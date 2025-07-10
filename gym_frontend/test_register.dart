import 'dart:convert';
import 'dart:io';

void main() async {
  print('📝 REGISTER_TEST: Testing user registration...');
  
  final apiUrl = 'https://gym-management-production-4343.up.railway.app/api';
  print('🌐 REGISTER_TEST: API URL: $apiUrl');
  
  // Test registration with demo credentials
  final registrationData = {
    'email': 'admin@gym.com',
    'password': 'admin123',
    'first_name': 'Admin',
    'last_name': 'User',
    'gym_name': 'Demo Gym',
    'gym_address': '123 Main St',
    'gym_description': 'A demo gym for testing',
    'phone_number': '123-456-7890',
  };
  
  try {
    print('🔍 REGISTER_TEST: Registering user...');
    
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    final uri = Uri.parse('$apiUrl/auth/register/');
    final request = await client.postUrl(uri);
    request.headers.add('Content-Type', 'application/json');
    
    final body = jsonEncode(registrationData);
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📡 REGISTER_TEST: Status: ${response.statusCode}');
    print('📡 REGISTER_TEST: Response: $responseBody');
    
    if (response.statusCode == 201) {
      print('✅ REGISTER_TEST: Registration successful!');
      
      // Now test login
      print('🔐 REGISTER_TEST: Testing login after registration...');
      
      final loginUri = Uri.parse('$apiUrl/auth/login/');
      final loginRequest = await client.postUrl(loginUri);
      loginRequest.headers.add('Content-Type', 'application/json');
      
      final loginBody = jsonEncode({
        'email': registrationData['email'],
        'password': registrationData['password'],
      });
      loginRequest.write(loginBody);
      
      final loginResponse = await loginRequest.close();
      final loginResponseBody = await loginResponse.transform(utf8.decoder).join();
      
      print('📡 REGISTER_TEST: Login Status: ${loginResponse.statusCode}');
      print('📡 REGISTER_TEST: Login Response: $loginResponseBody');
      
      if (loginResponse.statusCode == 200) {
        print('✅ REGISTER_TEST: Login successful after registration!');
      } else {
        print('❌ REGISTER_TEST: Login failed after registration');
      }
    } else {
      print('❌ REGISTER_TEST: Registration failed');
    }
    
    client.close();
    
  } catch (e) {
    print('💥 REGISTER_TEST: Error: $e');
  }
}