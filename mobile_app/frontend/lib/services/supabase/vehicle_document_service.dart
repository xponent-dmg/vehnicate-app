import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnway/services/supabase/supabase_core_service.dart';

class VehicleDocumentService {
  final _core = SupabaseCoreService();
  final String _bucketName = 'vehicle-documents';

  /// 1. Upload Document
  Future<Map<String, dynamic>> uploadDocument({
    required int vehicleId,
    required String documentType,
    required File file,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final userId = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalFileName = path.basename(file.path);

    // Construct storage path: {user_id}/{vehicle_id}/{document_type}/{timestamp}_{original_filename}
    final filePath =
        '$userId/$vehicleId/$documentType/${timestamp}_$originalFileName';

    final client = await _core.getAuthenticatedClient();

    // Upload to Supabase Storage
    await client.storage.from(_bucketName).upload(filePath, file);
    final fileSize = await file.length();

    // Insert Database Record (user_id removed, vehicle_id is int)
    final response =
        await client
            .from('vehicle_documents')
            .insert({
              'vehicle_id': vehicleId,
              'document_type': documentType,
              'file_name': originalFileName,
              'file_path': filePath,
              'file_size': fileSize,
              'mime_type': _getMimeType(originalFileName),
              'issue_date': issueDate?.toIso8601String(),
              'expiry_date': expiryDate?.toIso8601String(),
            })
            .select()
            .single();

    return response;
  }

  /// 2. Replace Document
  Future<Map<String, dynamic>> replaceDocument({
    required String existingDocumentId,
    required int vehicleId,
    required String documentType,
    required String oldFilePath,
    required File newFile,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    // Upload new document first
    final newDoc = await uploadDocument(
      vehicleId: vehicleId,
      documentType: documentType,
      file: newFile,
      issueDate: issueDate,
      expiryDate: expiryDate,
    );

    // Delete old document record & storage file
    await deleteDocument(existingDocumentId, oldFilePath);

    return newDoc;
  }

  /// 3. Delete Document
  Future<void> deleteDocument(String documentId, String filePath) async {
    final client = await _core.getAuthenticatedClient();

    // Delete database record
    await client
        .from('vehicle_documents')
        .delete()
        .eq('document_id', documentId);

    // Delete file from storage
    await client.storage.from(_bucketName).remove([filePath]);
  }

  /// 4. Fetch all documents for a vehicle
  Future<List<Map<String, dynamic>>> getVehicleDocuments(int vehicleId) async {
    final client = await _core.getAuthenticatedClient();
    final response = await client
        .from('vehicle_documents')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 5. Fetch documents grouped by type (Returns Map of String to List)
  Future<Map<String, List<Map<String, dynamic>>>> getDocumentsGroupedByType(
    int vehicleId,
  ) async {
    final docs = await getVehicleDocuments(vehicleId);
    final groupedDocs = <String, List<Map<String, dynamic>>>{};
    for (var doc in docs) {
      final type = doc['document_type'] as String;
      groupedDocs.putIfAbsent(type, () => []).add(doc);
    }
    return groupedDocs;
  }

  /// Helper 1: Get documents expiring within 30 days
  Future<List<Map<String, dynamic>>> getExpiringDocuments(int vehicleId) async {
    final today = DateTime.now();
    final thirtyDaysFromNow = today.add(const Duration(days: 30));

    final client = await _core.getAuthenticatedClient();
    final response = await client
        .from('vehicle_documents')
        .select()
        .eq('vehicle_id', vehicleId)
        .gte('expiry_date', today.toIso8601String())
        .lte('expiry_date', thirtyDaysFromNow.toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper 2: Get expired documents
  Future<List<Map<String, dynamic>>> getExpiredDocuments(int vehicleId) async {
    final today = DateTime.now();
    final client = await _core.getAuthenticatedClient();
    final response = await client
        .from('vehicle_documents')
        .select()
        .eq('vehicle_id', vehicleId)
        .lt('expiry_date', today.toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper 3: Get latest document of each type for a vehicle
  Future<List<Map<String, dynamic>>> getLatestDocuments(int vehicleId) async {
    final docs = await getVehicleDocuments(vehicleId);
    final latestDocs = <String, Map<String, dynamic>>{};
    for (var doc in docs) {
      final type = doc['document_type'] as String;
      // Since docs are already ordered by uploaded_at descending, the first one we see is the latest.
      latestDocs.putIfAbsent(type, () => doc);
    }
    return latestDocs.values.toList();
  }

  String _getMimeType(String filename) {
    final ext = path.extension(filename).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
