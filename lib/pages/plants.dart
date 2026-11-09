import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/page_header.dart';

class Plants extends StatelessWidget {
  const Plants({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'My plants',
        actionIcon: LucideIcons.plus,
        onActionTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.eyebrowText(
              'MAYA’S LITTLE JUNGLE',
              title: 'Growing, together.',
              subtitle: 'Every leaf has a story. Here are yours.',
            ),
          ],
        ),
      ),
    );
  }
}
