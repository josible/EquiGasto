import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRemoteDataSource {
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(String email, String password);
  Future<firebase_auth.UserCredential> signInWithGoogle();
  Future<firebase_auth.UserCredential> linkGoogleAccount();
  Future<void> signOut();
  firebase_auth.User? getCurrentFirebaseUser();
  Stream<firebase_auth.User?> getAuthStateChanges();
  Future<void> sendPasswordResetEmail(String email);
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
      // Autenticar con Google usando signIn() (API versión 6.x)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'No se pudieron obtener las credenciales de Google. Por favor, intenta de nuevo.',
        );
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      return await firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Manejar errores específicos de Firebase Auth
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          // Extraer el email del error si está disponible
          final email = e.email;
          if (email != null) {
            errorMessage = 'Ya existe una cuenta con el email $email registrada con email y contraseña. Por favor, inicia sesión primero con tu email y contraseña, y luego podrás vincular tu cuenta de Google desde tu perfil.';
          } else {
            errorMessage = 'Ya existe una cuenta con este email usando otro método de inicio de sesión (email y contraseña). Por favor, inicia sesión primero con tu email y contraseña.';
          }
          break;
        case 'invalid-credential':
          errorMessage = 'Las credenciales de Google han expirado o son inválidas. Por favor, intenta de nuevo.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El inicio de sesión con Google no está habilitado. Contacta al administrador.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada. Contacta al administrador.';
          break;
        case 'user-not-found':
          errorMessage = 'No se encontró una cuenta con estas credenciales.';
          break;
        case 'wrong-password':
          errorMessage = 'Credenciales incorrectas.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Código de verificación inválido.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'ID de verificación inválido.';
          break;
        default:
          errorMessage = 'Error al iniciar sesión con Google: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al iniciar sesión con Google. Por favor, intenta de nuevo.');
    }
  }

  @override
  Future<firebase_auth.UserCredential> linkGoogleAccount() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesión primero antes de vincular tu cuenta de Google');
      }

      // Autenticar con Google usando signIn() (API versión 6.x)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'No se pudieron obtener las credenciales de Google. Por favor, intenta de nuevo.',
        );
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      return await currentUser.linkWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'provider-already-linked':
          errorMessage = 'Esta cuenta de Google ya está vinculada a otra cuenta.';
          break;
        case 'credential-already-in-use':
          errorMessage = 'Esta cuenta de Google ya está en uso por otro usuario.';
          break;
        case 'invalid-credential':
          errorMessage = 'Las credenciales de Google han expirado o son inválidas. Por favor, intenta de nuevo.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este email ya está asociado a otra cuenta.';
          break;
        default:
          errorMessage = 'Error al vincular cuenta de Google: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(e.toString());
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
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

