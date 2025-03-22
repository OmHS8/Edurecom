// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthApiService {
  // Base URL for your Django API
  final String baseUrl = 'http://192.168.0.102:8000';
  
  // Secure storage for tokens
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Key constants for storage
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  
  // Headers for API calls
  Future<Map<String, String>> getHeaders() async {
    String? token = await _storage.read(key: ACCESS_TOKEN_KEY);
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Check if token is expired
  Future<bool> isTokenExpired() async {
    String? token = await _storage.read(key: ACCESS_TOKEN_KEY);
    
    if (token == null) {
      return true;
    }
    
    // Check if token is expired
    return JwtDecoder.isExpired(token);
  }
  
  // Refresh token
  Future<bool> refreshToken() async {
    String? refreshToken = await _storage.read(key: REFRESH_TOKEN_KEY);
    
    if (refreshToken == null) {
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: ACCESS_TOKEN_KEY, value: data['access']);
        
        // If the refresh token is also rotated (as per your Django settings)
        if (data.containsKey('refresh')) {
          await _storage.write(key: REFRESH_TOKEN_KEY, value: data['refresh']);
        }
        
        return true;
      } else {
        // If refresh fails, clear tokens and require re-login
        await _storage.deleteAll();
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }
  
  // Make authenticated request
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function() requestFunction
  ) async {
    // Check if token needs refreshing
    if (await isTokenExpired()) {
      bool refreshed = await refreshToken();
      if (!refreshed) {
        throw Exception('Authentication required. Please login again.');
      }
    }
    
    // Make the actual request
    return await requestFunction();
  }
  
  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? bio,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register/'),
        headers: await getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          if (bio != null) 'bio': bio,
        }),
      );

      print(jsonDecode(response.body));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/'),
        headers: await getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final data = _handleResponse(response);
      
      // Save tokens
      if (data.containsKey('access') && data.containsKey('refresh')) {
        await _storage.write(key: ACCESS_TOKEN_KEY, value: data['access']);
        await _storage.write(key: REFRESH_TOKEN_KEY, value: data['refresh']);
      }
      
      return data;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  // Logout user
  Future<bool> logout() async {
      // Clear tokens
      await _storage.deleteAll();
      return true;
  }
  
  Future<bool> registerUser(String username, String email, String password, 
                           {String firstName = '', String lastName = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    
    if (response.statusCode == 201) {
      return true;
    } else {
      // Handle error based on response
      final error = jsonDecode(response.body);
      throw Exception(error.toString());
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _authenticatedRequest(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: await getHeaders(),
      );

      print(response.body);
      
      return response;
    }).then((response) => _handleResponse(response));
  }
  
  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _authenticatedRequest(() async {
      final response = await http.put(
        Uri.parse('$baseUrl/users/change-password/'),
        headers: await getHeaders(),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );
      
      return response;
    }).then((response) => _handleResponse(response));
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: ACCESS_TOKEN_KEY);
    String? refreshToken = await _storage.read(key: REFRESH_TOKEN_KEY);
    
    // No tokens at all
    if (token == null && refreshToken == null) {
      return false;
    }
    
    // Has refresh token but access token is expired
    if (token != null && JwtDecoder.isExpired(token) && refreshToken != null) {
      return refreshToken as bool;
    }
    
    // Has valid access token
    return token != null && !JwtDecoder.isExpired(token);
  }
  
  // Helper to handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['detail'] ?? 'Request failed with status: ${response.statusCode}');
    }
  }
}