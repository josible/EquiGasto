import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/pages/groups_list_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RouteNames.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('EquiGasto'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => context.push(RouteNames.notifications),
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => context.push(RouteNames.profile),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.home), text: 'Inicio'),
                  Tab(icon: Icon(Icons.group), text: 'Grupos'),
                  Tab(icon: Icon(Icons.settings), text: 'Configuración'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _HomeTab(),
                GroupsListPage(),
                SettingsPage(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('No hay usuario autenticado'));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.group, size: 40),
                title: const Text('Ver Grupos'),
                subtitle: const Text('Gestiona tus grupos de gastos'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications, size: 40),
                title: const Text('Notificaciones'),
                subtitle: const Text('Revisa tus notificaciones'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push(RouteNames.notifications),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

