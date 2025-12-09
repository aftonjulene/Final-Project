import 'package:flutter/material.dart';


class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String label;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? borderColor;
  final bool centerAlign;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.label,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Colors.grey[300]!),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: centerAlign
          ? Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}


class SimpleStatCard extends StatelessWidget {
  final String value;
  final String label;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? borderColor;

  const SimpleStatCard({
    super.key,
    required this.value,
    required this.label,
    this.padding,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Colors.grey[300]!),
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

