//views/widgets/sport_tile.dart
import 'package:flutter/material.dart';
import 'package:the_shot2/components/theme.dart';
import 'package:the_shot2/models/sport_category.dart';

class SportTile extends StatelessWidget {
  final SportCategory sport;
  final VoidCallback onTap;

  const SportTile({Key? key, required this.sport, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kGradientStart, kGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              sport.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}