class Plan {
  final int id;
  final String name;
  final String slug;
  final String formattedPrice;
  final String currency;
  final String interval;
  final List<String> features;

  const Plan({
    required this.id,
    required this.name,
    required this.slug,
    required this.formattedPrice,
    required this.currency,
    required this.interval,
    required this.features,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'],
        name: json['name'],
        slug: json['slug'],
        formattedPrice: json['formatted_price'],
        currency: (json['currency'] as String).toUpperCase(),
        interval: json['interval'] == 'month' ? 'mes' : 'año',
        features: List<String>.from(json['features'] ?? []),
      );
}
