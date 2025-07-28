import 'package:flutter/material.dart';

class SwipeProvider extends ChangeNotifier {
  bool _swipeEnabled = true;
  bool get swipeEnabled => _swipeEnabled;
  void setSwipeEnabled(bool value) {
    _swipeEnabled = value;
    notifyListeners();
  }
} 