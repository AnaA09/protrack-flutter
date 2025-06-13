import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../models/lab.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../models/booking.dart';
import 'api_service.dart';

class InventoryService {
  final ApiService _apiService;

  InventoryService(this._apiService);

  // Lab Management
  Future<List<Lab>> getLabs() async {
    try {
      final response = await _apiService.get('/inventory/labs');
      final List<dynamic> labsJson = response as List<dynamic>;
      return labsJson.map((json) => Lab.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching labs: $e');
      rethrow;
    }
  }

  Future<Lab> createLab(Map<String, dynamic> labData) async {
    try {
      final response = await _apiService.post('/inventory/labs', labData);
      return Lab.fromJson(response);
    } catch (e) {
      debugPrint('Error creating lab: $e');
      rethrow;
    }
  }

  Future<Lab> getLab(String labId) async {
    try {
      final response = await _apiService.get('/inventory/labs/$labId');
      return Lab.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching lab: $e');
      rethrow;
    }
  }

  Future<void> deleteLab(String labId) async {
    try {
      await _apiService.delete('/inventory/labs/$labId');
    } catch (e) {
      debugPrint('Error deleting lab: $e');
      rethrow;
    }
  }

  Future<Lab> updateLab(String labId, Map<String, dynamic> labData) async {
    try {
      final response = await _apiService.put('/inventory/labs/$labId', labData);
      return Lab.fromJson(response);
    } catch (e) {
      debugPrint('Error updating lab: $e');
      rethrow;
    }
  }

  // Category Management
  Future<List<Category>> getCategoriesByLab(String labId) async {
    try {
      final response =
          await _apiService.get('/inventory/labs/$labId/categories');
      final List<dynamic> categoriesJson = response as List<dynamic>;
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<Category> createCategory(
      String labId, Map<String, dynamic> categoryData) async {
    try {
      final response = await _apiService.post(
          '/inventory/labs/$labId/categories', categoryData);
      return Category.fromJson(response);
    } catch (e) {
      debugPrint('Error creating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _apiService.delete('/inventory/categories/$categoryId');
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Future<Category> updateCategory(
      String categoryId, Map<String, dynamic> categoryData) async {
    try {
      final response = await _apiService.put(
          '/inventory/categories/$categoryId', categoryData);
      return Category.fromJson(response);
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  // Entry Management
  Future<List<Entry>> getEntriesByCategory(String categoryId) async {
    try {
      final response =
          await _apiService.get('/inventory/categories/$categoryId/entries');
      final List<dynamic> entriesJson = response as List<dynamic>;
      return entriesJson.map((json) => Entry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching entries: $e');
      rethrow;
    }
  }

  Future<Entry> createEntry(
      String categoryId, Map<String, dynamic> entryData) async {
    try {
      final response = await _apiService.post(
          '/inventory/categories/$categoryId/entries', entryData);
      return Entry.fromJson(response);
    } catch (e) {
      debugPrint('Error creating entry: $e');
      rethrow;
    }
  }

  Future<Entry> getEntry(String entryId) async {
    try {
      final response = await _apiService.get('/inventory/entries/$entryId');
      return Entry.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching entry: $e');
      rethrow;
    }
  }

  Future<Entry> updateEntry(
      String entryId, Map<String, dynamic> entryData) async {
    try {
      final response =
          await _apiService.put('/inventory/entries/$entryId', entryData);
      return Entry.fromJson(response);
    } catch (e) {
      debugPrint('Error updating entry: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _apiService.delete('/inventory/entries/$entryId');
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      rethrow;
    }
  }

  // Booking Management
  Future<Booking> createBooking(
      String entryId, Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiService.post(
          '/inventory/entries/$entryId/book', bookingData);
      return Booking.fromJson(response);
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByEntry(String entryId) async {
    try {
      final response =
          await _apiService.get('/inventory/entries/$entryId/bookings');
      final List<dynamic> bookingsJson = response as List<dynamic>;
      return bookingsJson.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailableDates(
      String entryId, String startDate, String endDate) async {
    try {
      final response = await _apiService.get(
          '/inventory/entries/$entryId/availability/$startDate?end_date=$endDate');
      final Map<String, dynamic> result = response as Map<String, dynamic>;
      final List<dynamic> datesJson = result['availableDates'];
      return datesJson.cast<String>();
    } catch (e) {
      debugPrint('Error fetching available dates: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String entryId, String bookingId) async {
    try {
      // Send bookingId as a query parameter for DELETE
      await _apiService.delete('/inventory/entries/$entryId/bookings?bookingId=$bookingId');
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      rethrow;
    }
  }

  // Helper methods for filtering categories
  List<Category> getInstrumentCategories(List<Category> categories) {
    return categories
        .where((category) => category.categoryType == 'INSTRUMENTS')
        .toList();
  }

  List<Category> getChemicalCategories(List<Category> categories) {
    return categories
        .where((category) => category.categoryType == 'CHEMICALS')
        .toList();
  }

  List<Category> getCultureCategories(List<Category> categories) {
    return categories
        .where((category) => category.categoryType == 'CULTURES')
        .toList();
  }

  // Helper methods for filtering entries
  List<Entry> getAvailableEntries(List<Entry> entries) {
    return entries.where((entry) => entry.isAvailable).toList();
  }

  List<Entry> getEntriesByStatus(List<Entry> entries, String status) {
    return entries.where((entry) => entry.status == status).toList();
  }
}
