import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '363848646486-amk51ebf9fqvbqufmk3a9g2a78b014t8.apps.googleusercontent.com',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithGoogle() async {
    try {
      // Usar signIn() que es el método correcto en la versión 6.x
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario.');
      }

      // Obtener las credenciales de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'No se pudieron obtener las credenciales de Google. Por favor, intenta de nuevo.',
        );
      }

      // Crear la credencial de Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Iniciar sesión en Firebase con las credenciales de Google
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error inesperado al iniciar sesión con Google: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

