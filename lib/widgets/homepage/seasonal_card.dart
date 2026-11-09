import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeasonalFeatureCard extends StatelessWidget {
  const SeasonalFeatureCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 258,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/autumn_botanical_still_life.png',
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xEB1A3636), Color(0x001A3636)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(23),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: 265,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE INDOOR SEASON',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            color: scheme.secondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bring the outside in.',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 30,
                            height: 1.08,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 240,
                          child: Text(
                            'A slower season. A greener sanctuary.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              height: 1.5,
                              color: scheme.surfaceContainerLow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore the autumn edit',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                LucideIcons.arrowUpRight,
                                size: 17,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}