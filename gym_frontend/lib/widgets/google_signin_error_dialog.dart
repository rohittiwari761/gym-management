import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInErrorDialog extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onUseEmail;

  const GoogleSignInErrorDialog({
    Key? key,
    required this.error,
    this.onRetry,
    this.onUseEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdBlockerError = error.contains('blocked') || 
                            error.contains('ad blocker') ||
                            error.contains('ERR_BLOCKED_BY_CLIENT') ||
                            error.contains('play.google.com');

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isAdBlockerError ? Icons.block : Icons.error,
            color: isAdBlockerError ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAdBlockerError 
                  ? 'Google Sign-In Blocked' 
                  : 'Google Sign-In Error',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdBlockerError) ...[
            const Text(
              'Google Sign-In is being blocked by an ad blocker or browser extension.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To fix this issue:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildSolutionItem(
              '1. Disable ad blockers',
              'Turn off uBlock Origin, AdBlock Plus, or similar extensions for this site',
            ),
            _buildSolutionItem(
              '2. Disable privacy extensions',
              'Temporarily disable Ghostery, Privacy Badger, or similar extensions',
            ),
            _buildSolutionItem(
              '3. Try incognito/private window',
              'Extensions are usually disabled in private browsing mode',
            ),
            _buildSolutionItem(
              '4. Use email registration',
              'As an alternative, you can register with your email address',
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a common issue with ad blockers. The app is working correctly.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Text(
              error,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
      actions: [
        if (onUseEmail != null)
          TextButton(
            onPressed: onUseEmail,
            child: const Text('Use Email Instead'),
          ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(isAdBlockerError ? 'Try Again' : 'Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSolutionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String error,
    VoidCallback? onRetry,
    VoidCallback? onUseEmail,
  }) {
    showDialog(
      context: context,
      builder: (context) => GoogleSignInErrorDialog(
        error: error,
        onRetry: onRetry,
        onUseEmail: onUseEmail,
      ),
    );
  }
}