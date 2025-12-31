import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safeguard/utils/logger.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://iczlmtdbqpufkkkuqdvy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljemxtdGRicXB1Zmtra3VxZHZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyOTg4MjAsImV4cCI6MjA3Njg3NDgyMH0.x5maaHI2rysqDhOrpHD9QaYqfkqG6uDOs1zyzNnh4Y8',
    );
    AppLogger.info('Supabase initialized successfully');
  }

  // Method to write data to the database
  Future<void> writeData(String table, Map<String, dynamic> data) async {
    try {
      await client.from(table).insert(data);
      AppLogger.info('Data written successfully to $table');
    } catch (e) {
      AppLogger.error('Error writing data to $table', e);
    }
  }

  // Method to push new data to the database and get its ID
  Future<String?> pushData(String table, Map<String, dynamic> data) async {
    try {
      final response = await client
          .from(table)
          .insert(data)
          .select('id')
          .single();
      final id = response['id']?.toString();
      AppLogger.info('Data pushed successfully to $table with ID $id');
      return id;
    } catch (e) {
      AppLogger.error('Error pushing data to $table', e);
      return null;
    }
  }

  // Method to remove data from the database
  Future<void> removeData(String table, String id) async {
    try {
      await client.from(table).delete().eq('id', id);
      AppLogger.info('Data removed successfully from $table with ID $id');
    } catch (e) {
      AppLogger.error('Error removing data from $table', e);
    }
  }

  // Method to read data once from the database
  Future<List<Map<String, dynamic>>> readDataOnce(
    String table, {
    String? deviceId,
    bool silent =
        false, // If true, suppress error logging (useful when local fallback exists)
  }) async {
    try {
      PostgrestFilterBuilder query = client.from(table).select();

      // Only apply device filter if the table has device_id column
      if (deviceId != null) {
        // Attempt device filter; if it fails due to missing column, ignore
        try {
          query = query.eq('device_id', deviceId);
        } catch (_) {}
      }

      final response = await query;
      if (!silent) {
        AppLogger.info('Data read successfully from $table');
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Only log error if not silent (when we have local fallback)
      if (!silent) {
        AppLogger.error('Error reading data from $table', e);
      }
      return [];
    }
  }

  // Method to listen for updates to a specific table
  Stream<List<Map<String, dynamic>>> listenForUpdates(
    String table, {
    String? deviceId,
  }) {
    try {
      AppLogger.info('Listening for updates at $table');

      final stream = client.from(table).stream(primaryKey: ['id']);
      // If deviceId is provided and table supports it, filter by device
      if (deviceId != null && deviceId.isNotEmpty) {
        return stream
            .eq('device_id', deviceId)
            .map((data) => List<Map<String, dynamic>>.from(data));
      }
      return stream.map((data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      AppLogger.error('Error setting up listener for $table', e);
      rethrow;
    }
  }

  // Method to update data in the database
  Future<void> updateData(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await client.from(table).update(data).eq('id', id);
      AppLogger.info('Data updated successfully in $table with ID $id');
    } catch (e) {
      AppLogger.error('Error updating data in $table', e);
    }
  }
}
