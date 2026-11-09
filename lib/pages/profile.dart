import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/page_header.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Profile',
        actionIcon: LucideIcons.settings,
        onActionTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.eyebrowText(
              'YOUR VERDANT WORLD',
              title: 'Rooted in you.',
              subtitle: 'A little space for you and your growing world.',
            ),
          ],
        ),
      ),
    );
  }
}
