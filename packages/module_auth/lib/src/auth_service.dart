import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      print(
          'AuthService: Estado de autenticação alterado - usuário autenticado: ${_user?.uid}');
      _user = firebaseUser;
      await _loadUserData();
      _status = AuthStatus.authenticated;
    }
    print('AuthService: Notificando ouvintes');
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    print('AuthService: Carregando dados do usuário: ${_user!.uid}');
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      _userData = userDoc.data() as Map<String, dynamic>?;
      print('AuthService: Dados do usuário carregados: $_userData');

      if (_userData != null && _userData!['tenant_id'] != null) {
        print(
            'AuthService: Carregando dados do tenant: ${_userData!['tenant_id']}');
        DocumentSnapshot tenantDoc = await _firestore
            .collection('tenant') // Correção: 'tenants' para 'tenant'
            .doc(_userData!['tenant_id'])
            .get();
        _tenantData = tenantDoc.data() as Map<String, dynamic>?;
        print('AuthService: Dados do tenant carregados: $_tenantData');
      } else {
        print('AuthService: Nenhum tenant_id encontrado para o usuário.');
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
