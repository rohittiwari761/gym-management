import 'package:flutter/material.dart';

/// Responsive wrapper that prevents pixel overflow and provides safe layouts
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useSafeArea;
  final bool preventOverflow;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.useSafeArea = true,
    this.preventOverflow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;

    if (preventOverflow) {
      wrappedChild = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: wrappedChild,
      );
    }

    if (padding != null) {
      wrappedChild = Padding(
        padding: padding!,
        child: wrappedChild,
      );
    }

    if (useSafeArea) {
      wrappedChild = SafeArea(
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }
}

/// Responsive card that adapts to screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 8,
        vertical: 4,
      ),
      child: Card(
        elevation: elevation ?? (isTablet ? 6 : 4),
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(isTablet ? 20 : 16),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive button that adapts size based on screen
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSecondary;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final buttonStyle = isSecondary
        ? OutlinedButton.styleFrom(
            foregroundColor: textColor ?? Theme.of(context).primaryColor,
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).primaryColor,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
            foregroundColor: textColor ?? Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

    if (icon != null) {
      return isSecondary
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isTablet ? 20 : 18),
              label: Text(
                text,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: buttonStyle,
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isTablet ? 20 : 18),
              label: Text(
                text,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: buttonStyle,
            );
    }

    return isSecondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(
              text,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(
              text,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
          );
  }
}

/// Responsive text that adapts font size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final fontSize = style?.fontSize ?? 14;
    final responsiveFontSize = isTablet ? fontSize * 1.1 : fontSize;
    
    return Text(
      text,
      style: style?.copyWith(fontSize: responsiveFontSize) ??
          TextStyle(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive row that wraps on small screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool forceWrap;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.forceWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldWrap = forceWrap || screenWidth < 600;
    
    if (shouldWrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Utility class for responsive values
class ResponsiveUtils {
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= 600;
  }
  
  static double getResponsivePadding(BuildContext context) {
    return isTablet(context) ? 20 : 16;
  }
  
  static double getResponsiveMargin(BuildContext context) {
    return isTablet(context) ? 16 : 8;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    return isTablet(context) ? baseFontSize * 1.1 : baseFontSize;
  }
  
  static EdgeInsets getResponsiveInsets(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }
}