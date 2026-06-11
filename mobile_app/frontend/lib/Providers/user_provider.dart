import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:vehnway/models/user_model.dart';
import 'package:vehnway/services/cache_service.dart';
import 'package:vehnway/services/supabase/supabase_user_service.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  StreamSubscription<firebase.User?>? _authSub;
  bool _isLoading = false;
  Object? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  String get displayName {
    final name = _currentUser?.name ?? 'Guest';
    const int threshold = 15;

    if (name.length <= threshold) {
      return name;
    }

    final words = name.split(' ');
    String result = '';

    for (var word in words) {
      if (result.isEmpty) {
        result = word;
      } else if ((result.length + 1 + word.length) <= threshold) {
        result += ' $word';
      } else {
        break;
      }
    }

    // If even the first word is longer than the threshold, we just return it.
    // (You can also truncate the first word if desired, e.g. result.substring(0, threshold))
    return result;
  }

  UserProvider() {
    _listenAuth();
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = firebase.FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
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

    // 1. Try Cache First
    final cachedData = CacheService().getUserDetail(firebaseUid);
    if (cachedData != null) {
      _setUser(AppUser.fromMap(cachedData));
    }

    notifyListeners();

    try {
      final currentUser = firebase.FirebaseAuth.instance.currentUser;

      // If user isn't verified (and isn't using a social provider), we don't load details yet
      if (currentUser != null &&
          currentUser.uid == firebaseUid &&
          !currentUser.emailVerified &&
          currentUser.providerData.every(
            (info) => info.providerId == 'password',
          )) {
        _setUser(null);
        return;
      }

      final data = await SupabaseUserService().getOrCreateUser(
        uid: firebaseUid,
        email: currentUser?.email ?? '',
        displayName: currentUser?.displayName,
      );

      if (data != null) {
        final user = AppUser.fromMap(data);
        _setUser(user);

        // 2. Save to Cache
        await CacheService().setUserDetail(firebaseUid, data);
      } else {
        // If no data and no cache, set to null
        if (cachedData == null) {
          _setUser(null);
        }
      }
    } catch (e) {
      _error = e;
      // If we have cached data, don't force null on error (keep last known good)
      if (cachedData == null) {
        _setUser(null);
      }
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
