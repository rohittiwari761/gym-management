import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/responsive_utils.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;
  final Widget? tabletBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
    this.tabletBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isDesktop(context)) {
          return desktopBody;
        } else if (ResponsiveUtils.isTablet(context)) {
          return tabletBody ?? desktopBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}

class WebSidebarLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget body;
  final double sidebarWidth;

  const WebSidebarLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.sidebarWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: sidebar,
          ),
          // Main content
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}

class EnhancedCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableHover;

  const EnhancedCard({
    super.key,
    required this.child,
    this.color,
    this.elevation,
    this.margin,
    this.padding,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          child: MouseRegion(
            onEnter: (_) {
              if (widget.enableHover && kIsWeb) {
                setState(() => _isHovered = true);
                _animationController.forward();
              }
            },
            onExit: (_) {
              if (widget.enableHover && kIsWeb) {
                setState(() => _isHovered = false);
                _animationController.reverse();
              }
            },
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: _elevationAnimation.value,
                color: widget.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(20),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WebSidebar extends StatelessWidget {
  final Function(String) onItemSelected;
  final String currentRoute;

  const WebSidebar({
    super.key,
    required this.onItemSelected,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gym Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Professional Edition',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  'dashboard',
                  currentRoute == 'dashboard',
                ),
                _buildNavItem(
                  context,
                  'Members',
                  Icons.people,
                  'members',
                  currentRoute == 'members',
                ),
                _buildNavItem(
                  context,
                  'Trainers',
                  Icons.fitness_center,
                  'trainers',
                  currentRoute == 'trainers',
                ),
                _buildNavItem(
                  context,
                  'Equipment',
                  Icons.sports_gymnastics,
                  'equipment',
                  currentRoute == 'equipment',
                ),
                _buildNavItem(
                  context,
                  'Attendance',
                  Icons.checklist,
                  'attendance',
                  currentRoute == 'attendance',
                ),
                _buildNavItem(
                  context,
                  'Subscription Plans',
                  Icons.card_membership,
                  'subscription-plans',
                  currentRoute == 'subscription-plans',
                ),
                _buildNavItem(
                  context,
                  'Payments',
                  Icons.payment,
                  'payments',
                  currentRoute == 'payments',
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white30),
                const SizedBox(height: 20),
                _buildNavItem(
                  context,
                  'Settings',
                  Icons.settings,
                  'settings',
                  currentRoute == 'settings',
                ),
                _buildNavItem(
                  context,
                  'Profile',
                  Icons.person,
                  'profile',
                  currentRoute == 'profile',
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Divider(color: Colors.white30),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onItemSelected(route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}