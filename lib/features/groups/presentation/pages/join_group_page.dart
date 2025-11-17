import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/datasources/user_remote_datasource.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/group.dart';
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
  bool _hasShownError = false;
  Future<Group>? _groupFuture;
  
  String get _normalizedCode => widget.code.trim().toUpperCase();
  
  @override
  void initState() {
    super.initState();
    // Cargar el grupo una sola vez al inicializar
    _groupFuture = ref.read(groupByInviteCodeProvider(_normalizedCode).future);
  }

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

    // Obtener el grupo antes de unirse para tener el groupId
    Group? group;
    try {
      group = await _groupFuture;
    } catch (e) {
      print('❌ Error al obtener grupo: $e');
      debugPrint('❌ Error al obtener grupo: $e');
    }

    final joinUseCase = ref.read(joinGroupByCodeUseCaseProvider);
    final result = await joinUseCase(_normalizedCode, user.id);

    if (!mounted) return;
    setState(() => _isJoining = false);

    result.when(
      success: (_) {
        // Invalidar providers para refrescar los datos
        ref.invalidate(groupsListProvider);
        if (group != null) {
          ref.invalidate(groupProvider(group.id));
          ref.invalidate(groupMembersProvider(group.memberIds));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al grupo exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar directamente al detalle del grupo si tenemos el groupId
        if (group != null) {
          context.go('/groups/${group.id}');
        } else {
          // Si no tenemos el grupo, navegar a la lista de grupos
          context.go(RouteNames.groups);
        }
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
    print('🔍 JoinGroupPage - Código recibido: ${widget.code} (longitud: ${widget.code.length})');
    debugPrint('🔍 JoinGroupPage - Código recibido: ${widget.code} (longitud: ${widget.code.length})');
    
    // Validar que el código no sea demasiado largo (los códigos de invitación son de 8 caracteres)
    // Si es muy largo, probablemente es un groupId, no un código de invitación
    if (_normalizedCode.length > 20 || _normalizedCode.length < 4) {
      print('❌ JoinGroupPage - Código inválido (longitud: ${_normalizedCode.length}), probablemente es un groupId o código malformado');
      debugPrint('❌ JoinGroupPage - Código inválido (longitud: ${_normalizedCode.length}), probablemente es un groupId o código malformado');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invitación a grupo'),
        ),
        body: Center(
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
                  'El código proporcionado no es válido. Asegúrate de usar el código de invitación correcto.',
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
      );
    }
    
    debugPrint('🔍 JoinGroupPage - Código normalizado: $_normalizedCode');
    
    // Usar FutureBuilder con el future cargado en initState para evitar recargas infinitas
    if (_groupFuture == null) {
      _groupFuture = ref.read(groupByInviteCodeProvider(_normalizedCode).future);
    }

    return Scaffold(
      key: ValueKey('join_group_${_normalizedCode}'),
      appBar: AppBar(
        title: const Text('Invitación a grupo'),
      ),
      body: FutureBuilder<Group>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Buscando grupo con código: $_normalizedCode', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => context.go(RouteNames.groups), child: const Text('Volver')),
                  ],
                ),
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Grupo no encontrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => context.go(RouteNames.groups), child: const Text('Volver')),
                  ],
                ),
              ),
            );
          }
          
          final group = snapshot.data!;
          
          return _buildGroupContent(group);
        },
      ),
    );
  }
  
  Widget _buildGroupContent(Group group) {
    print('✅ JoinGroupPage - Grupo encontrado: ${group.id} - ${group.name}');
    debugPrint('✅ JoinGroupPage - Grupo encontrado: ${group.id} - ${group.name}');
    
    // Obtener información del creador de forma opcional usando FutureBuilder
    // para evitar que el provider cause recargas infinitas
    return FutureBuilder<List<User>>(
            future: ref.read(groupMembersProvider([group.createdBy]).future).catchError((e) {
              print('❌ JoinGroupPage - Error al obtener creador: $e');
              debugPrint('❌ JoinGroupPage - Error al obtener creador: $e');
              return <User>[];
            }),
            builder: (context, snapshot) {
              final creator = snapshot.hasData && snapshot.data!.isNotEmpty 
                  ? snapshot.data!.first 
                  : null;
              
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
                                    _normalizedCode,
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
          );
  }
}

