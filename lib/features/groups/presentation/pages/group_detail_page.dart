import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../../../core/di/providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsRepository = ref.watch(groupsRepositoryProvider);
    final groupAsync = FutureProvider((ref) async {
      final result = await groupsRepository.getGroupById(groupId);
      return result.when(
        success: (group) => group,
        error: (_) => throw Exception('Grupo no encontrado'),
      );
    });

    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: ref.watch(groupAsync).when(
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
                  const TabBar(
                    tabs: [
                      Tab(text: 'Gastos'),
                      Tab(text: 'Miembros'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ExpensesTab(groupId: groupId),
                        _MembersTab(group: group),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/groups/$groupId/expenses/add'),
          child: const Icon(Icons.add),
        ),
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

    return expensesAsync.when(
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
                subtitle: Text('\$${expense.amount.toStringAsFixed(2)}'),
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
    );
  }
}

class _MembersTab extends StatelessWidget {
  final group;

  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
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
          ),
        );
      },
    );
  }
}

