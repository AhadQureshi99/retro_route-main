import 'package:flutter/material.dart';


class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            tileMode: TileMode.clamp,
            colors: [
              Color(0xFF4CB57B), 
              Color(0xFFFFFFFF), 
              Color(0xFFFFFFFF), 
              Color(0xFFFFFFFF), 
              Color(0xFFFFFFFF), 

            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
