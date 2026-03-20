import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  const Avatar({super.key, this.imageUrl, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image:
              imageUrl != null
                  ? NetworkImage(imageUrl!)
                  : const AssetImage("assets/logo.png") as ImageProvider,
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withAlpha(200),
            blurRadius: 4,
            spreadRadius: 3,
            // offset: const Offset(0, -2),
          ),
        ],
      ),
    );
  }
}