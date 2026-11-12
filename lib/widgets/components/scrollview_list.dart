import 'package:flutter/material.dart';

class ScrollViewNoStretch extends StatelessWidget {
  const ScrollViewNoStretch({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        controller: controller,
        physics: physics,
        padding: padding,
        scrollDirection: scrollDirection,
        child: child,
      ),
    );
  }
}
