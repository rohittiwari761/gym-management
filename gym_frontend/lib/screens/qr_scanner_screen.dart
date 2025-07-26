import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/attendance_provider.dart';

// Mobile scanner temporarily disabled for iOS compatibility
// import 'package:mobile_scanner/mobile_scanner.dart' if (dart.library.html) 'dart:html' as mobile_scanner;

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  String? _lastScannedCode;
  // MobileScannerController? _controller; // Temporarily disabled

  @override
  void initState() {
    super.initState();
    // Mobile scanner temporarily disabled
    // if (!kIsWeb) {
    //   _controller = MobileScannerController();
    // }
  }

  @override
  void dispose() {
    // _controller?.dispose(); // Temporarily disabled
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!kIsWeb) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () {
                // _controller?.toggleTorch(); // Temporarily disabled
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () {
                // _controller?.switchCamera(); // Temporarily disabled
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Instructions Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                Text(
                  kIsWeb 
                    ? 'QR Scanner - Web Testing Mode'
                    : 'Scan Member QR Code',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                    ? 'QR scanning is not available on web. Use the test button below.'
                    : 'Point the camera at a member\'s QR code to mark attendance.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // QR Scanner Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: kIsWeb 
                ? _buildWebQRScanner()
                : _buildMobileQRScanner(),
            ),
          ),
          
          // Status and Processing Indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    'Processing attendance...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebQRScanner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          const Text(
            'QR Code Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Not available on web platform',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Simulate QR scan for testing
              _onQRScanned('TEST-QR-12345');
            },
            icon: const Icon(Icons.smart_button),
            label: const Text('Simulate QR Scan (Testing)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQRScanner() {
    // Mobile scanner temporarily disabled for iOS compatibility
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          const Text(
            'QR Scanner (Mobile)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'QR scanner temporarily disabled',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _onQRScanned('MOBILE-TEST-QR-67890');
            },
            child: const Text('Simulate QR Scan'),
          ),
        ],
      ),
    );
  }

  void _onQRScanned(String qrCode) async {
    if (_isProcessing || qrCode == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = qrCode;
    });

    try {
      print('📱 QR SCANNER: Scanned code: $qrCode');
      
      // Process the QR code for attendance
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      
      // For testing, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code scanned: $qrCode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Navigate back after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      print('💥 QR SCANNER: Error processing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

}