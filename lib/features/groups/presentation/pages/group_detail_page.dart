import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../expenses/domain/entities/debt.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../providers/groups_provider.dart';
import '../providers/group_members_provider.dart';
import '../providers/group_balance_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  bool _isDeletingGroup = false;
  bool _isLeavingGroup = false;
  static const double _balanceTolerance = 0.01;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      body: groupAsync.when(
        data: (group) {
          final canDeleteGroup = currentUser?.id == group.createdBy;
          final canLeaveGroup = currentUser != null &&
              group.memberIds.contains(currentUser.id) &&
              currentUser.id != group.createdBy;
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Compartir grupo',
                      onPressed: () =>
                          _showShareDialog(context, group, currentUser),
                    ),
                    if (canDeleteGroup)
                      IconButton(
                        icon: _isDeletingGroup
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar grupo',
                        onPressed: _isDeletingGroup
                            ? null
                            : () => _confirmDeleteGroup(context, group),
                      ),
                    if (canLeaveGroup)
                      IconButton(
                        icon: _isLeavingGroup
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.logout),
                        tooltip: 'Salir del grupo',
                        onPressed: _isLeavingGroup || currentUser == null
                            ? null
                            : () => _handleLeaveGroupTap(
                                  context,
                                  group,
                                  currentUser,
                                ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(group.name),
                    background: Container(
                      color: Colors.blue,
                      child: const Center(
                        child: Icon(
                          Icons.group,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Gastos'),
                    Tab(text: 'Miembros'),
                    Tab(text: 'Cuentas'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ExpensesTab(groupId: widget.groupId),
                      _MembersTab(group: group, groupId: widget.groupId),
                      _AccountsTab(groupId: widget.groupId),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Detalle del Grupo')),
          body: Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: groupAsync.when(
        data: (group) {
          // Mostrar FAB solo en la pestaña de gastos
          if (_currentTabIndex == 0) {
            return FloatingActionButton(
              onPressed: () =>
                  context.push('/groups/${widget.groupId}/expenses/add'),
              child: const Icon(Icons.add),
            );
          }
          // En la pestaña de miembros, no mostrar FAB (ya hay botón en la pestaña)
          return const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _handleLeaveGroupTap(
    BuildContext context,
    group,
    User currentUser,
  ) async {
    ref.invalidate(groupBalanceProvider(group.id));
    final balance = await ref.read(groupBalanceProvider(group.id).future);

    if (!mounted) return;

    if (balance < -_balanceTolerance) {
      final amount = balance.abs().toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes salir: aún debes €$amount en este grupo. Liquida tus deudas primero.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await _confirmLeaveGroup(context, group, currentUser);
  }

  Future<void> _confirmDeleteGroup(BuildContext context, group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text(
          'Esta acción eliminará el grupo y todos sus datos. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingGroup = true);

    final deleteUseCase = ref.read(deleteGroupUseCaseProvider);
    final result = await deleteUseCase(group.id);

    if (!mounted) return;

    setState(() => _isDeletingGroup = false);

    result.when(
      success: (_) {
        ref.invalidate(groupsListProvider);
        ref.invalidate(groupProvider(group.id));
        ref.invalidate(groupExpensesProvider(group.id));
        ref.invalidate(groupDebtsProvider(group.id));
        ref.invalidate(groupBalanceProvider(group.id));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.home);
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

  Future<void> _confirmLeaveGroup(
    BuildContext context,
    group,
    User currentUser,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text(
          'Ya no recibirás actualizaciones de este grupo. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLeavingGroup = true);

    final removeUseCase = ref.read(removeUserFromGroupUseCaseProvider);
    final result = await removeUseCase(group.id, currentUser.id);

    if (!mounted) return;

    setState(() => _isLeavingGroup = false);

    await result.when(
      success: (_) async {
        unawaited(_notifyMembersUserLeft(group, currentUser));
        _refreshGroupRelatedData(group);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has salido del grupo'),
            backgroundColor: Colors.blue,
          ),
        );

        _navigateToGroupsList();
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

  void _refreshGroupRelatedData(group) {
    ref.invalidate(groupsListProvider);
    ref.invalidate(groupProvider(group.id));
    ref.invalidate(groupMembersProvider(group.memberIds));
    ref.invalidate(groupExpensesProvider(group.id));
    ref.invalidate(groupDebtsProvider(group.id));
    ref.invalidate(groupBalanceProvider(group.id));
  }

  void _navigateToGroupsList() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      const groupsTabIndex = 1;
      context.go(RouteNames.home, extra: groupsTabIndex);
    });
  }

  Future<void> _notifyMembersUserLeft(group, User user) async {
    final createNotificationUseCase =
        ref.read(createNotificationUseCaseProvider);
    for (final memberId in group.memberIds) {
      if (memberId == user.id) continue;
      final notification = AppNotification(
        id: const Uuid().v4(),
        userId: memberId,
        type: NotificationType.memberLeft,
        title: 'Un miembro salió del grupo',
        message: '${user.name} ha salido de ${group.name}',
        data: {
          'groupId': group.id,
          'userId': user.id,
        },
        isRead: false,
        createdAt: DateTime.now(),
      );
      final result = await createNotificationUseCase(notification);
      result.when(success: (_) {}, error: (_) {});
    }
  }

  void _showShareDialog(
    BuildContext context,
    group,
    User? inviter,
  ) {
    // Mostrar diálogo directamente con el ID del grupo como código
    showDialog(
      context: context,
      builder: (dialogContext) => _ShareGroupDialog(
        groupName: group.name,
        code: widget.groupId,
        inviterName: inviter?.name ?? 'Un miembro de EquiGasto',
      ),
    );
  }
}

class _ShareGroupDialog extends StatelessWidget {
  final String groupName;
  final String code;
  final String inviterName;

  static const String _storeUrl =
      'https://play.google.com/store/apps/details?id=com.sire.equigasto';

  const _ShareGroupDialog({
    required this.groupName,
    required this.code,
    required this.inviterName,
  });

  String get _shareMessage => '''
¡Hola! $inviterName te ha invitado al grupo "$groupName" en EquiGasto.

Si ya tienes la app instalada, abre EquiGasto y pega este código:
$code

¿Aún no tienes EquiGasto? Instálala aquí y usa el mismo código para unirte:
$_storeUrl
'''
      .trim();

  Future<void> _shareToWhatsApp(BuildContext context) async {
    print('[COMPARTIR] Iniciando compartir a WhatsApp');
    final message = Uri.encodeComponent(_shareMessage);
    print(
        '[COMPARTIR] Mensaje codificado: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

    try {
      // Intentar primero con el esquema nativo de WhatsApp
      final nativeUrl = Uri.parse('whatsapp://send?text=$message');
      print('[COMPARTIR] Intentando abrir URL nativa: $nativeUrl');
      try {
        final canLaunch = await canLaunchUrl(nativeUrl);
        print('[COMPARTIR] canLaunchUrl(nativeUrl) = $canLaunch');
        if (canLaunch) {
          print('[COMPARTIR] Lanzando URL nativa...');
          await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
          print('[COMPARTIR] URL nativa lanzada exitosamente');
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          return;
        } else {
          print('[COMPARTIR] No se puede lanzar URL nativa, intentando web...');
        }
      } catch (e) {
        print('[COMPARTIR] Error al intentar URL nativa: $e');
        // Si falla, intentar con la URL web
      }

      // Si el esquema nativo no funciona, intentar con la URL web
      final webUrl = Uri.parse('https://wa.me/?text=$message');
      print('[COMPARTIR] Intentando abrir URL web: $webUrl');
      final canLaunchWeb = await canLaunchUrl(webUrl);
      print('[COMPARTIR] canLaunchUrl(webUrl) = $canLaunchWeb');
      if (canLaunchWeb) {
        print('[COMPARTIR] Lanzando URL web...');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('[COMPARTIR] URL web lanzada exitosamente');
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        print('[COMPARTIR] No se puede lanzar URL web');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se pudo abrir WhatsApp. Intenta compartir con otra aplicación.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[COMPARTIR] Error general al abrir WhatsApp: $e');
      print('[COMPARTIR] Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareToTelegram(BuildContext context) async {
    print('[COMPARTIR] Iniciando compartir a Telegram');
    final message = Uri.encodeComponent(_shareMessage);
    print(
        '[COMPARTIR] Mensaje codificado: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

    try {
      // Intentar primero con el esquema nativo de Telegram
      final nativeUrl = Uri.parse('tg://msg?text=$message');
      print('[COMPARTIR] Intentando abrir URL nativa: $nativeUrl');
      try {
        final canLaunch = await canLaunchUrl(nativeUrl);
        print('[COMPARTIR] canLaunchUrl(nativeUrl) = $canLaunch');
        if (canLaunch) {
          print('[COMPARTIR] Lanzando URL nativa...');
          await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
          print('[COMPARTIR] URL nativa lanzada exitosamente');
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          return;
        } else {
          print('[COMPARTIR] No se puede lanzar URL nativa, intentando web...');
        }
      } catch (e) {
        print('[COMPARTIR] Error al intentar URL nativa: $e');
        // Si falla, intentar con la URL web
      }

      // Si el esquema nativo no funciona, intentar con la URL web
      final webUrl =
          Uri.parse('https://t.me/share/url?text=${Uri.encodeComponent(code)}');
      print('[COMPARTIR] Intentando abrir URL web: $webUrl');
      final canLaunchWeb = await canLaunchUrl(webUrl);
      print('[COMPARTIR] canLaunchUrl(webUrl) = $canLaunchWeb');
      if (canLaunchWeb) {
        print('[COMPARTIR] Lanzando URL web...');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('[COMPARTIR] URL web lanzada exitosamente');
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        print('[COMPARTIR] No se puede lanzar URL web');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se pudo abrir Telegram. Intenta compartir con otra aplicación.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[COMPARTIR] Error general al abrir Telegram: $e');
      print('[COMPARTIR] Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Telegram: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareGeneric(BuildContext context) async {
    print('[COMPARTIR] Iniciando compartir genérico');
    print(
        '[COMPARTIR] Mensaje: ${_shareMessage.substring(0, _shareMessage.length > 100 ? 100 : _shareMessage.length)}...');
    try {
      print('[COMPARTIR] Llamando a Share.share...');
      await Share.share(_shareMessage);
      print('[COMPARTIR] Share.share completado');
      if (context.mounted) {
        Navigator.of(context).pop();
        print('[COMPARTIR] Diálogo cerrado');
      }
    } catch (e, stackTrace) {
      print('[COMPARTIR] Error al compartir: $e');
      print('[COMPARTIR] Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return AlertDialog(
      title: const Text('Compartir grupo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Código de invitación:'),
            const SizedBox(height: 8),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            if (isMobile) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Compartir en:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              // WhatsApp
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 24),
                ),
                title: const Text('WhatsApp'),
                onTap: () {
                  print('[COMPARTIR] Botón WhatsApp presionado');
                  _shareToWhatsApp(context);
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              // Telegram
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
                title: const Text('Telegram'),
                onTap: () {
                  print('[COMPARTIR] Botón Telegram presionado');
                  _shareToTelegram(context);
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              // Compartir genérico
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Otras aplicaciones'),
                onTap: () {
                  print('[COMPARTIR] Botón Otras aplicaciones presionado');
                  _shareGeneric(context);
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado al portapapeles')),
              );
            }
          },
          child: const Text('Copiar código'),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () => _shareGeneric(context),
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String groupId;

  const _ExpensesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final groupAsync = ref.watch(groupProvider(groupId));

    return groupAsync.when(
      data: (group) {
        final membersAsync = ref.watch(groupMembersProvider(group.memberIds));

        return membersAsync.when(
          data: (members) {
            final membersMap = <String, User>{};
            for (final member in members) {
              membersMap[member.id] = member;
            }
            final currentUser = ref.watch(authStateProvider).value;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(groupExpensesProvider(groupId));
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text('No hay gastos aún'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final paidByUser = membersMap[expense.paidBy];
                      final paidByName = paidByUser?.name ??
                          'Usuario ${expense.paidBy.substring(0, 8)}';
                      final canManageExpense =
                          currentUser?.id == expense.paidBy;

                      return Card(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.receipt),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      expense.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '€${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pagado por: $paidByName',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (canManageExpense)
                                    PopupMenuButton<String>(
                                      icon:
                                          const Icon(Icons.more_vert, size: 20),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _navigateToEditExpense(
                                              context, expense);
                                        } else if (value == 'delete') {
                                          _confirmDeleteExpense(
                                            context,
                                            ref,
                                            expense,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Editar'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            title: Text('Eliminar'),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(groupExpensesProvider(groupId));
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(
                  child: Text('No hay gastos aún'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt),
                      title: Text(expense.description),
                      subtitle: Text(
                          '€${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}'),
                      trailing: Text(
                        '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _navigateToEditExpense(BuildContext context, Expense expense) {
    context.push(
      '/groups/${expense.groupId}/expenses/${expense.id}/edit',
      extra: expense,
    );
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content:
            const Text('Esta acción no se puede deshacer. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleteUseCase = ref.read(deleteExpenseUseCaseProvider);
    final result = await deleteUseCase(expense.id);

    result.when(
      success: (_) {
        ref.invalidate(groupExpensesProvider(groupId));
        ref.invalidate(groupDebtsProvider(groupId));
        ref.invalidate(groupBalanceProvider(groupId));
        ref.invalidate(groupsListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
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
}

class _MembersTab extends ConsumerWidget {
  final group;
  final String groupId;

  const _MembersTab({required this.group, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.memberIds));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showInviteDialog(context, ref, groupId),
            icon: const Icon(Icons.person_add),
            label: const Text('Invitar miembro'),
          ),
        ),
        Expanded(
          child: membersAsync.when(
            data: (members) {
              // Crear un mapa de userId -> User para búsqueda rápida
              final membersMap = <String, User>{};
              for (final member in members) {
                membersMap[member.id] = member;
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: group.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = group.memberIds[index];
                  final member = membersMap[memberId];
                  final displayName =
                      member != null ? member.name : 'Miembro ${index + 1}';
                  final initial = member != null
                      ? member.name[0].toUpperCase()
                      : memberId.substring(0, 1).toUpperCase();

                  // Calcular balance del miembro
                  final expensesAsync =
                      ref.watch(groupExpensesProvider(groupId));
                  return expensesAsync.when(
                    data: (expenses) {
                      double memberBalance = 0.0;
                      for (final expense in expenses) {
                        if (expense.paidBy == memberId) {
                          memberBalance += expense.amount;
                        }
                        if (expense.splitAmounts.containsKey(memberId)) {
                          memberBalance -= expense.splitAmounts[memberId]!;
                        }
                      }

                      final isPositive = memberBalance > 0.01;
                      final isNegative = memberBalance < -0.01;
                      final balanceColor = isPositive
                          ? Colors.green
                          : isNegative
                              ? Colors.red
                              : Colors.grey;

                      return Card(
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                child: Text(initial),
                              ),
                              if (group.createdBy == memberId)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(displayName),
                          subtitle: member != null
                              ? Text(member.email)
                              : Text(memberId),
                          trailing: Text(
                            isPositive
                                ? '+€${memberBalance.toStringAsFixed(2).replaceAll('.', ',')}'
                                : isNegative
                                    ? '-€${(-memberBalance).toStringAsFixed(2).replaceAll('.', ',')}'
                                    : '€0,00',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: balanceColor,
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => Card(
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              child: Text(initial),
                            ),
                            if (group.createdBy == memberId)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(displayName),
                        subtitle: member != null
                            ? Text(member.email)
                            : Text(memberId),
                      ),
                    ),
                    error: (_, __) => Card(
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              child: Text(initial),
                            ),
                            if (group.createdBy == memberId)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(displayName),
                        subtitle: member != null
                            ? Text(member.email)
                            : Text(memberId),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: group.memberIds.length,
              itemBuilder: (context, index) {
                final memberId = group.memberIds[index];
                return Card(
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          child: Text(memberId.substring(0, 1).toUpperCase()),
                        ),
                        if (group.createdBy == memberId)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text('Miembro ${index + 1}'),
                    subtitle: Text(memberId),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => _InviteMemberDialog(
        groupId: groupId,
      ),
    );
  }
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final String groupId;

  const _InviteMemberDialog({
    required this.groupId,
  });

  @override
  ConsumerState<_InviteMemberDialog> createState() =>
      _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  bool _isLoading = false;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inviteUseCase = ref.read(inviteUserToGroupUseCaseProvider);
      final result = await inviteUseCase(
        widget.groupId,
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      result.when(
        success: (_) {
          ref.invalidate(groupProvider(widget.groupId));
          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario invitado exitosamente'),
              ),
            );
          }
        },
        error: (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar miembro'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email del usuario',
            hintText: 'usuario@example.com',
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese un email';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un email válido';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleInvite,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invitar'),
        ),
      ],
    );
  }
}

class _AccountsTab extends ConsumerStatefulWidget {
  final String groupId;

  const _AccountsTab({required this.groupId});

  @override
  ConsumerState<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends ConsumerState<_AccountsTab> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final debtsAsync = ref.watch(groupDebtsProvider(widget.groupId));
    final groupAsync = ref.watch(groupProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        final membersAsync = ref.watch(groupMembersProvider(group.memberIds));

        return membersAsync.when(
          data: (members) {
            final membersMap = <String, User>{};
            for (final member in members) {
              membersMap[member.id] = member;
            }

            return debtsAsync.when(
              data: (debts) {
                if (debts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay deudas pendientes.\nTodos están al día.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    final fromUser = membersMap[debt.fromUserId];
                    final toUser = membersMap[debt.toUserId];

                    final fromName = fromUser?.name ??
                        'Usuario ${debt.fromUserId.substring(0, 8)}';
                    final toName = toUser?.name ??
                        'Usuario ${debt.toUserId.substring(0, 8)}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                        title: Text('$fromName debe a $toName'),
                        subtitle: Text(
                          '€${debt.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () => _showSettleDebtDialog(
                            context,
                            ref,
                            debt,
                            fromName,
                            toName,
                            widget.groupId,
                          ),
                          tooltip: 'Liquidar deuda',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error al cargar deudas: $error'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return const Center(
                  child: Text('No hay deudas pendientes'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: debts.length,
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                      title: Text(
                          'Usuario ${debt.fromUserId.substring(0, 8)} debe a Usuario ${debt.toUserId.substring(0, 8)}'),
                      subtitle: Text(
                        '€${debt.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error al cargar deudas: $error'),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _showSettleDebtDialog(
    BuildContext context,
    WidgetRef ref,
    Debt debt,
    String fromName,
    String toName,
    String groupId,
  ) async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.value;

    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes estar autenticado para liquidar deudas'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Solo el deudor puede liquidar su deuda
    if (currentUser.id != debt.fromUserId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo el deudor puede liquidar esta deuda'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liquidar deuda'),
        content: Text(
          '¿Confirmas que has pagado €${debt.amount.toStringAsFixed(2).replaceAll('.', ',')} a $toName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Liquidando deuda...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final settleUseCase = ref.read(settleDebtUseCaseProvider);
    final result = await settleUseCase(
      fromUserId: debt.fromUserId,
      toUserId: debt.toUserId,
      groupId: debt.groupId,
      amount: debt.amount,
    );

    if (!context.mounted) return;

    result.when(
      success: (_) {
        // Invalidar providers para refrescar
        ref.invalidate(groupExpensesProvider(groupId));
        ref.invalidate(groupDebtsProvider(groupId));
        ref.invalidate(groupBalanceProvider(groupId));
        ref.invalidate(groupsListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deuda liquidada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }
}
