import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaConnectButton extends StatefulWidget {
  final bool isConnected;
  final Function(bool)? onConnectionStatusChanged;

  const StravaConnectButton({
    super.key,
    required this.isConnected,
    this.onConnectionStatusChanged,
  });

  @override
  _StravaConnectButtonState createState() => _StravaConnectButtonState();
}

class _StravaConnectButtonState extends State<StravaConnectButton> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // No need for _connectStrava here since we're not initiating a connection on start
  }

  Future<void> _connectStrava() async {
    const clientId = '117285';
    const redirectUri = 'https://fitglide.in/callback';
    const scope = 'read,activity:read_all';
    final authorizationUrl =
        'https://www.strava.com/oauth/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope';

    if (await canLaunchUrl(Uri.parse(authorizationUrl))) {
      await launchUrl(
        Uri.parse(authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch $authorizationUrl');
    }
  }

  Future<void> _unbindStrava() async {
    await _storage.delete(key: 'athlete_id'); // Use the correct key name here
    widget.onConnectionStatusChanged?.call(false);
    // No need for setState here because we're not managing state internally
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (widget.isConnected) {
          await _unbindStrava();
        } else {
          await _connectStrava();
        }
        // If onConnectionStatusChanged is provided, we toggle the status here
        widget.onConnectionStatusChanged?.call(!widget.isConnected);
      },
      child: Text(widget.isConnected ? 'Unbind Strava' : 'Connect Strava'),
    );
  }
}