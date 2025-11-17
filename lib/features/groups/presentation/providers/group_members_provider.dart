import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/di/providers.dart';

final groupMembersProvider = FutureProvider.family<List<User>, List<String>>((ref, memberIds) async {
  if (memberIds.isEmpty) {
    print('🔍 groupMembersProvider - Lista de IDs vacía');
    debugPrint('🔍 groupMembersProvider - Lista de IDs vacía');
    return [];
  }
  
  print('🔍 groupMembersProvider - Obteniendo usuarios: $memberIds');
  debugPrint('🔍 groupMembersProvider - Obteniendo usuarios: $memberIds');
  
  // Usar ref.read en lugar de ref.watch para evitar recargas infinitas
  final userRemoteDataSource = ref.read(userRemoteDataSourceProvider);
  try {
    // Agregar timeout de 5 segundos
    final users = await Future(() => userRemoteDataSource.getUsersByIds(memberIds)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('❌ groupMembersProvider - Timeout después de 5 segundos');
        debugPrint('❌ groupMembersProvider - Timeout después de 5 segundos');
        return <User>[];
      },
    );
    
    print('✅ groupMembersProvider - Usuarios obtenidos: ${users.length}');
    debugPrint('✅ groupMembersProvider - Usuarios obtenidos: ${users.length}');
    return users;
  } catch (e) {
    print('❌ groupMembersProvider - Error: $e');
    debugPrint('❌ groupMembersProvider - Error: $e');
    // Si falla, retornar lista vacía
    return [];
  }
});

