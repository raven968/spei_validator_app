class SubscriptionStatus {
  final bool subscribed;
  final String? plan;
  final String status;
  final String? endsAt;
  final bool onTrial;
  final bool cancelled;

  const SubscriptionStatus({
    required this.subscribed,
    required this.status,
    this.plan,
    this.endsAt,
    this.onTrial = false,
    this.cancelled = false,
  });

  bool get isActive => subscribed && !cancelled;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        subscribed: json['subscribed'] ?? false,
        plan: json['plan'],
        status: json['status'] ?? 'inactive',
        endsAt: json['ends_at'],
        onTrial: json['on_trial'] ?? false,
        cancelled: json['cancelled'] ?? false,
      );
}
