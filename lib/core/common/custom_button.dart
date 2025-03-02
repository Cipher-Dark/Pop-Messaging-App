import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Widget? child;
  final String? text;
  final Function()? onPressed;
  const CustomButton({
    super.key,
    this.child,
    this.text,
    this.onPressed,
  }) : assert(
          text != null || child != null,
          'Either text or child must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed == null
            ? null
            : () async {
                await onPressed?.call();
              },
        child: child ??
            Text(
              text!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}
