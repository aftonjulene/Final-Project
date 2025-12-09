import 'package:flutter/material.dart';


class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? const Color(0xFF1a1d2e),
          side: BorderSide(
            color: borderColor ?? const Color(0xFF1a1d2e),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? const Color(0xFF1a1d2e),
          ),
        ),
      ),
    );
  }
}

