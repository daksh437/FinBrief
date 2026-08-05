import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const GoogleSignInButton({super.key, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No bundled Google "G" asset yet — a plain icon avoids an
                // offline-dependent network image for something this small.
                Icon(Icons.login, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text('Continue with Google'),
              ],
            ),
    );
  }
}
