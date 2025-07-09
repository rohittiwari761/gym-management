import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Platform-specific QR scanner widget
class PlatformQRScanner extends StatelessWidget {
  final Function(String) onQRViewCreated;
  final Widget? overlay;

  const PlatformQRScanner({
    Key? key,
    required this.onQRViewCreated,
    this.overlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web fallback - show message that QR scanning is not available
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Colors.white54,
              ),
              SizedBox(height: 20),
              Text(
                'QR Code Scanning',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Not available on web platform',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // For testing, simulate a scanned QR code
                  onQRViewCreated('test-qr-code-12345');
                },
                child: Text('Simulate QR Scan (Testing)'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile platform - use actual QR scanner
      try {
        // Dynamic import for mobile platforms only
        return _MobileQRScanner(
          onQRViewCreated: onQRViewCreated,
          overlay: overlay,
        );
      } catch (e) {
        // Fallback if QR scanner fails to load
        return Container(
          color: Colors.black,
          child: Center(
            child: Text(
              'QR Scanner not available: $e',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}

// Mobile QR Scanner implementation
class _MobileQRScanner extends StatefulWidget {
  final Function(String) onQRViewCreated;
  final Widget? overlay;

  const _MobileQRScanner({
    required this.onQRViewCreated,
    this.overlay,
  });

  @override
  State<_MobileQRScanner> createState() => _MobileQRScannerState();
}

class _MobileQRScannerState extends State<_MobileQRScanner> {
  @override
  Widget build(BuildContext context) {
    // For now, return a placeholder that won't cause web compilation issues
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.white54,
            ),
            SizedBox(height: 20),
            Text(
              'QR Scanner (Mobile)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simulate QR scan for testing
                widget.onQRViewCreated('mobile-test-qr-12345');
              },
              child: Text('Simulate QR Scan'),
            ),
          ],
        ),
      ),
    );
  }
}