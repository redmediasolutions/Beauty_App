class HeroSliderItem {
  final String image;
  final String title;
  final String title2;
  final String subtitle;
  final String buttonText;
  final String buttonRoute;
  final String? categoryId;

  HeroSliderItem({
    required this.image,
    required this.title,
    required this.title2,
    required this.subtitle,
    required this.buttonText,
    required this.buttonRoute,
    this.categoryId,
  });

  factory HeroSliderItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return HeroSliderItem(
      image: map['image'] ?? '',
      title: map['title'] ?? '',
      title2: map['title2'] ?? '',
      subtitle: map['subtitle'] ?? '',
      buttonText: map['buttonText'] ?? '',
      buttonRoute: map['buttonRoute'] ?? '',
      categoryId: map['categoryId']?.toString(),
    );
  }
}

class HeroSettings {
  final bool enabled;
  final int autoSlideSeconds;
  final List<HeroSliderItem> items;

  HeroSettings({
    required this.enabled,
    required this.autoSlideSeconds,
    required this.items,
  });

  factory HeroSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return HeroSettings(
      enabled: map['enabled'] ?? true,
      autoSlideSeconds:
          (map['autoSlideSeconds'] ?? 4)
              .toInt(),
      items:
          (map['items'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    HeroSliderItem.fromMap(
                      Map<String, dynamic>.from(
                        e,
                      ),
                    ),
              )
              .toList(),
    );
  }
}