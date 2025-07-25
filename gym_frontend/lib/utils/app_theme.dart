import 'package:flutter/material.dart';

class AppTheme {
  // Material Design 3 Color Scheme - Modern Blue Theme
  static const Color _gymPrimary = Color(0xFF1976D2); // Gym Management Blue
  
  // Create Material 3 Color Schemes
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _gymPrimary,
    brightness: Brightness.light,
  );
  
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _gymPrimary,
    brightness: Brightness.dark,
  );
  
  // Semantic Colors for Gym App
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFED6C02);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF0288D1);
  
  // Add backward compatibility getters
  static Color get primaryBlueStatic => _gymPrimary;
  
  // Surface Colors (Material 3)
  static Color get primaryContainer => _lightColorScheme.primaryContainer;
  static Color get secondaryContainer => _lightColorScheme.secondaryContainer;
  static Color get tertiaryContainer => _lightColorScheme.tertiaryContainer;
  static Color get surfaceContainerLowest => _lightColorScheme.surfaceContainerLowest;
  static Color get surfaceContainer => _lightColorScheme.surfaceContainer;
  static Color get surfaceContainerHigh => _lightColorScheme.surfaceContainerHigh;
  
  // Text Colors (Material 3)
  static Color get onSurface => _lightColorScheme.onSurface;
  static Color get onSurfaceVariant => _lightColorScheme.onSurfaceVariant;
  static Color get outline => _lightColorScheme.outline;
  static Color get outlineVariant => _lightColorScheme.outlineVariant;
  
  // Theme-aware color getters (work with both light and dark themes)
  static Color primaryBlueContext(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color backgroundGrey(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color surfaceWhite(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color cardWhite(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textDisabled(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color borderLight(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  static Color shadowLight(BuildContext context) => Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08);
  
  // Backward compatibility colors (deprecated - use theme-aware versions above)
  static Color get primaryBlue => _lightColorScheme.primary;
  static Color get primaryBlueOld => _lightColorScheme.primary;
  static Color get backgroundGreyOld => _lightColorScheme.surface;
  static Color get surfaceWhiteOld => _lightColorScheme.surface;
  static Color get cardWhiteOld => _lightColorScheme.surfaceContainer;
  static Color get textPrimaryOld => _lightColorScheme.onSurface;
  static Color get textSecondaryOld => _lightColorScheme.onSurfaceVariant;
  static Color get textDisabledOld => _lightColorScheme.outline;
  static Color get borderLightOld => _lightColorScheme.outlineVariant;
  static Color get shadowLightOld => _lightColorScheme.shadow.withValues(alpha: 0.08);
  
  // Material 3 Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_lightColorScheme.primary, _lightColorScheme.primary.withValues(alpha: 0.8)],
  );
  
  static LinearGradient get successGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, successGreen.withValues(alpha: 0.8)],
  );

  // Material Design 3 Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    
    // App Bar Theme - Material 3 Style
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: _lightColorScheme.shadow,
      surfaceTintColor: _lightColorScheme.surfaceTint,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineSmall.copyWith(
        color: _lightColorScheme.onSurface,
      ),
    ),
    
    // Card Theme - Material 3 Container Styles
    cardTheme: CardThemeData(
      color: _lightColorScheme.surfaceContainer,
      elevation: 0,
      shadowColor: _lightColorScheme.shadow,
      surfaceTintColor: _lightColorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Material 3 larger radius
      ),
    ),
    
    // Button Themes - Material 3 Styled
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shadowColor: _lightColorScheme.shadow,
        surfaceTintColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Material 3 pill shape
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: _lightColorScheme.outline),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Material 3 FAB shape
      ),
    ),
    
    // Input Decoration Theme - Material 3
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightColorScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightColorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      elevation: 0,
      backgroundColor: _lightColorScheme.surface,
      indicatorColor: _lightColorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelMedium.copyWith(
            color: _lightColorScheme.onSecondaryContainer,
          );
        }
        return AppTextStyles.labelMedium.copyWith(
          color: _lightColorScheme.onSurfaceVariant,
        );
      }),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: _lightColorScheme.surfaceContainerHigh,
      selectedColor: _lightColorScheme.secondaryContainer,
      side: BorderSide(color: _lightColorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightColorScheme.inverseSurface,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: _lightColorScheme.onInverseSurface,
      ),
      actionTextColor: _lightColorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 3,
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: _lightColorScheme.surfaceContainerHigh,
      surfaceTintColor: _lightColorScheme.surfaceTint,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    
    // List Tile Theme
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    
    // App Bar Theme - Dark Mode
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: _darkColorScheme.shadow,
      surfaceTintColor: _darkColorScheme.surfaceTint,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineSmall.copyWith(
        color: _darkColorScheme.onSurface,
      ),
    ),
    
    // Card Theme - Dark Mode
    cardTheme: CardThemeData(
      color: _darkColorScheme.surfaceContainer,
      elevation: 0,
      shadowColor: _darkColorScheme.shadow,
      surfaceTintColor: _darkColorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Button Themes - Dark Mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shadowColor: _darkColorScheme.shadow,
        surfaceTintColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: _darkColorScheme.outline),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Input Decoration Theme - Dark Mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Navigation Bar Theme - Dark Mode
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      elevation: 0,
      backgroundColor: _darkColorScheme.surface,
      indicatorColor: _darkColorScheme.secondaryContainer,
    ),
    
    // SnackBar Theme - Dark Mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkColorScheme.inverseSurface,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: _darkColorScheme.onInverseSurface,
      ),
      actionTextColor: _darkColorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 3,
    ),
    
    // Dialog Theme - Dark Mode
    dialogTheme: DialogThemeData(
      backgroundColor: _darkColorScheme.surfaceContainerHigh,
      surfaceTintColor: _darkColorScheme.surfaceTint,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );

  // Status Color System with Material 3 containers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'working':
      case 'completed':
      case 'success':
      case 'available':
        return successGreen;
      case 'inactive':
      case 'maintenance':
      case 'pending':
      case 'warning':
      case 'busy':
        return warningOrange;
      case 'failed':
      case 'error':
      case 'expired':
        return errorRed;
      case 'info':
        return infoBlue;
      default:
        return _lightColorScheme.onSurfaceVariant;
    }
  }
  
  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'working':
      case 'completed':
      case 'success':
      case 'available':
        return successGreen.withValues(alpha: 0.12);
      case 'inactive':
      case 'maintenance':
      case 'pending':
      case 'warning':
      case 'busy':
        return warningOrange.withValues(alpha: 0.12);
      case 'failed':
      case 'error':
      case 'expired':
        return errorRed.withValues(alpha: 0.12);
      case 'info':
        return infoBlue.withValues(alpha: 0.12);
      default:
        return _lightColorScheme.surfaceContainerHigh;
    }
  }
  
  static Color getStatusBorderColor(String status) {
    return getStatusColor(status).withValues(alpha: 0.24);
  }
  
  static Color getStatusTextColor(String status) {
    return getStatusColor(status);
  }
}

