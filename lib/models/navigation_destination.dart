// models/navigation_destinations.dart

import 'package:flutter/material.dart';

class NavigationDestination {
  final String label;
  final String route;
  final Widget Function() screenFactory;

  NavigationDestination({
    required this.label,
    required this.route,
    required this.screenFactory,
  });
}

class BottomNavigationBar {
  final Widget icon;
  final Widget activeIcon;
  final String label;
  final String route;
  final Widget Function() screenFactory;

  BottomNavigationBar({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.screenFactory,
  });
}
