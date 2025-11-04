import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showLogo;
  final bool centerTitle;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showLogo = false,
    this.centerTitle = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: centerTitle
            ? Center(
          child: showLogo
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 32,
                width: 32,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.account_circle),
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          )
              : Text(title),
        )
            : Text(title),
        centerTitle: centerTitle,
        actions: actions,
        backgroundColor: const Color(0xff224562),
        foregroundColor: const Color(0xffe6ebea),
      ),
      body: body,
      backgroundColor: const Color(0xffe6eceb),
    );
  }
}