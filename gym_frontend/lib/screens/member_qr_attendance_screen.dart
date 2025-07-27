import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/platform_qr_scanner.dart';

class MemberQRAttendanceScreen extends StatefulWidget {
  final String? scannedData;
  
  const MemberQRAttendanceScreen({
    super.key,
    this.scannedData,
  });

  @override
  State<MemberQRAttendanceScreen> createState() => _MemberQRAttendanceScreenState();
}

class _MemberQRAttendanceScreenState extends State<MemberQRAttendanceScreen> {
  final TextEditingController _memberIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String? _scannedQRData;
  String? _gymInfo;
  bool _isProcessing = false;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.scannedData != null) {
      _processScannedData(widget.scannedData!);
    } else {
      _showScanner = true;
    }
  }

  @override
  void dispose() {
    _memberIdController.dispose();
    super.dispose();
  }

  void _processScannedData(String qrData) {
    setState(() {
      _scannedQRData = qrData;
      _showScanner = false;
    });

    // Parse QR data
    try {
      // Try JSON format first (new format)
      final jsonData = json.decode(qrData);
      if (jsonData['type'] == 'gym_attendance') {
        final gymId = jsonData['gym_id'];
        final gymName = jsonData['gym_name'];
        _gymInfo = 'Gym: $gymName (ID: $gymId)';
      }
    } catch (e) {
      // Fallback to old colon-separated format for backward compatibility
      try {
        if (qrData.startsWith('gym_attendance:')) {
          final parts = qrData.split(':');
          if (parts.length >= 3) {
            final gymId = parts[1];
            final gymName = Uri.decodeComponent(parts[2]);
            _gymInfo = 'Gym: $gymName (ID: $gymId)';
          }
        }
      } catch (e2) {
        print('Error parsing QR data: $e2');
        _gymInfo = 'Valid gym QR code detected';
      }
    }

    // Show member ID input
    setState(() {});
  }

  Future<void> _logAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final memberId = _memberIdController.text.trim();
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      
      // Extract gym info from QR data
      String? gymId;
      if (_scannedQRData != null) {
        try {
          // Try JSON format first
          final jsonData = json.decode(_scannedQRData!);
          if (jsonData['type'] == 'gym_attendance') {
            gymId = jsonData['gym_id'];
          }
        } catch (e) {
          // Fallback to old format
          if (_scannedQRData!.startsWith('gym_attendance:')) {
            final parts = _scannedQRData!.split(':');
            if (parts.length >= 2) {
              gymId = parts[1];
            }
          }
        }
      }

      // Log attendance via QR
      final success = await attendanceProvider.logAttendanceViaQR(
        memberId: memberId,
        qrData: _scannedQRData!,
        gymId: gymId,
      );

      if (success && mounted) {
        // Show success message
        _showSuccessDialog();
      } else if (mounted) {
        // Show error message
        _showErrorDialog(attendanceProvider.errorMessage ?? 'Failed to log attendance');
      }
      
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Attendance'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_showScanner && _scannedQRData != null)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                setState(() {
                  _showScanner = true;
                  _scannedQRData = null;
                  _gymInfo = null;
                  _memberIdController.clear();
                });
              },
              tooltip: 'Scan New QR Code',
            ),
        ],
      ),
      body: _showScanner ? _buildQRScanner() : _buildMemberIdForm(),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.green[50],
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: Colors.green[700],
              ),
              const SizedBox(height: 16),
              Text(
                'Scan Gym QR Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at the QR code displayed at the gym',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
        ),
        
        // QR Scanner
        Expanded(
          child: PlatformQRScanner(
            onQRViewCreated: _processScannedData,
          ),
        ),

        // Manual entry option
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Having trouble scanning?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Enter QR Data Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberIdForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success indicator
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QR Code Scanned Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (_gymInfo != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _gymInfo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Member ID input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Your Member ID',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _memberIdController,
                      decoration: const InputDecoration(
                        labelText: 'Member ID',
                        hintText: 'Enter your member ID (e.g., 1001, 1002)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your member ID';
                        }
                        if (value.trim().length < 3) {
                          return 'Member ID must be at least 3 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _logAttendance(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your member ID is provided when you joined the gym. If you don\'t know it, please contact the gym staff.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Log attendance button
            ElevatedButton(
              onPressed: _isProcessing ? null : _logAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Logging Attendance...'),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Log My Attendance'),
                    ],
                  ),
            ),

            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your attendance will be recorded with the current date and time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController manualController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter QR Data Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the QR code data here:'),
            const SizedBox(height: 16),
            TextField(
              controller: manualController,
              decoration: const InputDecoration(
                labelText: 'QR Data',
                hintText: 'gym_attendance:123:GymName:...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              final data = manualController.text.trim();
              if (data.isNotEmpty) {
                Navigator.of(context).pop();
                _processScannedData(data);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Attendance Logged!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your attendance has been successfully recorded.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close attendance screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
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
}