import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/pages/groups_list_page.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/widgets/ad_banner.dart';

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
            body: Column(
              children: [
                const Expanded(
                  child: TabBarView(
                    children: [
                      _HomeTab(),
                      GroupsListPage(),
                      SettingsPage(),
                    ],
                  ),
                ),
                // Banner publicitario en la parte inferior
                const AdBanner(),
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
                leading: const Icon(Icons.group_add, size: 40, color: Colors.blue),
                title: const Text('Unirse a un grupo'),
                subtitle: const Text('Ingresa el código del grupo para unirte'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showJoinGroupDialog(context, ref),
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

  static void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Unirse a un grupo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pide el código del grupo a tus amigos',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código del grupo',
                    hintText: 'Ingresa el código',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el código del grupo';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        final groupId = codeController.text.trim();
                        final groupsRepository = ref.read(groupsRepositoryProvider);
                        final result = await groupsRepository.getGroupById(groupId);

                        if (!context.mounted) return;

                        result.when(
                          success: (group) async {
                            // Verificar si el usuario ya es miembro
                            final authState = ref.read(authStateProvider);
                            final user = authState.value;
                            
                            if (user == null) {
                              setState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Debes estar autenticado'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            if (group.memberIds.contains(user.id)) {
                              setState(() => isLoading = false);
                              Navigator.of(context).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ya eres miembro de este grupo'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            // Unirse al grupo
                            final inviteResult = await groupsRepository.inviteUserToGroup(
                              groupId,
                              user.email,
                            );

                            setState(() => isLoading = false);

                            if (!context.mounted) return;

                            inviteResult.when(
                              success: (_) {
                                Navigator.of(context).pop();
                                ref.invalidate(groupsListProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Te has unido al grupo "${group.name}"'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Navegar al grupo
                                context.push('/groups/$groupId');
                              },
                              error: (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${failure.message}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            );
                          },
                          error: (failure) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${failure.message}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        );
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error inesperado: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unirse'),
            ),
          ],
        ),
      ),
    );
  }
}

