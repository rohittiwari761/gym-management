import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GymLogoAvatar extends StatelessWidget {
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final String? gymLogoUrl;
  final IconData fallbackIcon;

  const GymLogoAvatar({
    super.key,
    this.radius = 30,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
    this.gymLogoUrl,
    this.fallbackIcon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: _buildAvatarContent(),
    );
  }

  Widget _buildAvatarContent() {
    // Try to load gym logo first
    if (gymLogoUrl != null && gymLogoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          gymLogoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('Failed to load gym logo from URL: $gymLogoUrl');
            }
            return _buildAssetImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingContent();
          },
        ),
      );
    }

    // Load local gym logo asset
    return _buildAssetImage();
  }

  Widget _buildAssetImage() {
    return ClipOval(
      child: Image.asset(
        'assets/images/gym_logo.png',
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Failed to load gym logo asset: $error');
          }
          return _buildFallbackContent();
        },
      ),
    );
  }

  Widget _buildFallbackContent() {
    return Icon(
      fallbackIcon,
      size: radius * 0.8,
      color: iconColor,
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      width: radius * 0.6,
      height: radius * 0.6,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
      ),
    );
  }
}