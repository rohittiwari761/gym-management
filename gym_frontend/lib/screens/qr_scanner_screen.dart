import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/attendance_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
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
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () async {
              await controller?.flipCamera();
            },
          ),
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
                  color: Colors.blue,
                  size: isTablet ? 32 : 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan Member QR Code',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Position the QR code within the frame to record attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Scanner Area
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.blue,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: isTablet ? 300 : 250,
                  ),
                ),
              ),
            ),
          ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing attendance...',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Manual Entry Option
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showManualEntryDialog(),
              icon: const Icon(Icons.keyboard),
              label: const Text('Manual Entry'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.blue.shade300),
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null && scanData.code != _lastScannedCode) {
        _lastScannedCode = scanData.code;
        _handleQRCodeScanned(scanData.code!);
      }
    });
  }

  Future<void> _handleQRCodeScanned(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Pause camera while processing
      await controller?.pauseCamera();
      
      // Parse member ID from QR code
      int? memberId = _parseMemberIdFromQR(code);
      
      if (memberId != null) {
        await _recordAttendance(memberId);
      } else {
        _showErrorDialog('Invalid QR Code', 'The scanned QR code is not recognized as a valid member code.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to process QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
      
      // Resume camera after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          controller?.resumeCamera();
        }
      });
    }
  }

  int? _parseMemberIdFromQR(String qrCode) {
    try {
      // Try to parse as direct member ID
      if (RegExp(r'^\d+$').hasMatch(qrCode)) {
        return int.parse(qrCode);
      }
      
      // Try to parse from URL format: gym://member/123
      if (qrCode.startsWith('gym://member/')) {
        final idString = qrCode.substring('gym://member/'.length);
        return int.parse(idString);
      }
      
      // Try to parse from JSON format: {"memberId": 123}
      if (qrCode.startsWith('{') && qrCode.endsWith('}')) {
        final decoded = qrCode.replaceAll(RegExp(r'[{}"]'), '');
        final parts = decoded.split(':');
        if (parts.length == 2 && parts[0].trim() == 'memberId') {
          return int.parse(parts[1].trim());
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _recordAttendance(int memberId) async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    try {
      // Find member
      final member = memberProvider.members.firstWhere(
        (m) => m.id == memberId,
        orElse: () => throw Exception('Member not found'),
      );

      // Record attendance
      final success = await attendanceProvider.checkIn(memberId, member.fullName);

      if (success) {
        _showSuccessDialog(member.fullName);
      } else {
        _showErrorDialog('Attendance Failed', attendanceProvider.errorMessage.isNotEmpty 
            ? attendanceProvider.errorMessage 
            : 'Failed to record attendance');
      }
    } catch (e) {
      _showErrorDialog('Member Not Found', 'Member ID $memberId not found in the system.');
    }
  }

  void _showSuccessDialog(String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Attendance Recorded'),
        content: Text('Welcome $memberName!\nAttendance has been recorded successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continue Scanning'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController memberIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Member Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the member ID to record attendance:'),
            const SizedBox(height: 16),
            TextField(
              controller: memberIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Member ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final idText = memberIdController.text.trim();
              if (idText.isNotEmpty) {
                final memberId = int.tryParse(idText);
                if (memberId != null) {
                  Navigator.of(context).pop();
                  _handleQRCodeScanned(idText);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid member ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Record Attendance'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}