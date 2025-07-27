import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../config/app_config.dart';

class QRAttendanceGeneratorScreen extends StatefulWidget {
  const QRAttendanceGeneratorScreen({super.key});

  @override
  State<QRAttendanceGeneratorScreen> createState() => _QRAttendanceGeneratorScreenState();
}

class _QRAttendanceGeneratorScreenState extends State<QRAttendanceGeneratorScreen> {
  String? _qrData;
  bool _isGenerating = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  void _generateQRCode() {
    setState(() {
      _isGenerating = true;
    });

    // Generate QR data with gym info and timestamp
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gymOwner = authProvider.currentUser;
    
    if (gymOwner != null) {
      // Always use production URL for QR codes (so they work when shared)
      const productionBaseUrl = 'https://gym-management-production-2168.up.railway.app';
      final gymId = gymOwner.id;
      final gymName = Uri.encodeComponent(gymOwner.gymName ?? 'Unknown Gym');
      
      // Generate web attendance URL that opens in browser
      _qrData = '$productionBaseUrl/attendance/qr/?gym_id=$gymId&gym_name=$gymName&t=${DateTime.now().millisecondsSinceEpoch}';
    }

    setState(() {
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Attendance Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateQRCode,
            tooltip: 'Generate New QR Code',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareQRCode();
                  break;
                case 'instructions':
                  _showInstructions();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share QR Code'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'instructions',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Instructions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final gymOwner = authProvider.currentUser;
          
          if (gymOwner == null) {
            return const Center(
              child: Text('Unable to generate QR code. Please login again.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Attendance QR Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gymOwner.gymName ?? 'Unknown Gym',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gym ID: ${gymOwner.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // QR Code
                if (_isGenerating)
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating QR Code...'),
                        ],
                      ),
                    ),
                  )
                else if (_qrData != null)
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Info Cards
                _buildInfoCard(
                  'How it works',
                  'Members scan this QR code with their phone camera. A web page opens automatically where they enter their Member ID to log attendance instantly. No app installation required!',
                  Icons.info_outline,
                  Colors.blue,
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  'Web-based',
                  'QR code opens a secure web page linked to your gym. Members can use any smartphone with a camera - no app downloads needed.',
                  Icons.web,
                  Colors.green,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareQRCode,
                        icon: const Icon(Icons.share),
                        label: const Text('Share QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showInstructions,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Instructions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Footer note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Display this QR code at your gym entrance for easy member check-ins',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQRCode() async {
    if (_qrData == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gymName = authProvider.currentUser?.gymName ?? 'Gym';
      
      // Capture the QR code as an image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save the image to a temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr_code_${gymName.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(pngBytes);
      
      // Share the QR code image with text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code to log your attendance at $gymName!\n\n'
              'Instructions:\n'
              '1. Scan the QR code with your phone camera\n'
              '2. A web page will open automatically\n'
              '3. Enter your Member ID on the web page\n'
              '4. Your attendance will be logged instantly\n\n'
              'QR Code URL: $_qrData\n\n'
              'No app installation required!',
        subject: '$gymName - Attendance QR Code',
      );
    } catch (e) {
      // Fallback to text sharing if image sharing fails
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gymName = authProvider.currentUser?.gymName ?? 'Gym';
      
      Share.share(
        'Scan this QR code to log your attendance at $gymName!\n\n'
        'QR Code URL: $_qrData\n\n'
        'Instructions:\n'
        '1. Copy the URL above and open it in your browser, or\n'
        '2. Scan the QR code with your phone camera\n'
        '3. Enter your Member ID on the web page\n'
        '4. Your attendance will be logged instantly\n\n'
        'No app installation required!',
        subject: '$gymName - Attendance QR Code',
      );
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('How to Use QR Attendance'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionStep(
                '1',
                'Display QR Code',
                'Show this QR code at your gym entrance or reception area',
              ),
              _buildInstructionStep(
                '2',
                'Members Scan',
                'Members use their phone camera to scan the code - a web page opens automatically',
              ),
              _buildInstructionStep(
                '3',
                'Enter Member ID',
                'On the web page, members enter their unique Member ID',
              ),
              _buildInstructionStep(
                '4',
                'Instant Logging',
                'Attendance is logged instantly in your system - no app installation needed',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All attendance data is securely logged and associated with your gym',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
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
}