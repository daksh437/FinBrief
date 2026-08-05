import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Wraps the app to show a slim "offline" banner whenever there's no network
// connection, regardless of which screen is currently showing.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted) setState(() => _offline = offline);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          Material(
            color: AppColors.danger,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('You\'re offline', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
