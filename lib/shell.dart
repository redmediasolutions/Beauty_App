import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:glowfit/components/Floating_Navbar.dart';

class ShellPage extends StatefulWidget {
  final Widget child;

  const ShellPage({
    super.key,
    required this.child,
  });

  @override
  State<ShellPage> createState() =>
      _ShellPageState();
}

class _ShellPageState
    extends State<ShellPage> {
  bool _showNavBar = true;

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCF9F9),

      body: NotificationListener<
          UserScrollNotification>(
        onNotification: (
          notification,
        ) {
          if (notification.direction ==
              ScrollDirection.reverse) {
            if (_showNavBar) {
              setState(() {
                _showNavBar = false;
              });
            }
          }

          if (notification.direction ==
              ScrollDirection.forward) {
            if (!_showNavBar) {
              setState(() {
                _showNavBar = true;
              });
            }
          }

          return false;
        },

        child: Stack(
          children: [
            Positioned.fill(
              child: widget.child,
            ),

            user == null
                ? AnimatedPositioned(
                    duration:
                        const Duration(
                          milliseconds:
                              350,
                        ),
                    curve:
                        Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom:
                        _showNavBar
                            ? MediaQuery.of(
                                      context,
                                    )
                                    .viewPadding
                                    .bottom +
                                25
                            : -120,
                    child:
                        const FloatingNavBar(
                          cartCount: 0,
                        ),
                  )
                : StreamBuilder<
                    QuerySnapshot>(
                    stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                              'carts',
                            )
                            .doc(
                              user.uid,
                            )
                            .collection(
                              'items',
                            )
                            .snapshots(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      int cartCount =
                          0;

                      if (snapshot
                          .hasData) {
                        for (final doc
                            in snapshot
                                .data!
                                .docs) {
                          final data =
                              doc.data()
                                  as Map<
                                    String,
                                    dynamic
                                  >;

                          cartCount +=
                              (data['quantity']
                                          as num?)
                                      ?.toInt() ??
                                  0;
                        }
                      }

                      return AnimatedPositioned(
                        duration:
                            const Duration(
                              milliseconds:
                                  250,
                            ),
                        curve:
                            Curves.easeOut,
                        left: 0,
                        right: 0,
                        bottom:
                            _showNavBar
                                ? MediaQuery.of(
                                          context,
                                        )
                                        .viewPadding
                                        .bottom +
                                    20
                                : -120,
                        child:
                            FloatingNavBar(
                              cartCount:
                                  cartCount,
                            ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}