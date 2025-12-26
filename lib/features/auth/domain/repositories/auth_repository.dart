import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(
    String name,
    String email,
    String password,
    String phone,
  );
  Future<UserModel> signInWithGoogle();
  Future<void> logout();
  Future<UserModel?> getProfile();
  Future<void> checkPhoneAndSendOtp(String phone);
  Future<String> verifyOtp(String phone, String otp);
  Future<void> resetPassword(String phone, String password, String passwordConfirmation, String resetToken);
}
