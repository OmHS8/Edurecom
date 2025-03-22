// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  
  bool _isLoggedIn = false;
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;
  
  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  
  // Constructor - check if user is already logged in on startup
  AuthProvider() {
    _checkLoginStatus();
  }
  
  // Check login status
  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First check if we have valid tokens
      final loggedIn = await _apiService.isLoggedIn();
      _isLoggedIn = loggedIn;
      
      // If logged in, fetch user data
      if (loggedIn) {
        await getUserProfile();
      }
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.registerUser(
        username,
        email,
        password
      );
      
      // After registration, attempt to login
      return await login(username: username, password: password);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login
  Future<bool> login({required String username, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.login(username: username, password: password);
      
      // Get user profile after successful login
      await getUserProfile();
      
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _apiService.logout();
      _user = null;
      _isLoggedIn = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearError() async {
    _error = null;
  }
  
  // Get user profile
  Future<void> getUserProfile() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _apiService.getUserProfile();
      _user = data;
      _isLoggedIn = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (e.toString().contains('Authentication required')) {
        _isLoggedIn = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      
      // Update tokens if returned in response
      if (data.containsKey('tokens')) {
        // The tokens are automatically saved by the API service
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}