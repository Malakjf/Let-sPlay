import 'package:flutter/material.dart';

class LogoButton extends StatelessWidget {
  const LogoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
