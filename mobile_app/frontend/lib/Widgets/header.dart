import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Widgets/avatar.dart';
import 'package:vehnicate_frontend/Widgets/typewriter_text.dart';

class Header extends StatefulWidget {
  final String pageName;
  final int pageIndex;
  const Header({super.key, required this.pageName, required this.pageIndex});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool _slideUp = true;

  @override
  void didUpdateWidget(Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageIndex != oldWidget.pageIndex) {
      _slideUp = widget.pageIndex > oldWidget.pageIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 10, bottom: 15, left: 25, right: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Welcome to ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ClipRect(
                    child: SizedBox(
                      height: 30,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        layoutBuilder: (
                          Widget? currentChild,
                          List<Widget> previousChildren,
                        ) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          final double offset = _slideUp ? 1.0 : -1.0;
                          final inAnimation = Tween<Offset>(
                            begin: Offset(0.0, offset),
                            end: Offset.zero,
                          ).animate(animation);
                          final outAnimation = Tween<Offset>(
                            begin: Offset(0.0, -offset),
                            end: Offset.zero,
                          ).animate(animation);

                          if (child.key == ValueKey(widget.pageName)) {
                            return SlideTransition(
                              position: inAnimation,
                              child: child,
                            );
                          } else {
                            return SlideTransition(
                              position: outAnimation,
                              child: child,
                            );
                          }
                        },
                        child: Text(
                          widget.pageName,
                          key: ValueKey(widget.pageName),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  if (userProvider.isLoading) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.withValues(alpha: 0.2),
                      highlightColor: Colors.white,
                      loop: 5,
                      child: Container(
                        width: 200,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                  if (userProvider.currentUser != null) {
                    return TypewriterText(
                      "${userProvider.currentUser?.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
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
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  final profilePic = user?.profilePictureUrl;
                  return Avatar(imageUrl: profilePic, size: 60);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
