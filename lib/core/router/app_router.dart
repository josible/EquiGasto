import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/groups/presentation/pages/groups_list_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/join_group_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../constants/route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RouteNames.groups,
        name: 'groups',
        builder: (context, state) => const GroupsListPage(),
      ),
      GoRoute(
        path: RouteNames.groupDetail,
        name: 'group-detail',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteNames.addExpense,
        name: 'add-expense',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return AddExpensePage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteNames.editExpense,
        name: 'edit-expense',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final expense = state.extra as Expense?;
          return AddExpensePage(
            groupId: groupId,
            initialExpense: expense,
          );
        },
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.joinGroup,
        name: 'join-group',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return JoinGroupPage(code: code);
        },
      ),
    ],
  );
}
