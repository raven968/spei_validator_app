class User {
  final int id;
  final String email;
  final String name;
  final String? subscriptionStatus;
  final bool emailVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.subscriptionStatus,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        subscriptionStatus: json['subscription_status'],
        emailVerified: json['email_verified_at'] != null,
      );
}
