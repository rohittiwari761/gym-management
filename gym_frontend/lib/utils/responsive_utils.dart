import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Platform detection
  static bool isWeb() => kIsWeb;
  
  // Proper responsive detection for enterprise web UI
  static bool shouldUseMobileLayout(BuildContext context) {
    if (!kIsWeb) {
      return MediaQuery.of(context).size.width < mobileBreakpoint;
    }
    // Web uses proper responsive breakpoints
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Web-specific layout detection
  static bool isWebDesktop(BuildContext context) {
    return kIsWeb && isDesktop(context);
  }

  static bool isWebTablet(BuildContext context) {
    return kIsWeb && isTablet(context);
  }

  static bool isWebMobile(BuildContext context) {
    return kIsWeb && isMobile(context);
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Web-specific content padding
  static EdgeInsets getWebContentPadding(BuildContext context) {
    if (isWebDesktop(context)) {
      return const EdgeInsets.all(32.0);
    } else if (isWebTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  // Get appropriate card margin based on screen size
  static EdgeInsets getCardMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    }
  }

  // Get number of columns for grid layouts
  static int getGridColumns(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else if (width < desktopBreakpoint) {
      return 3;
    } else if (width < 1600) {
      return 4;
    } else {
      return 5; // For very large screens
    }
  }

  // Get columns for different content types
  static int getMemberCardColumns(BuildContext context) {
    if (isWebDesktop(context)) {
      final width = getScreenWidth(context);
      if (width > 1600) return 4;
      if (width > 1200) return 3;
      return 2;
    }
    return getGridColumns(context);
  }

  static int getDashboardCardColumns(BuildContext context) {
    if (isWebDesktop(context)) {
      final width = getScreenWidth(context);
      if (width > 1400) return 4;
      if (width > 1000) return 3;
      return 2;
    } else if (isTablet(context)) {
      return 2;
    }
    return 1;
  }

  // Get appropriate font sizes for enterprise UI
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else if (isLargeDesktop(context)) {
      return 32.0;
    } else {
      return 28.0;
    }
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 18.0;
    } else if (isLargeDesktop(context)) {
      return 22.0;
    } else {
      return 20.0;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 15.0;
    } else {
      return 16.0;
    }
  }

  static double getCaptionFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 13.0;
    } else {
      return 14.0;
    }
  }

  // Web-specific font sizes
  static double getWebTableHeaderFontSize(BuildContext context) {
    return isWebDesktop(context) ? 14.0 : 13.0;
  }

  static double getWebTableBodyFontSize(BuildContext context) {
    return isWebDesktop(context) ? 13.0 : 12.0;
  }

  // Get appropriate icon sizes
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 26.0;
    } else {
      return 28.0;
    }
  }

  static double getSmallIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 18.0;
    } else {
      return 20.0;
    }
  }

  // Web-specific icon sizes
  static double getWebNavigationIconSize(BuildContext context) {
    return isWebDesktop(context) ? 20.0 : 18.0;
  }

  static double getWebActionIconSize(BuildContext context) {
    return isWebDesktop(context) ? 18.0 : 16.0;
  }

  // Get appropriate button padding
  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    }
  }

  // Web-specific button padding
  static EdgeInsets getWebActionButtonPadding(BuildContext context) {
    return isWebDesktop(context) 
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
        : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
  }

  // Get appropriate card elevation
  static double getCardElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2.0;
    } else if (isWebDesktop(context)) {
      return 1.0; // Subtle shadows for modern web design
    } else {
      return 3.0;
    }
  }

  // Get appropriate border radius
  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 10.0;
    } else {
      return 12.0; // More subtle for web
    }
  }

  // Web-specific border radius
  static double getWebCardBorderRadius(BuildContext context) {
    return isWebDesktop(context) ? 8.0 : 6.0;
  }

  static double getWebButtonBorderRadius(BuildContext context) {
    return isWebDesktop(context) ? 6.0 : 5.0;
  }

  // Get adaptive layout for cards
  static Widget adaptiveGridView({
    required BuildContext context,
    required List<Widget> children,
    double? childAspectRatio,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
  }) {
    final columns = getGridColumns(context);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? 1.0,
        mainAxisSpacing: mainAxisSpacing ?? 16.0,
        crossAxisSpacing: crossAxisSpacing ?? 16.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  // Get adaptive list view
  static Widget adaptiveListView({
    required BuildContext context,
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return ListView.separated(
      padding: padding ?? getScreenPadding(context),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(
        height: isMobile(context) ? 8.0 : 12.0,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }

  // Get maximum content width for better readability on large screens
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth > 1200) {
      return 1200;
    }
    return screenWidth;
  }

  // Center content on large screens
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

// Extension for easy access to responsive utilities
extension ResponsiveContext on BuildContext {
  // Platform detection
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  // Web-specific detection
  bool get isWebDesktop => ResponsiveUtils.isWebDesktop(this);
  bool get isWebTablet => ResponsiveUtils.isWebTablet(this);
  bool get isWebMobile => ResponsiveUtils.isWebMobile(this);
  
  // Screen dimensions
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);
  
  // Spacing and margins
  EdgeInsets get screenPadding => ResponsiveUtils.getScreenPadding(this);
  EdgeInsets get webContentPadding => ResponsiveUtils.getWebContentPadding(this);
  EdgeInsets get cardMargin => ResponsiveUtils.getCardMargin(this);
  EdgeInsets get buttonPadding => ResponsiveUtils.getButtonPadding(this);
  EdgeInsets get webActionButtonPadding => ResponsiveUtils.getWebActionButtonPadding(this);
  
  // Grid columns
  int get gridColumns => ResponsiveUtils.getGridColumns(this);
  int get memberCardColumns => ResponsiveUtils.getMemberCardColumns(this);
  int get dashboardCardColumns => ResponsiveUtils.getDashboardCardColumns(this);
  
  // Font sizes
  double get titleFontSize => ResponsiveUtils.getTitleFontSize(this);
  double get subtitleFontSize => ResponsiveUtils.getSubtitleFontSize(this);
  double get bodyFontSize => ResponsiveUtils.getBodyFontSize(this);
  double get captionFontSize => ResponsiveUtils.getCaptionFontSize(this);
  double get webTableHeaderFontSize => ResponsiveUtils.getWebTableHeaderFontSize(this);
  double get webTableBodyFontSize => ResponsiveUtils.getWebTableBodyFontSize(this);
  
  // Icon sizes
  double get iconSize => ResponsiveUtils.getIconSize(this);
  double get smallIconSize => ResponsiveUtils.getSmallIconSize(this);
  double get webNavigationIconSize => ResponsiveUtils.getWebNavigationIconSize(this);
  double get webActionIconSize => ResponsiveUtils.getWebActionIconSize(this);
  
  // Visual properties
  double get cardElevation => ResponsiveUtils.getCardElevation(this);
  double get borderRadius => ResponsiveUtils.getBorderRadius(this);
  double get webCardBorderRadius => ResponsiveUtils.getWebCardBorderRadius(this);
  double get webButtonBorderRadius => ResponsiveUtils.getWebButtonBorderRadius(this);
}