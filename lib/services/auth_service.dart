import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStoredUser();
    _isInitialized = true;
    notifyListeners();
  }

  // Load stored user from preferences
  Future<void> _loadStoredUser() async {
    final userJson = _prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }
  }

  // Login (mock)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Simple validation
      if (email.isEmpty || password.isEmpty) {
        return false;
      }

      // Mock user (in real app, call backend)
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        phone: '+225 07 00 00 00 00',
        fullName: email.split('@')[0],
        createdAt: DateTime.now(),
        savedAddresses: [],
      );

      _currentUser = user;
      await _prefs.setString('current_user', jsonEncode(user.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Register (mock)
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Simple validation
      if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        return false;
      }

      // Mock user creation
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        phone: phone,
        fullName: fullName,
        createdAt: DateTime.now(),
        savedAddresses: [],
      );

      _currentUser = user;
      await _prefs.setString('current_user', jsonEncode(user.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove('current_user');
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    if (_currentUser == null) return false;

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));

      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        phone: phone ?? _currentUser!.phone,
        profileImage: profileImage ?? _currentUser!.profileImage,
      );

      await _prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Add saved address
  Future<bool> addSavedAddress(String address) async {
    if (_currentUser == null) return false;

    try {
      final addresses = List<String>.from(_currentUser!.savedAddresses);
      if (!addresses.contains(address)) {
        addresses.add(address);
        _currentUser = _currentUser!.copyWith(savedAddresses: addresses);
        await _prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove saved address
  Future<bool> removeSavedAddress(String address) async {
    if (_currentUser == null) return false;

    try {
      final addresses = List<String>.from(_currentUser!.savedAddresses);
      addresses.remove(address);
      _currentUser = _currentUser!.copyWith(savedAddresses: addresses);
      await _prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Forgot password (mock)
  Future<bool> requestPasswordReset(String email) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));
      // In real app, send email with reset link
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset password (mock)
  Future<bool> resetPassword({
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));
      // In real app, call backend with reset code
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify phone (mock)
  Future<bool> sendPhoneVerificationCode(String phone) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));
      // In real app, send SMS
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify code (mock)
  Future<bool> verifyPhoneCode(String code) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));
      // In real app, validate code with backend
      return code.length == 6; // Simple check
    } catch (e) {
      return false;
    }
  }
}
