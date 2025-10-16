import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButtonHandler extends StatelessWidget {
  final Widget child;
  final String? fallbackRoute;

  const AppBackButtonHandler({
    super.key,
    required this.child,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackPress(context);
        }
      },
      child: child,
    );
  }

  Future<void> _handleBackPress(BuildContext context) async {
    if (context.canPop()) {
      context.pop();
    } else if (fallbackRoute != null) {
      context.go(fallbackRoute!);
    } else {
      context.go('/search');
    }
  }
}
