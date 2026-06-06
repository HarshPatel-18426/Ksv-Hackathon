import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_role.dart';
import '../models/vendor.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserProfile? _currentUser;
  bool _initialized = false;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserProfile(user.uid);
      } else {
        _currentUser = null;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserProfile.fromJson({
          ...doc.data()!,
          'id': uid,
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? companyName,
    String? gstNumber,
    String? category,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userProfile = UserProfile(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        companyName: companyName,
        gstNumber: gstNumber,
        category: category,
      );

      final userProfileJson = {
        ...userProfile.toJson(),
        'password': password,
      };
      await _db.collection('users').doc(credential.user!.uid).set(userProfileJson);
      
      // If role is vendor, also create a record in the 'vendors' collection
      if (role == UserRole.vendor) {
        final vendor = Vendor(
          id: credential.user!.uid,
          name: companyName ?? name,
          category: category ?? 'Unassigned',
          gstNumber: gstNumber ?? 'PENDING',
          rating: 0.0,
          status: VendorStatus.pendingVerification,
          email: email,
          phone: '',
          address: '',
          performance: VendorPerformance(priceScore: 0, qualityScore: 0, deliveryScore: 0),
          attachments: [],
          activityLog: ['Account registered on ${DateTime.now().toString().split(' ')[0]}'],
        );
        final vendorJson = {
          ...vendor.toJson(),
          'password': password,
        };
        await _db.collection('vendors').doc(credential.user!.uid).set(vendorJson);
      }

      _currentUser = userProfile;
    } catch (e) {
      debugPrint("Registration error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> registerNewVendorFromAdmin({
    required String name,
    required String email,
    required String password,
    required String gstNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    FirebaseApp? tempApp;
    try {
      final appName = 'TempRegister-${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;

      // Create UserProfile in 'users' collection
      final userProfile = UserProfile(
        id: uid,
        name: name,
        email: email,
        role: UserRole.vendor,
        companyName: name,
        gstNumber: gstNumber,
        category: 'Unassigned',
      );
      final userProfileJson = {
        ...userProfile.toJson(),
        'password': password,
      };
      await _db.collection('users').doc(uid).set(userProfileJson);

      return uid;
    } catch (e) {
      debugPrint("Error registering vendor from admin: $e");
      rethrow;
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _fetchUserProfile(credential.user!.uid);
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _auth.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
