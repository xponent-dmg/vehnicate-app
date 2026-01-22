import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Widgets/typewriter_text.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 10,bottom:15, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to vehnicate,',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isLoading) {
                      return Padding(
                        padding: EdgeInsets.only(left: 8, right: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.withValues(alpha: 0.2),
                          highlightColor: Colors.white,
                          loop: 5,
                          child: Container(
                            width: 200,
                            height: 30,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    }
                    if (userProvider.currentUser != null) {
                      return TypewriterText(
                          "${userProvider.currentUser?.name}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),

          // Actions section
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Hero(
              tag: 'profile-avatar',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF8E44AD),
                child: Transform.translate(offset: const Offset(0, 1.2), child: Image.asset("assets/logo.png")),
              ),
            ),
          ),
        ],
      ),
    );
    ;
  }
}
