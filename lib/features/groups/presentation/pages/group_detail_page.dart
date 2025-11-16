import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../expenses/domain/entities/debt.dart';
import '../../../expenses/domain/usecases/settle_debt_usecase.dart';
import '../providers/groups_provider.dart';
import '../providers/group_members_provider.dart';
import '../providers/group_balance_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

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

    return Scaffold(
      body: groupAsync.when(
        data: (group) {
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
                      onPressed: () => _showShareDialog(context, ref, group),
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
              onPressed: () => context.push('/groups/${widget.groupId}/expenses/add'),
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

  Future<void> _showShareDialog(BuildContext context, WidgetRef ref, group) async {
    final generateCodeUseCase = ref.read(generateInviteCodeUseCaseProvider);
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await generateCodeUseCase(widget.groupId);
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Cerrar loading

    result.when(
      success: (code) async {
        // Construir el enlace
        // Para web: usar la URL actual
        // Para móvil: usar un formato que funcione con deep links
        final baseUrl = Uri.base.origin;
        // Usar formato que funcione tanto en web como en móvil
        final inviteLink = baseUrl.isEmpty || baseUrl == 'null' 
            ? 'https://equigasto.app/join/$code' // URL de producción (ajustar según tu dominio)
            : '$baseUrl/join/$code';
        
        await showDialog(
          context: context,
          builder: (dialogContext) => _ShareGroupDialog(
            groupName: group.name,
            code: code,
            inviteLink: inviteLink,
          ),
        );
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar código: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}

class _ShareGroupDialog extends StatelessWidget {
  final String groupName;
  final String code;
  final String inviteLink;

  const _ShareGroupDialog({
    required this.groupName,
    required this.code,
    required this.inviteLink,
  });

  String get _shareMessage => '¡Únete a mi grupo "$groupName" en EquiGasto!\n\nCódigo: $code\nEnlace: $inviteLink';

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(_shareMessage);
    final url = Uri.parse('https://wa.me/?text=$message');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Intentar con el esquema nativo
        final nativeUrl = Uri.parse('whatsapp://send?text=$message');
        if (await canLaunchUrl(nativeUrl)) {
          await launchUrl(nativeUrl);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp no está instalado'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
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
    final message = Uri.encodeComponent(_shareMessage);
    final url = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(inviteLink)}&text=${Uri.encodeComponent('¡Únete a mi grupo "$groupName" en EquiGasto!\n\nCódigo: $code')}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Intentar con el esquema nativo
        final nativeUrl = Uri.parse('tg://msg?text=$message');
        if (await canLaunchUrl(nativeUrl)) {
          await launchUrl(nativeUrl);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Telegram no está instalado'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
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
    try {
      await Share.share(_shareMessage);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
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
    final isMobile = Platform.isAndroid || Platform.isIOS;

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
            const SizedBox(height: 16),
            const Text('Enlace:'),
            const SizedBox(height: 8),
            SelectableText(
              inviteLink,
              style: const TextStyle(fontSize: 12),
            ),
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
                onTap: () => _shareToWhatsApp(context),
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
                onTap: () => _shareToTelegram(context),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              // Compartir genérico
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Otras aplicaciones'),
                onTap: () => _shareGeneric(context),
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
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: inviteLink));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            }
          },
          child: const Text('Copiar enlace'),
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
                      final paidByName = paidByUser?.name ?? 'Usuario ${expense.paidBy.substring(0, 8)}';
                      
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(expense.description),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('€${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pagado por: $paidByName',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                            style: const TextStyle(fontSize: 12),
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
                      subtitle: Text('€${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}'),
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
                  final displayName = member != null ? member.name : 'Miembro ${index + 1}';
                  final initial = member != null 
                      ? member.name[0].toUpperCase() 
                      : memberId.substring(0, 1).toUpperCase();
                  
                  // Calcular balance del miembro
                  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
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
                          subtitle: member != null ? Text(member.email) : Text(memberId),
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
                        subtitle: member != null ? Text(member.email) : Text(memberId),
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
                        subtitle: member != null ? Text(member.email) : Text(memberId),
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
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => _InviteMemberDialog(
          emailController: emailController,
          formKey: formKey,
          groupId: groupId,
        ),
      );
    } finally {
      emailController.dispose();
    }
  }
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;
  final String groupId;

  const _InviteMemberDialog({
    required this.emailController,
    required this.formKey,
    required this.groupId,
  });

  @override
  ConsumerState<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  bool _isLoading = false;

  Future<void> _handleInvite() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inviteUseCase = ref.read(inviteUserToGroupUseCaseProvider);
      final result = await inviteUseCase(
        widget.groupId,
        widget.emailController.text.trim(),
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
        key: widget.formKey,
        child: TextFormField(
          controller: widget.emailController,
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
                    
                    final fromName = fromUser?.name ?? 'Usuario ${debt.fromUserId.substring(0, 8)}';
                    final toName = toUser?.name ?? 'Usuario ${debt.toUserId.substring(0, 8)}';
                    
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
                          icon: const Icon(Icons.check_circle, color: Colors.green),
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
                      title: Text('Usuario ${debt.fromUserId.substring(0, 8)} debe a Usuario ${debt.toUserId.substring(0, 8)}'),
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

