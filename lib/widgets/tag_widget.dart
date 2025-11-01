import 'package:flutter/material.dart';

class TagWidget extends StatelessWidget {
  final String tag;

  const TagWidget({Key? key, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.deepOrangeAccent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}