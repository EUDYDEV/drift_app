import 'package:flutter/foundation.dart';

class MainNavigationController extends ChangeNotifier {
  static const int homeIndex = 0;
  static const int experiencesIndex = 1;
  static const int voyagesIndex = 2;
  static const int packIndex = 3;
  static const int profileIndex = 4;

  int _currentIndex = homeIndex;

  int get currentIndex => _currentIndex;

  void goTo(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
