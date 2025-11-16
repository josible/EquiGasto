import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRemoteDataSource {
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(String email, String password);
  Future<firebase_auth.UserCredential> signInWithGoogle();
  Future<void> signOut();
  firebase_auth.User? getCurrentFirebaseUser();
  Stream<firebase_auth.User?> getAuthStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl(this.firebaseAuth, this.googleSignIn);

  @override
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        throw Exception('Inicio de sesión con Google cancelado');
      }

      // Obtener los detalles de autenticación del usuario de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una nueva credencial
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      return await firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  @override
  firebase_auth.User? getCurrentFirebaseUser() {
    return firebaseAuth.currentUser;
  }

  @override
  Stream<firebase_auth.User?> getAuthStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No se encontró un usuario con ese email');
      case 'wrong-password':
        return Exception('Contraseña incorrecta');
      case 'email-already-in-use':
        return Exception('El email ya está registrado. Por favor, inicia sesión o usa otro email.');
      case 'weak-password':
        return Exception('La contraseña debe tener al menos 6 caracteres');
      case 'invalid-email':
        return Exception('El formato del email no es válido');
      case 'user-disabled':
        return Exception('Esta cuenta ha sido deshabilitada. Contacta al administrador.');
      case 'operation-not-allowed':
        return Exception('El registro con email y contraseña no está habilitado. Contacta al administrador.');
      case 'network-request-failed':
        return Exception('Error de conexión. Verifica tu conexión a internet.');
      default:
        return Exception('Error de autenticación: ${e.message ?? e.code}');
    }
  }
}

