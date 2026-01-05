import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Function(int) onTabChange;
  const HomePage({super.key, required this.onTabChange});

  Widget previewCard({
    required String title,
    required Widget previewContent,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(15),
        height: 180,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Center(child: previewContent),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        previewCard(
          title: "Clock",
          color: Colors.blue,
          onTap: () => onTabChange(2),
          previewContent: const Icon(Icons.access_time, size: 40),
        ),
        previewCard(
          title: "Weather",
          color: Colors.orange,
          onTap: () => onTabChange(1),
          previewContent: const Icon(Icons.wb_sunny, size: 40),
        ),
        previewCard(
          title: "Map",
          color: Colors.green,
          onTap: () => onTabChange(3),
          previewContent: const Icon(Icons.map, size: 40),
        ),
      ],
    );
  }
}
