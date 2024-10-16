import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ainaglam/utils/dialog.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  User? _user;
  bool? _status;
  String? _token;

  bool get isLoading => _isLoading;
  User? get user => _user;
  bool? get status => _status;
  String? get token => _token;

  // AuthProvider() {
  //   _loadUserFromPrefs(); // Load user session when the provider is initialized
  // }

  Future<void> login(String email, BuildContext context) async {
    _status = false;
    _isLoading = true;
    notifyListeners();
    try {
      var response = await _authService.sendSmsCode(email);
      if (response['success'] == true) {
        _status = response['success'];
      } else {
        showStatusDialog(context, response['message'], false);
      }
    } catch (error) {
      showStatusDialog(context, "An error occurred: $error", false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginwithGoogle(BuildContext context) async {
    _status = false;
    _isLoading = true;
    notifyListeners();
    try {
      var response = await _authService.loginWithGoogle();
      if (response['success'] == true) {
        _status = true;
      } else {
        showStatusDialog(context, response['message'], false);
      }
    } catch (error) {
      showStatusDialog(context, "An error occurred: $error", false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifySmsCode(String smsCode, BuildContext context) async {
    _status = false;
    _isLoading = true;
    notifyListeners();
    try {
      var response = await _authService.verifySmsCode(smsCode);
      if (response['success']) {
        Map<String, dynamic> jsonMap = response['data'];
        Map<String, dynamic> data = jsonMap['data'];
        _user = User.fromJson(data);
        await _saveAuthData(_user!);
        _token = _user?.token;
        _status = response['success'];
      } else {
        showStatusDialog(context, response['message'], false);
      }
    } catch (error) {
      showStatusDialog(context, "An error occurred: $error", false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user'); // Clear user session
  }

  Future<void> _saveAuthData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString('user_data', userJson);
  }

  Future<User?> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    String? userJson = prefs.getString('user_data');

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      notifyListeners();
      return User.fromJson(userMap);
    }
    return null;
  }
}
