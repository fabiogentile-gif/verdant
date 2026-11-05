import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/app_bar.dart';

class Plants extends StatelessWidget {
  const Plants({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(title: 'My plants',actionIcon: LucideIcons.plus,onActionTap: () {},),
    );
  }
}
