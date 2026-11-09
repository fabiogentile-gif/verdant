import 'package:flutter/material.dart';
import 'package:verdant/app_bar.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar.home(hasUnread: false,onActionTap: () {},),
    );
  }
}
