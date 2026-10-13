import 'package:flutter/material.dart';

class DashboardMetrics {
  final IconData icon;
  final String label;
  final String value;

  DashboardMetrics({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class RecentActivity {
  final IconData icon;
  final String description;

  RecentActivity({
    required this.icon,
    required this.description,
  });
}

class DashboardModel {
  final List<DashboardMetrics> metrics;
  final List<RecentActivity> activities;

  DashboardModel({
    required this.metrics,
    required this.activities,
  });
}
