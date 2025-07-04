import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';

// Material Design 3 Responsive Card Widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? surfaceTintColor;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.outlined = false,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: margin ?? context.cardMargin,
      child: Card(
        color: color ?? (outlined ? Colors.transparent : colorScheme.surfaceContainer),
        elevation: elevation ?? (outlined ? 0 : AppElevation.level1),
        shadowColor: colorScheme.shadow,
        surfaceTintColor: surfaceTintColor ?? colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          side: outlined 
              ? BorderSide(color: colorScheme.outline, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Material Design 3 Status Badge (Chip-like)
class StatusBadge extends StatelessWidget {
  final String status;
  final String? text;
  final IconData? icon;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.status,
    this.text,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: outlined 
            ? Colors.transparent 
            : AppTheme.getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppTheme.getStatusBorderColor(status),
          width: outlined ? 1 : 0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: AppTheme.getStatusTextColor(status),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text ?? status.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppTheme.getStatusTextColor(status),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Material Design 3 Loading Widget
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final bool linear;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.linear = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (linear)
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                backgroundColor: colorScheme.surfaceContainerHigh,
              ),
            )
          else
            SizedBox(
              width: size ?? 48,
              height: size ?? 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                backgroundColor: colorScheme.surfaceContainerHigh,
                strokeWidth: 4,
              ),
            ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Material Design 3 Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final bool useIllustration;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.useIllustration = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.containerPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Illustration
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppBorderRadius.extraLarge),
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            
            // Title
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Action Button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: AppSpacing.xl),
              ResponsiveButton(
                text: actionText!,
                onPressed: onAction,
                type: ButtonType.filled,
                icon: AppIcons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Material Design 3 Error Widget
class ErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? customIcon;

  const ErrorWidget({
    super.key,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.containerPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon Container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppBorderRadius.extraLarge),
              ),
              child: Icon(
                customIcon ?? AppIcons.error,
                size: 48,
                color: AppTheme.errorRed,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            
            // Error Title
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Error Message
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Retry Button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: AppSpacing.xl),
              ResponsiveButton(
                text: actionText!,
                onPressed: onAction,
                type: ButtonType.filled,
                color: AppTheme.errorRed,
                icon: AppIcons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Material Design 3 Responsive Button
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonType type;
  final Color? color;
  final bool expanded;
  final bool iconFirst;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.filled,
    this.color,
    this.expanded = false,
    this.iconFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget buildButtonChild() {
      if (isLoading) {
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLoadingColor(colorScheme),
            ),
          ),
        );
      }
      
      if (icon != null) {
        final iconWidget = Icon(icon, size: 18);
        final textWidget = Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [iconWidget, const SizedBox(width: 8), textWidget]
              : [textWidget, const SizedBox(width: 8), iconWidget],
        );
      }
      
      return Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    Widget button;
    switch (type) {
      case ButtonType.filled:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: color != null
              ? FilledButton.styleFrom(backgroundColor: color)
              : null,
          child: buildButtonChild(),
        );
        break;
      case ButtonType.elevated:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: color != null
              ? ElevatedButton.styleFrom(backgroundColor: color)
              : null,
          child: buildButtonChild(),
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: color != null
              ? OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color!),
                )
              : null,
          child: buildButtonChild(),
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: color != null
              ? TextButton.styleFrom(foregroundColor: color)
              : null,
          child: buildButtonChild(),
        );
        break;
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
  
  Color _getLoadingColor(ColorScheme colorScheme) {
    switch (type) {
      case ButtonType.filled:
      case ButtonType.elevated:
        return colorScheme.onPrimary;
      case ButtonType.outlined:
      case ButtonType.text:
        return color ?? colorScheme.primary;
    }
  }
}

enum ButtonType { filled, elevated, outlined, text }

// Material Design 3 Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool divider;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.divider = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        if (divider)
          Divider(
            color: colorScheme.outlineVariant,
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}

// Material Design 3 Search Bar Widget
class SearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool elevated;
  final EdgeInsets? margin;

  const SearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onClear,
    this.elevated = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: margin ?? EdgeInsets.all(AppSpacing.md),
      child: Material(
        elevation: elevated ? AppElevation.level2 : 0,
        borderRadius: BorderRadius.circular(AppBorderRadius.extraLarge),
        color: elevated
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerHigh,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              AppIcons.search,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            suffixIcon: controller?.text.isNotEmpty == true && onClear != null
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Material Design 3 Animated Counter Widget
class AnimatedCounter extends StatelessWidget {
  final int value;
  final String? label;
  final Duration duration;
  final Color? color;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.label,
    this.duration = const Duration(milliseconds: 1000),
    this.color,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  if (prefix != null)
                    TextSpan(
                      text: prefix,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: color ?? colorScheme.primary,
                      ),
                    ),
                  TextSpan(
                    text: animatedValue.toString(),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: color ?? colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      // fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  if (suffix != null)
                    TextSpan(
                      text: suffix,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: color ?? colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (label != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                label!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

// Material Design 3 Stat Card Widget
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? trend;
  final bool isPositiveTrend;
  final String? subtitle;
  final bool outlined;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    this.trend,
    this.isPositiveTrend = true,
    this.subtitle,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = color ?? colorScheme.primary;

    return ResponsiveCard(
      onTap: onTap,
      outlined: outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? AppTheme.successGreen : AppTheme.errorRed)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 12,
                        color: isPositiveTrend
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trend!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isPositiveTrend
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Value
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              // fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          
          SizedBox(height: AppSpacing.xs),
          
          // Title and subtitle
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}