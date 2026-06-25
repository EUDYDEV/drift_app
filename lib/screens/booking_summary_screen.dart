import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/experience_filter_controller.dart';
import '../controllers/main_navigation_controller.dart';
import '../models/cart_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/geographic_consistency_service.dart';
import '../services/hotel_service.dart';
import '../services/partner_catalog_service.dart';
import '../theme/app_colors.dart';
import 'paiement_page.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Hotel hotel;
  final DateTime departureDate;
  final DateTime? returnDate;
  final Map<String, int> selectedRooms;
  final double totalPrice;
  final String city;

  const BookingSummaryScreen({
    super.key,
    required this.hotel,
    required this.departureDate,
    this.returnDate,
    required this.selectedRooms,
    required this.totalPrice,
    required this.city,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late final HotelService _hotelService;
  late final GeographicConsistencyService _geoConsistencyService;
  late final PartnerCatalogService _partnerCatalogService;
  late final MainNavigationController _navigationController;
  late final ExperienceFilterController _experienceFilterController;

  final Map<String, Room> _roomsMap = <String, Room>{};
  late final Map<String, int> _selectedRoomQuantities;

  bool _isLoading = true;
  bool _isConfirming = false;
  bool _geoDialogShown = false;
  bool _geoCheckInProgress = false;
  int _dynamicTotal = 0;
  String? _geoRecommendationCity;

  String get _groupKey =>
      'booking:${widget.hotel.id}:${widget.departureDate.toIso8601String()}:${widget.returnDate?.toIso8601String() ?? 'single-night'}';

  int get _nights {
    final rawDifference = widget.returnDate == null
        ? 1
        : widget.returnDate!.difference(widget.departureDate).inDays;
    return math.max(1, rawDifference);
  }

  List<CartItem> get _currentPackItems {
    if (CartModel.items.isNotEmpty) {
      return CartModel.snapshot();
    }
    return _buildRoomCartItems();
  }

  List<CartItem> get _roomPackItems => _currentPackItems
      .where((item) => item.groupKey == _groupKey)
      .toList(growable: false);

  List<CartItem> get _extraPackItems => _currentPackItems
      .where((item) => item.groupKey == null || item.groupKey != _groupKey)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _hotelService = HotelService();
    _geoConsistencyService = context.read<GeographicConsistencyService>();
    _partnerCatalogService = context.read<PartnerCatalogService>();
    _navigationController = context.read<MainNavigationController>();
    _experienceFilterController = context.read<ExperienceFilterController>();
    _selectedRoomQuantities = Map<String, int>.from(widget.selectedRooms);

    CartModel.setBudgetLimit(
      CartModel.budgetLimit ?? widget.totalPrice.round(),
      label: CartModel.budgetLabel ?? 'Budget max',
    );
    _dynamicTotal = _resolveCurrentTotal();

    CartModel.itemCount.addListener(_onCartChanged);
    CartModel.revision.addListener(_onCartChanged);
    _loadRoomDetails();
  }

  Future<void> _loadRoomDetails() async {
    try {
      final rooms = await _hotelService.getRoomsForHotel(
        widget.hotel.id,
        partnerId: widget.hotel.partnerId,
      );
      for (final room in rooms) {
        _roomsMap[room.id] = room;
      }
      _syncSelectedRoomsIntoCart();
      await _refreshPartnerDrivenPricing();
      await _runGeographicConsistencyCheck();
    } catch (_) {
      _syncSelectedRoomsIntoCart();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCartChanged() {
    if (!mounted) return;

    setState(() {
      _dynamicTotal = _resolveCurrentTotal();
    });

    if (!_geoDialogShown && !_geoCheckInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _runGeographicConsistencyCheck();
        }
      });
    }
  }

  int _resolveCurrentTotal() {
    final items = _currentPackItems;
    if (items.isEmpty) {
      return 0;
    }
    return items.fold<int>(0, (sum, item) => sum + item.priceValue);
  }

  void _syncSelectedRoomsIntoCart() {
    final groupItems = _buildRoomCartItems();
    CartModel.syncGroup(_groupKey, groupItems);
    _dynamicTotal = _resolveCurrentTotal();
  }

  List<CartItem> _buildRoomCartItems() {
    final items = <CartItem>[];

    for (final entry in _selectedRoomQuantities.entries) {
      final roomId = entry.key;
      final quantity = entry.value;
      final room = _roomsMap[roomId];

      if (room == null || quantity <= 0) {
        continue;
      }

      final totalRoomPrice = room.priceValue * quantity * _nights;
      items.add(
        CartItem(
          id: '$_groupKey:$roomId',
          groupKey: _groupKey,
          type: 'hotel',
          serviceType: 'chambre_hotel',
          name: widget.hotel.name,
          subtitle: '${room.roomType} x$quantity - $_nights nuit(s)',
          priceDisplay: CartModel.formatCurrency(totalRoomPrice),
          priceValue: totalRoomPrice,
          color: AppColors.gradientBlue,
          icon: Icons.hotel,
          partnerId: room.partnerId ?? widget.hotel.partnerId,
          prestationId: room.prestationId,
          partnerName: widget.hotel.name,
          partnerType: 'hotel',
          partnerCity: widget.hotel.city,
          partnerAddress: widget.hotel.address,
          partnerLatitude: widget.hotel.latitude,
          partnerLongitude: widget.hotel.longitude,
          reservationStart: widget.departureDate.toUtc(),
          reservationEnd: (widget.returnDate ?? widget.departureDate)
              .add(const Duration(days: 1))
              .toUtc(),
          metadata: <String, dynamic>{
            'roomId': room.id,
            'roomType': room.roomType,
            'roomCapacity': room.capacity,
            'roomQuantity': quantity,
            'pricingMultiplier': quantity * _nights,
            'unitPrice': room.priceValue,
            'video360Url': room.virtualTourUrl,
            'bookingCity': widget.city,
            'bookingContext': _groupKey,
          },
        ),
      );
    }

    return items;
  }

  Future<void> _refreshPartnerDrivenPricing() async {
    try {
      final synchronized = await _partnerCatalogService.synchronizeCartItems(
        _currentPackItems,
      );
      CartModel.addAll(synchronized);
    } catch (_) {
      // The pack still works with the local price snapshot if the API is unreachable.
    }
  }

  Future<void> _runGeographicConsistencyCheck() async {
    if (_geoDialogShown || _geoCheckInProgress || !mounted) {
      return;
    }

    final items = _currentPackItems;
    if (items.isEmpty) {
      return;
    }

    _geoCheckInProgress = true;
    try {
      final contextResult =
          await _geoConsistencyService.showAlertForPackIfNeeded(
        context: context,
        items: items,
        onNeedHotelSuggestions: _redirectToHotelSuggestions,
      );

      if (contextResult != null) {
        _geoRecommendationCity =
            contextResult.item.partnerCity ?? contextResult.partnerCity;
        _geoDialogShown = true;
      }
    } finally {
      _geoCheckInProgress = false;
    }
  }

  void _redirectToHotelSuggestions() {
    final city = _geoRecommendationCity?.trim().isNotEmpty == true
        ? _geoRecommendationCity!.trim()
        : (widget.hotel.city.trim().isEmpty ? widget.city : widget.hotel.city);
    _experienceFilterController.activateHotelFilterForCity(city);
    _navigationController.goTo(MainNavigationController.experiencesIndex);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _removePackItem(CartItem item) {
    if (item.groupKey == _groupKey) {
      final roomId =
          item.metadata['roomId']?.toString() ?? item.id.split(':').last;
      _selectedRoomQuantities.remove(roomId);
      _syncSelectedRoomsIntoCart();
      return;
    }

    CartModel.remove(item.id);
  }

  Future<void> _confirmReservation() async {
    if (_isConfirming) return;

    if (CartModel.isOverBudget) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Budget depasse'),
          content: Text(
            'Le total du pack (${CartModel.totalFormatted}) depasse votre budget maximal '
            '(${CartModel.formatCurrency(CartModel.budgetLimit ?? widget.totalPrice.round())}).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ajuster mon pack'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);
    try {
      _syncSelectedRoomsIntoCart();
      await _refreshPartnerDrivenPricing();

      if (!mounted) return;

      final itemsToCheckout = _currentPackItems;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaiementPage(items: itemsToCheckout),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  void dispose() {
    CartModel.itemCount.removeListener(_onCartChanged);
    CartModel.revision.removeListener(_onCartChanged);
    CartModel.setBudgetLimit(null);
    _hotelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetSnapshot = CartModel.budgetSnapshot;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resume de reservation',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B894),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: 'Hotel',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.hotel.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '* ${widget.hotel.rating}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.hotel.address,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Dates du sejour',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arrivee',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${widget.departureDate.day}/${widget.departureDate.month}/${widget.departureDate.year}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Depart',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${widget.returnDate?.day ?? widget.departureDate.day}/${widget.returnDate?.month ?? widget.departureDate.month}/${widget.returnDate?.year ?? widget.departureDate.year}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$_nights nuit${_nights > 1 ? 's' : ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Chambres selectionnees',
                          child: _roomPackItems.isEmpty
                              ? _buildEmptyStateCard(
                                  'Aucune chambre active dans ce pack.',
                                )
                              : Column(
                                  children: _roomPackItems
                                      .map(_buildRoomPackCard)
                                      .toList(growable: false),
                                ),
                        ),
                        if (_extraPackItems.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Prestations du pack',
                            child: Column(
                              children: _extraPackItems
                                  .map(_buildExtraPackCard)
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Detail du prix',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _priceRow(
                                  'Sous-total',
                                  CartModel.formatCurrency(_dynamicTotal),
                                ),
                                const SizedBox(height: 8),
                                _priceRow(
                                  budgetSnapshot.label ?? 'Budget max',
                                  budgetSnapshot.maxBudget == null
                                      ? 'Non defini'
                                      : CartModel.formatCurrency(
                                          budgetSnapshot.maxBudget!,
                                        ),
                                ),
                                const SizedBox(height: 8),
                                _priceRow(
                                  budgetSnapshot.isOverBudget
                                      ? 'Depassement'
                                      : 'Budget restant',
                                  budgetSnapshot.remainingBudget == null
                                      ? 'N/A'
                                      : CartModel.formatCurrency(
                                          budgetSnapshot.remainingBudget!,
                                        ),
                                  valueColor: budgetSnapshot.isOverBudget
                                      ? Colors.redAccent
                                      : const Color(0xFF00B894),
                                ),
                                const SizedBox(height: 8),
                                _priceRow(
                                  'Frais de service',
                                  '0 FCFA',
                                ),
                                const SizedBox(height: 8),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      CartModel.formatCurrency(_dynamicTotal),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: CartModel.isOverBudget
                                            ? Colors.redAccent
                                            : const Color(0xFF00B894),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConfirming ? null : _confirmReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirmer la reservation',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmptyStateCard(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildRoomPackCard(CartItem item) {
    final quantity = (item.metadata['roomQuantity'] as num?)?.toInt() ?? 1;
    final capacity = (item.metadata['roomCapacity'] as num?)?.toInt() ?? 1;
    final roomType = item.metadata['roomType']?.toString() ?? item.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(
          color: Colors.green[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$roomType x$quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pour $capacity personne${capacity > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.priceDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00B894),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _removePackItem(item),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraPackCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: item.color.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.priceDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _removePackItem(item),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
