import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  successful,
  wrongPassword,
  emailAlreadyExists,
  invalidEmail,
  weakPassword,
  unknown,
}

AuthStatus _status = AuthStatus.wrongPassword;

class AuthExceptionHandler {
  static handleAuthException(FirebaseAuthException e) {
    AuthStatus status;
    switch (e.code) {
      case "invalid-email":
        status = AuthStatus.invalidEmail;
        break;
      case "wrong-password":
        status = AuthStatus.wrongPassword;
        break;
      case "weak-password":
        status = AuthStatus.weakPassword;
        break;
      case "email-already-in-use":
        status = AuthStatus.emailAlreadyExists;
        break;
      default:
        status = AuthStatus.unknown;
    }
    return status;
  }

  static String generateErrorMessage(error) {
    String errorMessage;
    switch (error) {
      case AuthStatus.invalidEmail:
        errorMessage = "Your email address appears to be malformed.";
        break;
      case AuthStatus.weakPassword:
        errorMessage = "Your password should be at least 6 characters.";
        break;
      case AuthStatus.wrongPassword:
        errorMessage = "Your email or password is wrong.";
        break;
      case AuthStatus.emailAlreadyExists:
        errorMessage =
            "The email address is already in use by another account.";
        break;
      default:
        errorMessage = "An error occured. Please try again later.";
    }
    return errorMessage;
  }
}

class AuthHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        return user.uid;
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      // ignore: unnecessary_null_comparison
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  Future<AuthStatus> resetPassword({required String email}) async {
    await _auth
        .sendPasswordResetEmail(email: email)
        .then((value) => _status = AuthStatus.successful)
        .catchError(
            (e) => _status = AuthExceptionHandler.handleAuthException(e));
    return _status;
  }
 
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Failed to log out: $e');
      // Handle error
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      return user;
    } catch (e) {
      rethrow;
    }
  }
}