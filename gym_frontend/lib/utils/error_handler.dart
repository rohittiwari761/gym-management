import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/unified_api_service.dart';

/// Comprehensive error handling system for the gym management app
class ErrorHandler {
  static const String _tag = 'ErrorHandler';
  
  // Error categories
  static const String _networkError = 'NETWORK_ERROR';
  static const String _authError = 'AUTH_ERROR';
  static const String _validationError = 'VALIDATION_ERROR';
  static const String _serverError = 'SERVER_ERROR';
  static const String _unknownError = 'UNKNOWN_ERROR';
  
  /// Handle API errors and provide user-friendly messages
  static ErrorInfo handleApiError(dynamic error, {String? context}) {
    String category = _unknownError;
    String userMessage = 'An unexpected error occurred. Please try again.';
    String technicalMessage = error.toString();
    bool isRecoverable = true;
    
    // Log error for debugging
    _logError(error, context);
    
    if (error is ApiException) {
      category = _determineApiErrorCategory(error.statusCode);
      userMessage = _getApiErrorMessage(error.statusCode, error.message);
      technicalMessage = error.toString();
      isRecoverable = _isRecoverableStatusCode(error.statusCode);
    } else if (error.toString().contains('SocketException')) {
      category = _networkError;
      userMessage = 'Unable to connect to the server. Please check your internet connection.';
      isRecoverable = true;
    } else if (error.toString().contains('TimeoutException')) {
      category = _networkError;
      userMessage = 'Request timed out. Please try again.';
      isRecoverable = true;
    } else if (error.toString().contains('FormatException')) {
      category = _serverError;
      userMessage = 'Server returned invalid data. Please try again later.';
      isRecoverable = true;
    } else if (error.toString().contains('HandshakeException')) {
      category = _networkError;
      userMessage = 'Secure connection failed. Please try again.';
      isRecoverable = true;
    }
    
    return ErrorInfo(
      category: category,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRecoverable: isRecoverable,
      context: context,
    );
  }
  
  /// Handle validation errors
  static ErrorInfo handleValidationError(String field, String message) {
    return ErrorInfo(
      category: _validationError,
      userMessage: message,
      technicalMessage: 'Validation failed for field: $field',
      isRecoverable: true,
      context: 'validation',
    );
  }
  
  /// Handle authentication errors
  static ErrorInfo handleAuthError(String message) {
    return ErrorInfo(
      category: _authError,
      userMessage: message.isNotEmpty ? message : 'Authentication failed. Please login again.',
      technicalMessage: 'Authentication error: $message',
      isRecoverable: true,
      context: 'authentication',
    );
  }
  
  /// Show error dialog to user
  static Future<void> showErrorDialog(BuildContext context, ErrorInfo errorInfo) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getErrorIcon(errorInfo.category),
                color: _getErrorColor(errorInfo.category),
              ),
              const SizedBox(width: 8),
              Text(_getErrorTitle(errorInfo.category)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorInfo.userMessage),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Technical Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorInfo.technicalMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (errorInfo.isRecoverable) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement retry logic
                },
                child: const Text('Retry'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ],
        );
      },
    );
  }
  
  /// Show error snackbar
  static void showErrorSnackbar(BuildContext context, ErrorInfo errorInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(errorInfo.category),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(errorInfo.userMessage)),
          ],
        ),
        backgroundColor: _getErrorColor(errorInfo.category),
        duration: const Duration(seconds: 4),
        action: errorInfo.isRecoverable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implement retry logic
                },
              )
            : null,
      ),
    );
  }
  
  /// Determine error category from status code
  static String _determineApiErrorCategory(int? statusCode) {
    if (statusCode == null) return _networkError;
    
    if (statusCode >= 400 && statusCode < 500) {
      if (statusCode == 401 || statusCode == 403) {
        return _authError;
      } else if (statusCode == 422 || statusCode == 400) {
        return _validationError;
      } else {
        return _validationError;
      }
    } else if (statusCode >= 500) {
      return _serverError;
    } else {
      return _unknownError;
    }
  }
  
  /// Get user-friendly error message from status code
  static String _getApiErrorMessage(int? statusCode, String originalMessage) {
    if (statusCode == null) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'You are not authorized. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return originalMessage.isNotEmpty ? originalMessage : 'Invalid data provided.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server temporarily unavailable. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      case 504:
        return 'Request timed out. Please try again.';
      default:
        return originalMessage.isNotEmpty ? originalMessage : 'An unexpected error occurred.';
    }
  }
  
  /// Check if error is recoverable
  static bool _isRecoverableStatusCode(int? statusCode) {
    if (statusCode == null) return true;
    
    // Non-recoverable errors
    if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
      return false;
    }
    
    return true;
  }
  
  /// Get error icon
  static IconData _getErrorIcon(String category) {
    switch (category) {
      case _networkError:
        return Icons.wifi_off;
      case _authError:
        return Icons.lock;
      case _validationError:
        return Icons.warning;
      case _serverError:
        return Icons.error;
      default:
        return Icons.error_outline;
    }
  }
  
  /// Get error color
  static Color _getErrorColor(String category) {
    switch (category) {
      case _networkError:
        return Colors.orange;
      case _authError:
        return Colors.red;
      case _validationError:
        return Colors.amber;
      case _serverError:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Get error title
  static String _getErrorTitle(String category) {
    switch (category) {
      case _networkError:
        return 'Connection Error';
      case _authError:
        return 'Authentication Error';
      case _validationError:
        return 'Validation Error';
      case _serverError:
        return 'Server Error';
      default:
        return 'Error';
    }
  }
  
  /// Log error for debugging
  static void _logError(dynamic error, String? context) {
    if (kDebugMode) {
      print('$_tag: ${context ?? 'Unknown context'} - $error');
    }
    
    // TODO: Send to crash reporting service (Sentry, Firebase Crashlytics, etc.)
  }
}

/// Error information class
class ErrorInfo {
  final String category;
  final String userMessage;
  final String technicalMessage;
  final bool isRecoverable;
  final String? context;
  
  ErrorInfo({
    required this.category,
    required this.userMessage,
    required this.technicalMessage,
    required this.isRecoverable,
    this.context,
  });
  
  @override
  String toString() {
    return 'ErrorInfo(category: $category, userMessage: $userMessage, context: $context)';
  }
}