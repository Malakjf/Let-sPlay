// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letsplay/widgets/App_Bottom_Nav.dart' show AppBottomNav;
import '../../services/language.dart';
import '../../models/user_permission.dart';
import '../../models/role_request.dart';
import '../../utils/permissions.dart';
import '../../services/firebase_service.dart';

class UserItem {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final UserPermission permission;
  final DateTime joinedDate;
  final bool isActive;

  const UserItem({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.permission,
    required this.joinedDate,
    this.isActive = true,
  });

  String get initials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }
}

class UserManagerScreen extends StatefulWidget {
  // ✅ FIXED: Added missing 'a' in Manager
  final LocaleController ctrl;
  const UserManagerScreen({
    super.key,
    required this.ctrl,
  }); // ✅ FIXED: Added missing 'a' in Manager

  @override
  State<UserManagerScreen> createState() => _UserManagerScreenState(); // ✅ FIXED: Added missing 'a' in Manager
}

class _UserManagerScreenState
    extends
        State<UserManagerScreen> // ✅ FIXED: Added missing 'a' in Manager
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<RoleRequest> _roleRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRoleRequests();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoadingUsers = true;
      });

      final users = await FirebaseService.instance.getAllUsers();

      // Debug: Print loaded users
      debugPrint(
        '🔧 [USER_MANAGER] Loaded ${users.length} users from Firestore',
      );
      for (var user in users) {
        debugPrint(
          '🔧 [USER_MANAGER] User: ${user['email']} - Role: ${user['role']}',
        );
      }

      if (!mounted) return;

      setState(() {
        _users = users.map((userData) {
          return UserItem(
            id: userData['uid'] ?? userData['id'] ?? '',
            name:
                userData['name'] ??
                userData['username'] ??
                userData['email']?.split('@')[0] ??
                'Unknown',
            email: userData['email'] ?? '',
            photoUrl: userData['imageUrl'] ?? userData['avatarUrl'],
            permission: permissionFromRole(
              userData['permissionLevel'] ?? userData['role'],
            ),
            joinedDate: userData['createdAt'] != null
                ? (userData['createdAt'] is Timestamp
                      ? userData['createdAt'].toDate()
                      : DateTime.parse(userData['createdAt']))
                : DateTime.now(),
            isActive: userData['isActive'] ?? true,
          );
        }).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoleRequests() async {
    try {
      final requests = await FirebaseService.instance.getRoleRequests();
      if (!mounted) return;
      setState(() {
        _roleRequests = requests.cast<RoleRequest>();
      });
    } catch (e) {
      print('Error loading role requests: $e');
    }
  }

  List<UserItem> _users = [];
  bool _isLoadingUsers = true;

  String _searchQuery = '';
  UserPermission? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;

    // Filter users based on search query and permission filter
    List<UserItem> filteredUsers = _users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPermission =
          _selectedFilter == null || user.permission == _selectedFilter;
      return matchesSearch && matchesPermission;
    }).toList();

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(
            ar ? 'إدارة المستخدمين' : 'Users Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: ar ? 'المستخدمين' : 'Users'),
              Tab(text: ar ? 'طلبات الأدوار' : 'Role Requests'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Users Tab
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          theme.appBarTheme.backgroundColor ??
                          const Color(0xFF1E2432),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color ?? Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: ar
                            ? 'البحث عن المستخدمين...'
                            : 'Search users...',
                        hintStyle: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              Colors.white54,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              Colors.white54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: ar ? 'الكل' : 'All',
                        isSelected: _selectedFilter == null,
                        onTap: () => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: ar ? 'مشرف' : 'Admin',
                        color: Colors.red,
                        permission: UserPermission.admin,
                        isSelected: _selectedFilter == UserPermission.admin,
                        onTap: () => setState(
                          () => _selectedFilter = UserPermission.admin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: ar ? 'منظم' : 'Organizer',
                        color: Colors.blue,
                        permission: UserPermission.organizer,
                        isSelected: _selectedFilter == UserPermission.organizer,
                        onTap: () => setState(
                          () => _selectedFilter = UserPermission.organizer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: ar ? 'مدرب' : 'Coach',
                        color: Colors.green,
                        permission: UserPermission.coach,
                        isSelected: _selectedFilter == UserPermission.coach,
                        onTap: () => setState(
                          () => _selectedFilter = UserPermission.coach,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: ar ? 'أكاديمية' : 'Academy',
                        color: Colors.purple,
                        permission: UserPermission.academy,
                        isSelected: _selectedFilter == UserPermission.academy,
                        onTap: () => setState(
                          () => _selectedFilter = UserPermission.academy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: ar ? 'لاعب' : 'Player',
                        color: Colors.orange,
                        permission: UserPermission.player,
                        isSelected: _selectedFilter == UserPermission.player,
                        onTap: () => setState(
                          () => _selectedFilter = UserPermission.player,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Users List
                Expanded(
                  child: _isLoadingUsers
                      ? const Center(child: CircularProgressIndicator())
                      : filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color:
                                    theme.textTheme.bodyMedium?.color ??
                                    Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? (ar
                                          ? 'لا توجد نتائج'
                                          : 'No results found')
                                    : (ar ? 'لا يوجد مستخدمين' : 'No users'),
                                style: TextStyle(
                                  color:
                                      theme.textTheme.bodyMedium?.color ??
                                      Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _UserCard(
                              user: user,
                              onPermissionChange: (newPermission) {
                                _updateUserPermission(user, newPermission);
                              },
                              ar: ar,
                            );
                          },
                        ),
                ),
              ],
            ),
            // Role Requests Tab
            _roleRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 64,
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ar ? 'لا توجد طلبات أدوار' : 'No role requests',
                          style: TextStyle(
                            color:
                                theme.textTheme.bodyMedium?.color ??
                                Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _roleRequests.length,
                    itemBuilder: (context, index) {
                      final request = _roleRequests[index];
                      return _RoleRequestCard(
                        request: request,
                        onApprove: () => _approveRoleRequest(request),
                        onReject: () => _rejectRoleRequest(request),
                        ar: ar,
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: const AppBottomNav(index: 3),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    UserPermission? permission,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (permission != null
                    ? (color ?? Colors.grey).withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.3))
              : theme.appBarTheme.backgroundColor ?? const Color(0xFF1E2432),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: permission != null
                      ? (color ?? Colors.grey)
                      : theme.colorScheme.primary,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (permission != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (permission != null ? color : theme.colorScheme.primary)
                    : (theme.textTheme.bodyMedium?.color ?? Colors.white),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserPermission(
    UserItem user,
    UserPermission newPermission,
  ) async {
    try {
      // Convert UserPermission to role string
      String roleString;
      final permissionLevelString = newPermission.name.toUpperCase();

      switch (newPermission) {
        case UserPermission.admin:
          roleString = 'Admin';
          break;
        case UserPermission.organizer:
          roleString = 'Organizer';
          break;
        case UserPermission.coach:
          roleString = 'Coach';
          break;
        case UserPermission.academy:
          roleString = 'academy_player';
          break;
        case UserPermission.player:
          roleString = 'Player';
          break;
      }

      // Update in Firestore
      await FirebaseService.instance.updateUserData(user.id, {
        'role': roleString,
        'permissionLevel': permissionLevelString,
      });

      // Reload users from Firestore to ensure fresh data
      await _loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'تم تحديث صلاحية المستخدم بنجاح'
                : 'User permission updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating user permission: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'فشل في تحديث صلاحية المستخدم'
                : 'Failed to update user permission',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          widget.ctrl.isArabic ? 'إضافة مستخدم جديد' : 'Add New User',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
          ),
        ),
        content: const Text('Add user functionality would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.ctrl.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.ctrl.isArabic ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRoleRequest(RoleRequest request) async {
    try {
      await FirebaseService.instance.approveRoleRequest(
        request.id,
        request.userId,
        request.requestedRole,
      );
      if (!mounted) return;
      setState(() {
        _roleRequests.removeWhere((r) => r.id == request.id);
      });
      // Reload users to reflect the updated role
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'تمت الموافقة على طلب الدور'
                : 'Role request approved',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error approving role request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'فشل في الموافقة على الطلب'
                : 'Failed to approve request',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRoleRequest(RoleRequest request) async {
    try {
      await FirebaseService.instance.rejectRoleRequest(request.id);
      if (!mounted) return;
      setState(() {
        _roleRequests.removeWhere((r) => r.id == request.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic ? 'تم رفض طلب الدور' : 'Role request rejected',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error rejecting role request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'فشل في رفض الطلب'
                : 'Failed to reject request',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserItem user;
  final Function(UserPermission) onPermissionChange;
  final bool ar;

  const _UserCard({
    required this.user,
    required this.onPermissionChange,
    required this.ar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.appBarTheme.backgroundColor ?? const Color(0xFF1E2432);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(
                      user.photoUrl!.contains('?')
                          ? '${user.photoUrl}&t=${DateTime.now().millisecondsSinceEpoch}'
                          : '${user.photoUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                    )
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.initials,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PermissionBadge(permission: user.permission, ar: ar),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: user.isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive
                            ? (ar ? 'نشط' : 'Active')
                            : (ar ? 'غير نشط' : 'Inactive'),
                        style: TextStyle(
                          color: user.isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            PopupMenuButton<UserPermission>(
              onSelected: (permission) => onPermissionChange(permission),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: UserPermission.admin,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ar ? 'مشرف' : 'Admin',
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: UserPermission.organizer,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ar ? 'منظم' : 'Organizer',
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: UserPermission.coach,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ar ? 'مدرب' : 'Coach',
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: UserPermission.academy,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ar ? 'لاعب أكاديمية' : 'Academy Player',
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: UserPermission.player,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ar ? 'لاعب' : 'Player',
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.more_vert,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ar ? 'إدارة' : 'Manage',
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color ?? Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRequestCard extends StatelessWidget {
  final RoleRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool ar;

  const _RoleRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.ar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.appBarTheme.backgroundColor ?? const Color(0xFF1E2432);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    request.userName.isNotEmpty
                        ? request.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.userEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'طلب الترقية إلى: ${request.requestedRole}'
                  : 'Requested role: ${request.requestedRole}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              ar
                  ? 'تاريخ الطلب: ${request.requestDate.toLocal().toString().split(' ')[0]}'
                  : 'Request date: ${request.requestDate.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(ar ? 'موافقة' : 'Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(ar ? 'رفض' : 'Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  final UserPermission permission;
  final bool ar;

  const _PermissionBadge({required this.permission, required this.ar});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (permission) {
      case UserPermission.admin:
        color = Colors.red;
        label = ar ? 'مشرف' : 'Admin';
        break;
      case UserPermission.organizer:
        color = Colors.blue;
        label = ar ? 'منظم' : 'Organizer';
        break;
      case UserPermission.coach:
        color = Colors.green;
        label = ar ? 'مدرب' : 'Coach';
        break;
      case UserPermission.academy:
        color = Colors.purple;
        label = ar ? 'أكاديمية' : 'Academy';
        break;
      case UserPermission.player:
        color = Colors.orange;
        label = ar ? 'لاعب' : 'Player';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
