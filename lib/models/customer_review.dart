class CustomerReview {
  final int day;
  final int ratingTenths;
  final int servedCustomers;
  final int skippedCustomers;
  final int totalCustomers;
  final String comment;

  const CustomerReview({
    required this.day,
    required this.ratingTenths,
    required this.servedCustomers,
    required this.skippedCustomers,
    required this.totalCustomers,
    required this.comment,
  });

  double get rating => ratingTenths / 10.0;

  String get stars {
    final fullStars = ratingTenths ~/ 10;
    final hasHalfStar = ratingTenths % 10 >= 5;

    final buffer = StringBuffer();

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        buffer.write('★');
      } else if (i == fullStars && hasHalfStar) {
        buffer.write('★');
      } else {
        buffer.write('☆');
      }
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'rating_tenths': ratingTenths,
      'served_customers': servedCustomers,
      'skipped_customers': skippedCustomers,
      'total_customers': totalCustomers,
      'comment': comment,
    };
  }

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      day: json['day'] is num ? json['day'].toInt() : 1,
      ratingTenths: json['rating_tenths'] is num
          ? json['rating_tenths'].toInt()
          : 50,
      servedCustomers: json['served_customers'] is num
          ? json['served_customers'].toInt()
          : 0,
      skippedCustomers: json['skipped_customers'] is num
          ? json['skipped_customers'].toInt()
          : 0,
      totalCustomers: json['total_customers'] is num
          ? json['total_customers'].toInt()
          : 0,
      comment: json['comment']?.toString() ?? '',
    );
  }
}