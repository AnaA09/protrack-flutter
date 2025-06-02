import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'cognito_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl;
  String? _authToken;

  ApiService({
    required this.baseUrl,
    String? authToken,
  }) : _authToken = authToken;

  void updateAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please sign in again');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      final decoded = json.decode(response.body);
      debugPrint('API Response: $decoded');
      return decoded;
    } else {
      throw Exception(
          'Failed to perform request: ${response.statusCode} - ${response.body}');
    }
  }
}
