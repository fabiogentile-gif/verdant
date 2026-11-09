import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header di pagina: [eyebrow] opzionale + titolo + sottotitolo.
///
/// Esempi:
///   PageHeader(title: 'Piante', subtitle: '...')
///   PageHeader.eyebrowText('Il tuo giardino', title: '...', subtitle: '...')
///   PageHeader.eyebrowDate(DateTime.now(), title: '...', subtitle: '...')

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle})
    : _eyebrowText = null,
      _eyebrowDate = null,
      _locale = null;

  const PageHeader.eyebrowText(
    String eyebrow, {
    super.key,
    required this.title,
    this.subtitle,
  }) : _eyebrowText = eyebrow,
       _eyebrowDate = null,
       _locale = null;

  const PageHeader.eyebrowDate(
    DateTime date, {
    super.key,
    required this.title,
    this.subtitle,
    String? locale, // es. 'it_IT'; null = locale di default
  }) : _eyebrowText = null,
       _eyebrowDate = date,
       _locale = locale;

  final String title;
  final String? subtitle;
  final String? _eyebrowText;
  final DateTime? _eyebrowDate;
  final String? _locale;

  static const _gap = 7.0;

  String? get _eyebrow {
    if (_eyebrowText != null) return _eyebrowText!.toUpperCase();
    if (_eyebrowDate != null) {
      return DateFormat(
        'EEEE, MMMM d',
        _locale,
      ).format(_eyebrowDate!).toUpperCase();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final eyebrow = _eyebrow;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 1.8,
              color: scheme.surfaceTint,
            ),
          ),
          const SizedBox(height: _gap),
        ],
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w400,
            fontSize: 32,
            height: 1.15,
            letterSpacing: -0.7,
            color: scheme.inverseSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: _gap),
          Text(
            subtitle!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
