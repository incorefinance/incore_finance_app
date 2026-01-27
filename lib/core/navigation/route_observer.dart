// lib/core/navigation/route_observer.dart
//
// Global route observer for detecting when screens are popped and returned to.
// Used to refresh stale data when navigating back to screens.

import 'package:flutter/material.dart';

class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  static final AppRouteObserver instance = AppRouteObserver._();

  AppRouteObserver._();

  /// Callbacks to invoke when a route is popped and the observer's route is shown again.
  final List<VoidCallback> _onRoutePopCallbacks = [];

  /// Register a callback to be invoked when this observer's route becomes visible again.
  void addOnRoutePopCallback(VoidCallback callback) {
    _onRoutePopCallbacks.add(callback);
  }

  /// Unregister a callback.
  void removeOnRoutePopCallback(VoidCallback callback) {
    _onRoutePopCallbacks.remove(callback);
  }

  void didPopNext() {
    // Called when the top route is popped and this route (below it) becomes visible again.
    for (final callback in _onRoutePopCallbacks) {
      callback();
    }
  }
}
