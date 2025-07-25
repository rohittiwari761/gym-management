import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';

class WebLayoutWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;
  final List<Widget>? actions;
  final bool showDrawer;

  const WebLayoutWrapper({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
    this.actions,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    // For mobile platforms, return child as-is
    if (!kIsWeb) {
      return child;
    }

    // For web mobile view, use standard mobile layout
    if (context.isWebMobile) {
      return child;
    }

    // For web desktop/tablet, use enterprise layout
    return WebDesktopLayout(
      currentRoute: currentRoute,
      pageTitle: pageTitle,
      actions: actions,
      showDrawer: showDrawer,
      child: child,
    );
  }
}

class WebDesktopLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;
  final List<Widget>? actions;
  final bool showDrawer;

  const WebDesktopLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
    this.actions,
    this.showDrawer = true,
  });

  @override
  State<WebDesktopLayout> createState() => _WebDesktopLayoutState();
}

class _WebDesktopLayoutState extends State<WebDesktopLayout> {
  bool _isDrawerExpanded = true;
  static const double _expandedDrawerWidth = 280.0;
  static const double _collapsedDrawerWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (widget.showDrawer) _buildNavigationSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context),
                Expanded(
                  child: Container(
                    padding: context.webContentPadding,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSidebar(BuildContext context) {
    final drawerWidth = _isDrawerExpanded ? _expandedDrawerWidth : _collapsedDrawerWidth;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: drawerWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(context),
          Expanded(child: _buildNavigationItems(context)),
          _buildSidebarFooter(context),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (_isDrawerExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gym Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Enterprise System',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            onPressed: () {
              setState(() {
                _isDrawerExpanded = !_isDrawerExpanded;
              });
            },
            icon: Icon(
              _isDrawerExpanded ? Icons.menu_open : Icons.menu,
              color: Colors.grey.shade600,
              size: context.webNavigationIconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    final navigationItems = [
      NavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      NavigationItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Members',
        route: '/members',
      ),
      NavigationItem(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: 'Equipment',
        route: '/equipment',
      ),
      NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Trainers',
        route: '/trainers',
      ),
      NavigationItem(
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership,
        label: 'Subscriptions',
        route: '/subscriptions',
      ),
      NavigationItem(
        icon: Icons.payment_outlined,
        activeIcon: Icons.payment,
        label: 'Payments',
        route: '/payments',
      ),
      NavigationItem(
        icon: Icons.event_available_outlined,
        activeIcon: Icons.event_available,
        label: 'Attendance',
        route: '/attendance',
      ),
      NavigationItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        label: 'Analytics',
        route: '/analytics',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_isDrawerExpanded) 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'MAIN NAVIGATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ...navigationItems.map((item) => _buildNavigationItem(context, item)),
        const SizedBox(height: 24),
        if (_isDrawerExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        _buildNavigationItem(
          context,
          NavigationItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            route: '/settings',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem(BuildContext context, NavigationItem item) {
    final isActive = widget.currentRoute.startsWith(item.route);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pushNamed(context, item.route);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDrawerExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive 
                  ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.2))
                  : null,
            ),
            child: Row(
              children: [
                if (!_isDrawerExpanded) const Spacer(),
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? AppTheme.primaryBlue : Colors.grey.shade600,
                  size: context.webNavigationIconSize,
                ),
                if (_isDrawerExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppTheme.primaryBlue : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
                if (!_isDrawerExpanded) const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!_isDrawerExpanded) {
            return Center(
              child: IconButton(
                onPressed: () => _showUserMenu(context),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    authProvider.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  authProvider.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.user?.email ?? 'User',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showUserMenu(context),
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.pageTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    // Implementation for user menu dropdown
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ),
      ],
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}