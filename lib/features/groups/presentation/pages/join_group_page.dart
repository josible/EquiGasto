import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/datasources/user_remote_datasource.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/groups_provider.dart';
import '../providers/group_members_provider.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/providers.dart';

class JoinGroupPage extends ConsumerStatefulWidget {
  final String code;

  const JoinGroupPage({
    super.key,
    required this.code,
  });

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
  bool _isJoining = false;

  Future<void> _handleJoin() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para unirte a un grupo'),
            backgroundColor: Colors.red,
          ),
        );
        context.go(RouteNames.login);
      }
      return;
    }

    setState(() => _isJoining = true);

    final joinUseCase = ref.read(joinGroupByCodeUseCaseProvider);
    final result = await joinUseCase(widget.code, user.id);

    if (!mounted) return;
    setState(() => _isJoining = false);

    result.when(
      success: (_) {
        // Invalidar providers
        ref.invalidate(groupsListProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al grupo exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar a la lista de grupos
        context.go(RouteNames.groups);
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 JoinGroupPage - Código recibido: ${widget.code}');
    final groupAsync = ref.watch(groupByInviteCodeProvider(widget.code));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitación a grupo'),
      ),
      body: groupAsync.when(
        data: (group) {
          // Obtener información del creador
          final creatorAsync = ref.watch(groupMembersProvider([group.createdBy]));
          
          return creatorAsync.when(
            data: (members) {
              final creator = members.isNotEmpty ? members.first : null;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_add,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Invitación a unirse a',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        group.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Creado por',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    creator?.name ?? 'Usuario',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código de invitación',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.code,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _handleJoin,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isJoining ? 'Uniéndose...' : 'Aceptar invitación'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(RouteNames.groups),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error al cargar información del creador')),
          );
        },
        loading: () {
          debugPrint('⏳ JoinGroupPage - Cargando grupo con código: ${widget.code}');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          debugPrint('❌ JoinGroupPage - Error al cargar grupo: $error');
          debugPrint('❌ Stack trace: $stack');
          return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Código de invitación inválido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El código que intentas usar no existe o ha expirado.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(RouteNames.groups),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ,),
    );
  }
}

