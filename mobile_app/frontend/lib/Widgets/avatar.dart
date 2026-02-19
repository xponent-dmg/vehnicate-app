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
        image:
            imageUrl != null
                ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withAlpha(200),
            blurRadius: 4,
            spreadRadius: 3,
            // offset: const Offset(0, -2),
          ),
        ],
      ),
      child:
          imageUrl == null
              ? Icon(
                Icons.person,
                size: size * 0.6,
                color: const Color.fromARGB(140, 255, 255, 255),
              )
              : null,
    );
  }
}
