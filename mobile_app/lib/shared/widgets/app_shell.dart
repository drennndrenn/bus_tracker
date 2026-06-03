import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/project_entitlements.dart';
import '../../features/alerts/data/alerts_service.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/routes/presentation/pages/routes_page.dart';
import '../../features/subscription/presentation/pages/plans_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  final pages = const <Widget>[
    HomePage(),
    RoutesPage(),
    AboutPage(),
  ];

  static const titles = <String>[
    'Home',
    'Routes',
    'About',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.directions_bus_rounded, size: 30);
                },
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName),
                Text(
                  AppConstants.appSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Plans',
            icon: Badge(
              isLabelVisible: ProjectEntitlements.instance.isPro,
              smallSize: 8,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.workspace_premium_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PlansPage(),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: AlertsService.instance,
            builder: (context, _) {
              final unread = AlertsService.instance.unreadCount;
              return IconButton(
                tooltip: 'Alerts',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _showAlertsModal(context),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: titles[0]),
          NavigationDestination(icon: Icon(Icons.alt_route), label: titles[1]),
          NavigationDestination(icon: Icon(Icons.info_outline), label: titles[2]),
        ],
      ),
    );
  }

  void _showAlertsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.65;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                child: ListenableBuilder(
                  listenable: AlertsService.instance,
                  builder: (context, _) {
                    final unread = AlertsService.instance.unreadCount;
                    return Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                        Text(
                          'Alerts',
                          style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        if (unread > 0)
                          TextButton(
                            onPressed: () => AlertsService.instance.markAllRead(),
                            child: const Text('Mark all read'),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              const Expanded(
                child: AlertsPage(),
              ),
            ],
          ),
        );
      },
    );
  }
}
