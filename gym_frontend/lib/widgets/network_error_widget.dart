import 'package:flutter/material.dart';
import '../services/offline_handler.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const NetworkErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              OfflineHandler.isOffline ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: OfflineHandler.isOffline ? Colors.orange : Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              OfflineHandler.isOffline 
                  ? 'You are offline'
                  : 'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: OfflineHandler.isOffline ? Colors.orange : Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 
              (OfflineHandler.isOffline 
                  ? 'Please check your internet connection and try again.'
                  : 'Unable to connect to server. Please try again.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  if (OfflineHandler.isOffline) {
                    final reconnected = await OfflineHandler.attemptReconnection();
                    if (reconnected || onRetry != null) {
                      onRetry!();
                    }
                  } else {
                    onRetry!();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Troubleshooting Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Check your WiFi or mobile data connection\n'
                    '• Make sure you have internet access\n'
                    '• Try refreshing the page\n'
                    '• Contact support if the problem persists',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}