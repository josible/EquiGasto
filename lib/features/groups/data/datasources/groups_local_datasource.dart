import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/group.dart';

abstract class GroupsLocalDataSource {
  Future<List<Group>> getUserGroups(String userId);
  Future<Group?> getGroupById(String groupId);
  Future<void> saveGroup(Group group);
  Future<void> deleteGroup(String groupId);
}

class GroupsLocalDataSourceImpl implements GroupsLocalDataSource {
  final SharedPreferences prefs;

  GroupsLocalDataSourceImpl(this.prefs);

  @override
  Future<List<Group>> getUserGroups(String userId) async {
    final groupsJson = prefs.getString('groups') ?? '[]';
    final List<dynamic> groupsList = jsonDecode(groupsJson);
    
    final groups = groupsList
        .map((json) => _groupFromJson(json as Map<String, dynamic>))
        .where((group) => group.memberIds.contains(userId))
        .toList();

    return groups;
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    final groupsJson = prefs.getString('groups') ?? '[]';
    final List<dynamic> groupsList = jsonDecode(groupsJson);
    
    try {
      final groupJson = groupsList.firstWhere(
        (json) => (json as Map<String, dynamic>)['id'] == groupId,
      ) as Map<String, dynamic>;
      return _groupFromJson(groupJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveGroup(Group group) async {
    final groupsJson = prefs.getString('groups') ?? '[]';
    final List<dynamic> groupsList = jsonDecode(groupsJson);
    
    final groupMap = _groupToJson(group);
    final index = groupsList.indexWhere(
      (json) => (json as Map<String, dynamic>)['id'] == group.id,
    );

    if (index >= 0) {
      groupsList[index] = groupMap;
    } else {
      groupsList.add(groupMap);
    }

    await prefs.setString('groups', jsonEncode(groupsList));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final groupsJson = prefs.getString('groups') ?? '[]';
    final List<dynamic> groupsList = jsonDecode(groupsJson);
    
    groupsList.removeWhere(
      (json) => (json as Map<String, dynamic>)['id'] == groupId,
    );

    await prefs.setString('groups', jsonEncode(groupsList));
  }

  Group _groupFromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _groupToJson(Group group) {
    return {
      'id': group.id,
      'name': group.name,
      'description': group.description,
      'createdBy': group.createdBy,
      'memberIds': group.memberIds,
      'createdAt': group.createdAt.toIso8601String(),
      'updatedAt': group.updatedAt.toIso8601String(),
    };
  }
}


