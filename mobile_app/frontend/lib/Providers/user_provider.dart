import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/models/user_model.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  StreamSubscription<firebase.User?>? _authSub;
  bool _isLoading = false;
  Object? _error;
  final VehicleProvider _vehicleProvider;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  UserProvider(this._vehicleProvider) {
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await SupabaseService().getUserdetails(firebaseUid);

      if (data != null) {
        _setUser(AppUser.fromMap(data));
      } else {
        _setUser(null);
      }
    } catch (e) {
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

    _vehicleProvider.loadVehicleByVehicleId(user?.firebaseUid);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
