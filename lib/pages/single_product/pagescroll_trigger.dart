import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

Widget scrollTriggered(Widget child, String key) {
  ValueNotifier<bool> isVisible = ValueNotifier(false);

  return VisibilityDetector(
    key: Key(key),
    onVisibilityChanged: (info) {
      // Trigger when 10% of the widget is visible
      if (info.visibleFraction > 0.1 && !isVisible.value) {
        isVisible.value = true;
      }
    },
    child: ValueListenableBuilder<bool>(
      valueListenable: isVisible,
      builder: (context, visible, _) {
        return visible ? child : Opacity(opacity: 0, child: child);
      },
    ),
  );
}

final CarouselSliderController _carouselController = CarouselSliderController();
late final VoidCallback onIncrement;
late final VoidCallback onDecrement;