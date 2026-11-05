import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // Token dal design Figma
  static const _background = Color(0xFFFFFDFA);
  static const _border = Color(0xFFDCE0D6);
  static const _indicator = Color(0xFFE6EBE3);
  static const _active = Color(0xFF1A3636);
  static const _inactive = Color(0xFF77847B);

  // Voce in evidenza (Greenhouse)
  static const _featuredIndex = 2;
  static const _featuredIdle = Color(0xFF677D6A);
  static const _circleSize = 52.0;
  static const _protrusion = 22.0; // quanto il cerchio esce sopra la barra
  static const _gap = 6.0; // spazio tra cerchio e bordo dell'incavo

  static const _items = [
    _NavItemData('Home', LucideIcons.house),
    _NavItemData('Plants', LucideIcons.sprout),
    _NavItemData('Greenhouse', LucideIcons.warehouse),
    _NavItemData('Activity', LucideIcons.bell),
    _NavItemData('Profile', LucideIcons.userRound),
  ];

  @override
  Widget build(BuildContext context) {
    final featuredSelected = currentIndex == _featuredIndex;
    final featuredColor = featuredSelected ? _active : _featuredIdle;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Sfondo della barra con incavo
          Positioned.fill(
            child: CustomPaint(
              painter: _BarPainter(
                top: _protrusion,
                notchDepth: _circleSize - _protrusion + _gap,
                notchHalfWidth: _circleSize / 2 + 22,
                fill: _background,
                border: _border,
              ),
            ),
          ),
          // Contenuto della barra
          Padding(
            padding: const EdgeInsets.only(top: _protrusion),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavItem(
                          data: _items[i],
                          selected: i == currentIndex,
                          featured: i == _featuredIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Cerchio in evidenza, centrato e sporgente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                selected: featuredSelected,
                label: _items[_featuredIndex].label,
                excludeSemantics: true,
                child: Material(
                  color: featuredColor,
                  elevation: 6,
                  shadowColor: featuredColor.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onTap(_featuredIndex),
                    child: SizedBox.square(
                      dimension: _circleSize,
                      child: Icon(
                        _items[_featuredIndex].icon,
                        size: 24,
                        color: _background,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.top,
    required this.notchDepth,
    required this.notchHalfWidth,
    required this.fill,
    required this.border,
  });

  final double top; // y del bordo superiore della barra
  final double notchDepth; // profondità dell'incavo sotto il bordo
  final double notchHalfWidth; // metà larghezza dell'incavo
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ctrl = notchHalfWidth * 0.625; // morbidezza della curva

    // Bordo superiore con incavo
    final edge = Path()
      ..moveTo(0, top)
      ..lineTo(cx - notchHalfWidth, top)
      ..cubicTo(cx - ctrl, top, cx - ctrl, top + notchDepth, cx, top + notchDepth)
      ..cubicTo(cx + ctrl, top + notchDepth, cx + ctrl, top, cx + notchHalfWidth, top)
      ..lineTo(size.width, top);

    final body = Path.from(edge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.12), 4, false);
    canvas.drawPath(body, Paint()..color = fill);
    canvas.drawPath(
      edge,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.top != top ||
      old.notchDepth != notchDepth ||
      old.notchHalfWidth != notchHalfWidth ||
      old.fill != fill ||
      old.border != border;
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.featured,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppBottomNavigation._active : AppBottomNavigation._inactive;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (featured)
              // Spazio lasciato al cerchio (disegnato sopra, nello Stack)
              const SizedBox(height: 30)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppBottomNavigation._indicator
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(data.icon, size: 21, color: color),
              ),
            Text(
              data.label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}