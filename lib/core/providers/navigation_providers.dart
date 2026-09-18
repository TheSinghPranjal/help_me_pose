import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active tab in the root [AppShell] bottom navigation.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Shared route observer so screens (notably the camera screen) can pause
/// expensive work while covered by a pushed route, and resume when they
/// become visible again.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
