import 'package:flutter/material.dart';
import 'package:verdant/app_bar.dart';
import 'package:verdant/widgets/components/page_header.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar.home(hasUnread: false, onActionTap: () {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.eyebrowDate(
              DateTime.now(),
              title: 'A little greener, Maya.',
              subtitle: 'Good things grow with a little care.',
            ),
          ],
        ),
      ),
    );
  }
}
