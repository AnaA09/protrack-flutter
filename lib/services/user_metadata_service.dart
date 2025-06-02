import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'cognito_service.dart';

class UserMetadataService {
  final String apiEndpoint;
  final CognitoService _cognitoService;

  UserMetadataService(this.apiEndpoint, this._cognitoService);

  Future<Map<String, dynamic>> getUserMetadata() async {
    final token = await _cognitoService.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated: No access token available');
    }

    print('Making GET request to: $apiEndpoint/user');
    print('Using token: ${token.substring(0, 10)}...');

    try {
      final response = await http.get(
        Uri.parse('$apiEndpoint/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:3000',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user metadata: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserMetadata: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
            'Network error: Please check your internet connection and try again');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUserMetadata(
      Map<String, dynamic> userData) async {
    final token = await _cognitoService.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated: No access token available');
    }

    print('Making POST request to: $apiEndpoint/user');
    print('Using token: ${token.substring(0, 10)}...');
    print('Request body: $userData');

    try {
      final response = await http
          .post(
        Uri.parse('$apiEndpoint/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:3000',
        },
        body: json.encode(userData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create user metadata: ${response.body}');
      }
    } catch (e) {
      print('Error in createUserMetadata: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
            'Network error: Please check your internet connection and try again');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserMetadata(
      Map<String, dynamic> userData) async {
    final token = await _cognitoService.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated: No access token available');
    }

    try {
      final response = await http
          .put(
        Uri.parse('$apiEndpoint/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:3000',
        },
        body: json.encode(userData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user metadata: ${response.body}');
      }
    } catch (e) {
      print('Error in updateUserMetadata: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
            'Network error: Please check your internet connection and try again');
      }
      rethrow;
    }
  }

  Future<void> deleteUserMetadata() async {
    final token = await _cognitoService.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated: No access token available');
    }

    try {
      final response = await http.delete(
        Uri.parse('$apiEndpoint/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:3000',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete user metadata: ${response.body}');
      }
    } catch (e) {
      print('Error in deleteUserMetadata: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
            'Network error: Please check your internet connection and try again');
      }
      rethrow;
    }
  }
}
