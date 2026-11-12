import 'package:flutter/material.dart';

class CollectionMetrics extends StatelessWidget {
  const CollectionMetrics({
    super.key,
    required this.total,
    required this.healthy,
    required this.needsCare,
  });

  final int total;
  final int healthy;
  final int needsCare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Metric(value: '$total', label: 'plants at home')),
        const SizedBox(width: 12),
        Expanded(child: _Metric(value: '$healthy', label: 'feeling good')),
        const SizedBox(width: 12),
        Expanded(child: _Metric(value: '$needsCare', label: 'needs care')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 29,
            fontWeight: FontWeight.w400,
            color: scheme.surface,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: scheme.tertiaryContainer,
          ),
        ),
      ],
    );
  }
}