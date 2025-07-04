import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

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
    } else {
      return 4;
    }
  }

  // Get appropriate font sizes
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 18.0;
    } else {
      return 20.0;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  static double getCaptionFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 14.0;
    } else {
      return 16.0;
    }
  }

  // Get appropriate icon sizes
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 28.0;
    } else {
      return 32.0;
    }
  }

  static double getSmallIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
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

  // Get appropriate card elevation
  static double getCardElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2.0;
    } else {
      return 4.0;
    }
  }

  // Get appropriate border radius
  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
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
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);
  
  EdgeInsets get screenPadding => ResponsiveUtils.getScreenPadding(this);
  EdgeInsets get cardMargin => ResponsiveUtils.getCardMargin(this);
  EdgeInsets get buttonPadding => ResponsiveUtils.getButtonPadding(this);
  
  int get gridColumns => ResponsiveUtils.getGridColumns(this);
  
  double get titleFontSize => ResponsiveUtils.getTitleFontSize(this);
  double get subtitleFontSize => ResponsiveUtils.getSubtitleFontSize(this);
  double get bodyFontSize => ResponsiveUtils.getBodyFontSize(this);
  double get captionFontSize => ResponsiveUtils.getCaptionFontSize(this);
  
  double get iconSize => ResponsiveUtils.getIconSize(this);
  double get smallIconSize => ResponsiveUtils.getSmallIconSize(this);
  
  double get cardElevation => ResponsiveUtils.getCardElevation(this);
  double get borderRadius => ResponsiveUtils.getBorderRadius(this);
}