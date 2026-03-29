import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});
  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _wasOffline = false;
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final isOffline = result.every((r) => r == ConnectivityResult.none);
    
    setState(() {
      if (isOffline) {
        _isOffline = true;
        _wasOffline = true;
        _showRestoredBanner = false;
        _restoredTimer?.cancel();
      } else {
        _isOffline = false;
        if (_wasOffline) {
          _showRestoredBanner = true;
          _restoredTimer?.cancel();
          _restoredTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _showRestoredBanner = false);
            }
          });
          _wasOffline = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isOffline)
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.amber.shade700,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    "You're offline — showing cached data",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          if (_showRestoredBanner)
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.green.shade600,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    "Back online ✓",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
