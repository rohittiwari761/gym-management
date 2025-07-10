import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔐 LOGIN_TEST: Testing login with demo credentials...');
  
  final apiUrl = 'https://gym-management-production-4343.up.railway.app/api';
  print('🌐 LOGIN_TEST: API URL: $apiUrl');
  
  // Test with demo credentials from the app
  final testCredentials = [
    {'email': 'admin@gym.com', 'password': 'admin123'},
    {'email': 'owner@fitnesscenter.com', 'password': 'owner123'},
  ];
  
  for (final creds in testCredentials) {
    try {
      print('🔍 LOGIN_TEST: Testing ${creds["email"]}...');
      
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      
      final uri = Uri.parse('$apiUrl/auth/login/');
      final request = await client.postUrl(uri);
      request.headers.add('Content-Type', 'application/json');
      
      final body = jsonEncode(creds);
      request.write(body);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('📡 LOGIN_TEST: ${creds["email"]} - Status: ${response.statusCode}');
      print('📡 LOGIN_TEST: Response: $responseBody');
      
      if (response.statusCode == 200) {
        print('✅ LOGIN_TEST: Login successful for ${creds["email"]}');
      } else {
        print('❌ LOGIN_TEST: Login failed for ${creds["email"]}');
      }
      
      client.close();
      
    } catch (e) {
      print('💥 LOGIN_TEST: Error testing ${creds["email"]}: $e');
    }
    
    print(''); // Empty line for readability
  }
}