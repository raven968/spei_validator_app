class User {
  final int id;
  final String email;
  final String name;
  final String? subscriptionStatus;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.subscriptionStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        subscriptionStatus: json['subscription_status'],
      );
}