// Material Design 3 Typography System
class AppTextStyles {
  // Display Styles (Large Headers)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline Styles (Section Headers)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title Styles (Card Headers, Dialog Titles)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Label Styles (Buttons, Chips)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
  
  // Body Styles (Content Text)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Backward compatibility methods
  static TextStyle heading1(BuildContext context) => displaySmall.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  static TextStyle heading2(BuildContext context) => headlineLarge.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  static TextStyle heading3(BuildContext context) => titleLarge.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  static TextStyle subtitle1(BuildContext context) => titleMedium.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  static TextStyle subtitle2(BuildContext context) => titleSmall.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  
  static TextStyle body1(BuildContext context) => bodyLarge.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  static TextStyle body2(BuildContext context) => bodyMedium.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  
  static TextStyle caption(BuildContext context) => bodySmall.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  
  static TextStyle button(BuildContext context) => labelLarge.copyWith(
    color: Theme.of(context).colorScheme.onPrimary,
  );
}

// Material Design 3 Spacing System
class AppSpacing {
  // Material 3 spacing scale (4dp base unit)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  
  // Container spacing
  static const double containerPadding = 24.0;
  static const double cardPadding = 16.0;
  static const double listItemPadding = 16.0;
}

// Material Design 3 Motion System
class AppDurations {
  // Standard easing durations
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);
  
  // Backward compatibility
  static const Duration short = short4;
  static const Duration medium = medium2;
  static const Duration long = long2;
}

// Material Design 3 Shape System
class AppBorderRadius {
  // Material 3 shape scale
  static const double none = 0.0;
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 28.0;
  static const double full = 9999.0; // Pill shape
  
  // Component specific
  static const double card = large;
  static const double button = extraLarge;
  static const double dialog = extraLarge;
  static const double fab = large;
  static const double chip = small;
}

// Material Design 3 Elevation System
class AppElevation {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;
}

// Material Design 3 Icon System
class AppIcons {
  // Navigation icons
  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home;
  static const IconData people = Icons.people_outline;
  static const IconData peopleSelected = Icons.people;
  static const IconData fitness = Icons.fitness_center_outlined;
  static const IconData fitnessSelected = Icons.fitness_center;
  static const IconData schedule = Icons.schedule_outlined;
  static const IconData scheduleSelected = Icons.schedule;
  static const IconData payments = Icons.payment_outlined;
  static const IconData paymentsSelected = Icons.payment;
  static const IconData qrCode = Icons.qr_code_scanner_outlined;
  static const IconData qrCodeSelected = Icons.qr_code_scanner;
  
  // Action icons
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData refresh = Icons.refresh;
  static const IconData more = Icons.more_vert;
  
  // Status icons
  static const IconData checkCircle = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData info = Icons.info;
}