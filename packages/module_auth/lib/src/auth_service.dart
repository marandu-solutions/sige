import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _tenantData;

  AuthService()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get tenantData => _tenantData;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      print('AuthService: Estado de autenticação alterado - usuário nulo');
      _status = AuthStatus.unauthenticated;
      _user = null;
      _userData = null;
      _tenantData = null;
    } else {
      _user = firebaseUser;
      await _loadUserData();
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    print('AuthService: Carregando dados do usuário: ${_user!.uid}');
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      _userData = userDoc.data() as Map<String, dynamic>?;

      if (_userData != null && _userData!['tenant_id'] != null) {
        DocumentSnapshot tenantDoc = await _firestore
            .collection('tenant') // Correção: 'tenants' para 'tenant'
            .doc(_userData!['tenant_id'])
            .get();
        _tenantData = tenantDoc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('AuthService: Erro ao carregar dados do usuário: $e');
    }
    notifyListeners(); // Correção: Restaurado o notifyListeners
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
