import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/page_header.dart';

class Activity extends StatelessWidget {
  const Activity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Activity',
        actionIcon: LucideIcons.calendarDays,
        onActionTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.eyebrowDate(
              DateTime.now(),
              title: 'A moment of care.',
              subtitle: 'Little rituals. Happier plants. All in one place.',
            ),
          ],
        ),
      ),
    );
  }
}
