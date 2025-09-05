import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:vehnicate_frontend/models/user_model.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  StreamSubscription<firebase.User?>? _authSub;
  bool _isLoading = false;
  Object? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  UserProvider() {
    _listenAuth();
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = firebase.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _setUser(null);
        return;
      }
      await loadUserByFirebaseUid(user.uid);
    });
  }

  Future<void> loadUserByFirebaseUid(String firebaseUid) async {
    print("UserProvider: Loading user data for Firebase UID: $firebaseUid");
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print("UserProvider: Requesting data from SupabaseService");
      final data = await SupabaseService().getUserdetails(firebaseUid);

      print("UserProvider: Received data from Supabase: $data");
      if (data != null) {
        final user = AppUser.fromMap(data);
        print("UserProvider: Created AppUser object: ${user.name}, ${user.email}");
        _setUser(user);
      } else {
        print("UserProvider: No user data received from Supabase");
        _setUser(null);
      }
    } catch (e, stackTrace) {
      print("UserProvider: Error loading user data:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      _error = e;
      _setUser(null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _setUser(null);
      return;
    }
    await loadUserByFirebaseUid(uid);
  }

  void _setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
