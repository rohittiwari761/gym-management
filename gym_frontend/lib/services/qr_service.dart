import 'dart:convert';
// QR code generation temporarily disabled - requires qr_flutter package
// import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRService {
  static String generateMemberQRData(int memberId, String memberName) {
    return jsonEncode({
      'type': 'gym_member',
      'member_id': memberId,
      'member_name': memberName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      if (data['type'] == 'gym_member') {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Widget buildQRCode(String data, {double size = 200.0}) {
    // Placeholder widget when QR package is disabled
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'QR Code\n(Package Disabled)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildMemberQRCard({
    required int memberId,
    required String memberName,
    double qrSize = 150.0,
  }) {
    final qrData = generateMemberQRData(memberId, memberName);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              memberName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: buildQRCode(qrData, size: qrSize),
            ),
            const SizedBox(height: 12),
            Text(
              'Member ID: $memberId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'QR code generation disabled',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}