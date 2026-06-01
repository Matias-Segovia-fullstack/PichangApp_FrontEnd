class LoginResponse {
  final String token;
  final String username;
  final int userId;
  final String message;

  LoginResponse({
    required this.token,
    required this.username,
    required this.userId,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      username: json['username'] ?? '',
      userId: json['userId'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}