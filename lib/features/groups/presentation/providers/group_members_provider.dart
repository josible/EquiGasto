import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/di/providers.dart';

final groupMembersProvider = FutureProvider.family<List<User>, List<String>>((ref, memberIds) async {
  if (memberIds.isEmpty) return [];
  
  final userRemoteDataSource = ref.watch(userRemoteDataSourceProvider);
  try {
    return await userRemoteDataSource.getUsersByIds(memberIds);
  } catch (e) {
    // Si falla, retornar lista vacía
    return [];
  }
});

