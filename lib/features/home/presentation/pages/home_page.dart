import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/ad_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/pages/groups_list_page.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/presentation/widgets/create_group_dialog.dart';
import '../../../groups/domain/usecases/get_group_by_invite_code_usecase.dart';
import '../../../groups/domain/usecases/join_group_by_code_usecase.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isUnlocked = false;
  bool _isAuthenticating = true;
  String? _authError;
  bool _updatesChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticateUser());
  }

  Future<void> _authenticateUser() async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    final localAuthService = ref.read(localAuthServiceProvider);
    final success = await localAuthService.authenticate();

    if (!mounted) return;

    setState(() {
      _isUnlocked = success;
      _isAuthenticating = false;
      if (!success) {
        _authError =
            'No se pudo verificar tu identidad. Usa tu huella o patrón para continuar.';
      }
    });
  }

  void _checkForUpdatesIfNeeded() {
    if (_updatesChecked) return;
    _updatesChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateServiceProvider).checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        body: Center(
          child: _isAuthenticating
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verificando identidad...'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Protegido con huella o patrón',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (_authError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _authError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _authenticateUser,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
        ),
      );
    }

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

        _checkForUpdatesIfNeeded();

        final unreadCountAsync =
            ref.watch(unreadNotificationsCountProvider(user.id));
        final unreadCount = unreadCountAsync.maybeWhen(
          data: (count) => count,
          orElse: () => 0,
        );

        return DefaultTabController(
          initialIndex: widget.initialTabIndex,
          length: 3,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context)!;
              return AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  final isHomeTab = tabController.index == 0;
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('EquiGasto'),
                      actions: [
                        IconButton(
                          icon: _BadgeIcon(
                            icon: Icons.notifications,
                            count: unreadCount,
                          ),
                          onPressed: () => context.push(RouteNames.notifications),
                        ),
                        Builder(
                          builder: (context) {
                            final user = ref.watch(authStateProvider).value;
                            if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
                              return IconButton(
                                icon: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  backgroundImage: NetworkImage(user.avatarUrl!),
                                  onBackgroundImageError: (exception, stackTrace) {
                                    // Si falla la carga, se mostrará el color de fondo
                                  },
                                ),
                                onPressed: () => context.push(RouteNames.profile),
                              );
                            }
                            return IconButton(
                              icon: const Icon(Icons.person),
                              onPressed: () => context.push(RouteNames.profile),
                            );
                          },
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
                        Expanded(
                          child: TabBarView(
                            children: [
                              _HomeTab(),
                              GroupsListPage(),
                              SettingsPage(),
                            ],
                          ),
                        ),
                        if (!isHomeTab)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 0),
                            child: AdBanner(),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
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

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.count,
    this.size = 24,
  });

  final IconData icon;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(icon, size: size),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final groupsAsync = ref.watch(groupsListProvider);
    final showCreateGroupCta = groupsAsync.maybeWhen(
      data: (groups) => groups.isEmpty,
      orElse: () => false,
    );

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
            if (showCreateGroupCta)
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Comencemos!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primer grupo para empezar a compartir gastos.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateGroupDialog(context),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Crear grupo'),
                      ),
                    ],
                  ),
                ),
              ),
            if (showCreateGroupCta) const SizedBox(height: 16),
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
                leading:
                    const Icon(Icons.group_add, size: 40, color: Colors.blue),
                title: const Text('Unirse a un grupo'),
                subtitle: const Text('Ingresa el código del grupo para unirte'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showJoinGroupDialog(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            const AdBanner(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  static void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
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
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        final inviteCode = codeController.text.trim().toUpperCase();
                        
                        // Verificar autenticación
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

                        // Obtener el grupo usando el código de invitación
                        final getGroupUseCase = ref.read(getGroupByInviteCodeUseCaseProvider);
                        final groupResult = await getGroupUseCase(inviteCode).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () {
                            throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
                          },
                        );

                        if (!context.mounted) return;

                        groupResult.when(
                          success: (group) async {
                            // Verificar si el usuario ya es miembro
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

                            // Unirse al grupo usando el código
                            final joinUseCase = ref.read(joinGroupByCodeUseCaseProvider);
                            final joinResult = await joinUseCase(inviteCode, user.id).timeout(
                              const Duration(seconds: 10),
                              onTimeout: () {
                                throw Exception('Tiempo de espera agotado al unirse al grupo.');
                              },
                            );

                            setState(() => isLoading = false);

                            if (!context.mounted) return;

                            joinResult.when(
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
                                context.push('/groups/${group.id}');
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
