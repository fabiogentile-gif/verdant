import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/app_bar.dart';

class Greenhouse extends StatelessWidget {
  const Greenhouse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(title: 'The greenhouse',actionIcon: LucideIcons.shoppingBag,onActionTap: () {},),
    );
  }
}
