import 'package:flutter/material.dart';

void showAppSnackBar(
    BuildContext context,
    String message, {
        Color? color,
        Duration duration = const Duration(seconds: 1),
    }) 
{
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: duration,
        ),
    );
}