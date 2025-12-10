import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group.dart';
import '../providers/group_balance_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class GroupCard extends ConsumerWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(groupBalanceProvider(group.id));

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            group.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          group.description.isEmpty ? 'Sin descripción' : group.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: balanceAsync.when(
          data: (balance) {
            final isPositive = balance > 0.01;
            final isNegative = balance < -0.01;
            final color = isPositive 
                ? Colors.green 
                : isNegative 
                    ? Colors.red 
                    : Colors.grey;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatAmountWithSign(balance, group.currency),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberIds.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 14),
                  const SizedBox(width: 4),
                  Text('${group.memberIds.length}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          error: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.grey),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 14),
                  const SizedBox(width: 4),
                  Text('${group.memberIds.length}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}



