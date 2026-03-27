import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import  'package:smart_vigie/models/admin_user.dart';
import 'package:smart_vigie/services/admin_service.dart';
import 'package:smart_vigie/utils/Appcolors.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final AdminService _adminService = AdminService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add admin dialog controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'admin';

  bool _isLoading = false;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _currentUserEmail = _auth.currentUser?.email;
    _updateCurrentUserLastLogin();
  }

  Future<void> _updateCurrentUserLastLogin() async {
    if (_currentUserEmail != null) {
      await _adminService.updateLastLogin(_currentUserEmail!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddAdminDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'admin@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.admin_panel_settings),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emailController.clear();
              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addAdmin,
            child: const Text('Add Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAdmin() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _adminService.addAdmin(
      _emailController.text.trim(),
      _nameController.text.trim(),
      _selectedRole,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _emailController.clear();
      _nameController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add admin. Email might already exist.')),
      );
    }
  }

  Future<void> _confirmDeleteAdmin(AdminUser admin) async {
    if (admin.email == _currentUserEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete yourself!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete ${admin.name} (${admin.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              final success = await _adminService.deleteAdmin(admin.id, admin.email);

              setState(() {
                _isLoading = false;
              });

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${admin.name} has been deleted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete admin')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return '#FF9800';
      case 'admin':
        return '#2196F3';
      case 'viewer':
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: Appcolors.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddAdminDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Admin',
          ),
          IconButton(
            onPressed: () async {
              final count = await _adminService.getAdminCount();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Total Admins: $count')),
              );
            },
            icon: const Icon(Icons.people, color: Colors.white),
            tooltip: 'Admin Count',
          ),
        ],
      ),
      body: StreamBuilder<List<AdminUser>>(
        stream: _adminService.getAdmins(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No admins found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddAdminDialog,
                    child: const Text('Add First Admin'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final isCurrentUser = admin.email == _currentUserEmail;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isCurrentUser
                        ? LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(_getRoleColor(admin.role).substring(1), radix: 16))
                          .withOpacity(0.2),
                      child: Text(
                        admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Color(int.parse(_getRoleColor(admin.role).substring(1), radix: 16)),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            admin.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          admin.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(int.parse(_getRoleColor(admin.role).substring(1), radix: 16))
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                admin.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(int.parse(_getRoleColor(admin.role).substring(1), radix: 16)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Last login: ${_formatDateTime(admin.lastLogin)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Joined: ${admin.createdAt.day}/${admin.createdAt.month}/${admin.createdAt.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: isCurrentUser
                        ? IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                      onPressed: () {
                        _showAdminDetails(admin);
                      },
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            _showEditAdminDialog(admin);
                          },
                          tooltip: 'Edit Admin',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDeleteAdmin(admin);
                          },
                          tooltip: 'Delete Admin',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAdminDetails(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${admin.name} - Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.email, 'Email', admin.email),
            const Divider(),
            _buildDetailRow(Icons.admin_panel_settings, 'Role', admin.role.toUpperCase()),
            const Divider(),
            _buildDetailRow(Icons.schedule, 'Last Login',
                '${admin.lastLogin.day}/${admin.lastLogin.month}/${admin.lastLogin.year} ${admin.lastLogin.hour}:${admin.lastLogin.minute}'),
            const Divider(),
            _buildDetailRow(Icons.calendar_today, 'Joined',
                '${admin.createdAt.day}/${admin.createdAt.month}/${admin.createdAt.year}'),
            const Divider(),
            _buildDetailRow(Icons.person, 'Status', admin.isActive ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAdminDialog(AdminUser admin) {
    final nameController = TextEditingController(text: admin.name);
    String selectedRole = admin.role;
    bool isActive = admin.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Edit ${admin.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setStateDialog(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Update logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update functionality coming soon!')),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}