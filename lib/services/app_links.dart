import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static Future<void> initialize(GoRouter router) async {
    debugPrint('🚀 DeepLinkService initialized');

    // Cold start
    final initial = await _appLinks.getInitialLink();

    if (initial != null) {
      final location =
          initial.path + (initial.hasQuery ? '?${initial.query}' : '');

      debugPrint('🧊 Cold Start Link Received');
      debugPrint('   URI      : $initial');
      debugPrint('   Path     : ${initial.path}');
      debugPrint('   Location : $location');
      debugPrint('   Before   : ${router.state.uri}');

      router.go(location);

      debugPrint('   After    : ${router.state.uri}');
    } else {
      debugPrint('🧊 No cold start link');
    }

    // Warm start
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        final location =
            uri.path + (uri.hasQuery ? '?${uri.query}' : '');

        debugPrint('🔥 Warm Link Received');
        debugPrint('   URI      : $uri');
        debugPrint('   Path     : ${uri.path}');
        debugPrint('   Location : $location');
        debugPrint('   Before   : ${router.state.uri}');

        router.go(location);

        debugPrint('   After    : ${router.state.uri}');
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Deep Link Error');
        debugPrint(error.toString());
        debugPrint(stackTrace.toString());
      },
    );
  }

  static Future<void> dispose() async {
    debugPrint('🛑 DeepLinkService disposed');
    await _sub?.cancel();
  }
}