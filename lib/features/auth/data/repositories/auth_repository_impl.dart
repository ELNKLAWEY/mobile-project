import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      // Based on docs: { "user": {...}, "access_token": "..." }

      final token =
          response.data['access_token']; // direct at root based on spec?
      // Spec says: { "user": {...}, "access_token": "..." }
      // But verify if wrapped in 'data' key or root. Docs say "Response (200 OK): { "user": ... }"
      // Assuming root.

      if (token != null) {
        await _tokenStorage.saveToken(token);
      }

      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      if (e is DioException) {
        // handle error
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      final token = response.data['access_token'];
      if (token != null) {
        await _tokenStorage.saveToken(token);
      }

      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get the ID token
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Send the ID token to your backend
      final response = await _apiClient.dio.post(
        ApiEndpoints.googleAuth,
        data: {
          'idToken': idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      );

      // Save the access token from your backend
      final token = response.data['access_token'];
      if (token != null) {
        await _tokenStorage.saveToken(token);
      }

      // Return user model with photo URL
      final userData = response.data['user'];
      return UserModel.fromJson(userData);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Google Sign-In failed');
      }
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } catch (e) {
      // ignore logout errors
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  @override
  Future<UserModel?> getProfile() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await _apiClient.dio.get(ApiEndpoints.me);
      // Response: { "user": { ... } } or wrapper?
      // Docs: { "user": { ... } }
      // But sometimes wrapped in 'data'. Let's check response structure carefully.
      // Based on provided valid docs: { "user": { ... } }

      // Wait, some APIs return { "status": true, "data": { "user": ... } }.
      // The snippet provided: { "user": { ... } }

      return UserModel.fromJson(
        response.data['user'] ?? response.data['data']['user'],
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> checkPhoneAndSendOtp(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resetPasswordCheckPhone,
        data: {'phone': phone},
      );
      // Response: { "success": true, "message": "OTP sent successfully" }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
      }
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> verifyOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resetPasswordVerifyOtp,
        data: {
          'phone': phone,
          'otp': otp,
        },
      );
      // Response: { "success": true, "message": "OTP verified successfully", "reset_token": "..." }
      return response.data['reset_token'] as String;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Invalid or expired OTP');
      }
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> resetPassword(
    String phone,
    String password,
    String passwordConfirmation,
    String resetToken,
  ) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.resetPasswordChange,
        data: {
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $resetToken',
          },
        ),
      );
      // Response: { "success": true, "message": "Password reset successfully" }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to reset password');
      }
      throw Exception(e.toString());
    }
  }
}
