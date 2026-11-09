import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/search_bar.dart';

class Greenhouse extends StatelessWidget {
  const Greenhouse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'The greenhouse',
        actionIcon: LucideIcons.shoppingBag,
        onActionTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Room to grow.',
              subtitle: 'Thoughtfully grown plants and beautiful things to help them thrive.',
            ),
            SizedBox(height: 28),
            AppSearchField(hintText: 'Search plants, pots & essentials'),
          ],
        ),
      ),
    );
  }
}
