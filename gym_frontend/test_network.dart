import 'dart:convert';
import 'dart:io';

void main() async {
  print('🌐 NETWORK_TEST: Testing Railway API from Dart...');
  
  final apiUrl = 'https://gym-management-production-4343.up.railway.app/api';
  print('🌐 NETWORK_TEST: API URL: $apiUrl');
  
  // Test 1: Basic connectivity
  try {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    final uri = Uri.parse('$apiUrl/');
    final request = await client.getUrl(uri);
    request.headers.add('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ NETWORK_TEST: Basic connectivity successful');
    print('📡 NETWORK_TEST: Status Code: ${response.statusCode}');
    print('📡 NETWORK_TEST: Headers: ${response.headers}');
    print('📡 NETWORK_TEST: Response: $responseBody');
    
    client.close();
    
  } catch (e) {
    print('❌ NETWORK_TEST: Basic connectivity failed: $e');
  }
  
  // Test 2: Login endpoint
  try {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    final uri = Uri.parse('$apiUrl/auth/login/');
    final request = await client.postUrl(uri);
    request.headers.add('Content-Type', 'application/json');
    
    final body = jsonEncode({
      'email': 'test@example.com',
      'password': 'testpassword',
    });
    
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ NETWORK_TEST: Login endpoint accessible');
    print('📡 NETWORK_TEST: Status Code: ${response.statusCode}');
    print('📡 NETWORK_TEST: Response: $responseBody');
    
    client.close();
    
  } catch (e) {
    print('❌ NETWORK_TEST: Login endpoint failed: $e');
  }
}