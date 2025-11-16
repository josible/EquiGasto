import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../expenses/domain/entities/debt.dart';
import '../providers/groups_provider.dart';
import '../providers/group_members_provider.dart';
import '../../../auth/domain/entities/user.dart';

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
}

class _ExpensesTab extends ConsumerWidget {
  final String groupId;

  const _ExpensesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

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
                  
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(initial),
                      ),
                      title: Text(displayName),
                      subtitle: member != null ? Text(member.email) : Text(memberId),
                      trailing: group.createdBy == memberId
                          ? const Chip(
                              label: Text('Creador'),
                              labelStyle: TextStyle(fontSize: 12),
                            )
                          : null,
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
                    leading: CircleAvatar(
                      child: Text(memberId.substring(0, 1).toUpperCase()),
                    ),
                    title: Text('Miembro ${index + 1}'),
                    subtitle: Text(memberId),
                    trailing: group.createdBy == memberId
                        ? const Chip(
                            label: Text('Creador'),
                            labelStyle: TextStyle(fontSize: 12),
                          )
                        : null,
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

class _AccountsTab extends ConsumerWidget {
  final String groupId;

  const _AccountsTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(groupDebtsProvider(groupId));
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
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
}

