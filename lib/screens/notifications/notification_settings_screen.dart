import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushAlerts = true;
  bool _morningBrief = true;
  bool _eveningSummary = true;
  bool _premiumAlerts = false;
  bool _whatsapp = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.getPreferences().then((prefs) {
      setState(() {
        _pushAlerts = prefs['pushAlerts'] ?? true;
        _morningBrief = prefs['morningBrief'] ?? true;
        _eveningSummary = prefs['eveningSummary'] ?? true;
        _premiumAlerts = prefs['premiumAlerts'] ?? false;
        _whatsapp = prefs['whatsapp'] ?? false;
        _loading = false;
      });
    });
  }

  Future<bool> _push() {
    return NotificationService.instance.updatePreferences(
      pushAlerts: _pushAlerts,
      morningBrief: _morningBrief,
      eveningSummary: _eveningSummary,
      premiumAlerts: _premiumAlerts,
      whatsapp: _whatsapp,
    );
  }

  void _showPremiumRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This requires Premium')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Push Alerts'),
            value: _pushAlerts,
            onChanged: (v) async {
              setState(() => _pushAlerts = v);
              await _push();
            },
          ),
          SwitchListTile(
            title: const Text('Morning Brief'),
            value: _morningBrief,
            onChanged: (v) async {
              setState(() => _morningBrief = v);
              await _push();
            },
          ),
          SwitchListTile(
            title: const Text('Evening Summary'),
            value: _eveningSummary,
            onChanged: (v) async {
              setState(() => _eveningSummary = v);
              await _push();
            },
          ),
          SwitchListTile(
            title: const Text('Premium Alerts (Premium)'),
            value: _premiumAlerts,
            onChanged: (v) async {
              final prevValue = _premiumAlerts;
              setState(() => _premiumAlerts = v);
              final ok = await _push();
              if (!mounted) return;
              if (!ok) {
                setState(() => _premiumAlerts = prevValue);
                _showPremiumRequired();
              }
            },
          ),
          SwitchListTile(
            title: const Text('WhatsApp Alerts (Premium)'),
            value: _whatsapp,
            onChanged: (v) async {
              final prevValue = _whatsapp;
              setState(() => _whatsapp = v);
              final ok = await _push();
              if (!mounted) return;
              if (!ok) {
                setState(() => _whatsapp = prevValue);
                _showPremiumRequired();
              }
            },
          ),
        ],
      ),
    );
  }
}
