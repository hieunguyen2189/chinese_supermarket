class DailyEvent {
  final String id;
  final String title;
  final String description;
  final String type;

  const DailyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
    };
  }

  factory DailyEvent.fromJson(Map<String, dynamic> json) {
    return DailyEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'normal',
    );
  }
}