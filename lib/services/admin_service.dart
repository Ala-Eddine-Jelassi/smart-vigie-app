import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  final String _adminCollection = 'admins';

  // Get all admins
  Stream<List<AdminUser>> getAdmins() {
    return _firestore
        .collection(_adminCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Add new admin
  Future<bool> addAdmin(String email, String name, String role) async {
    try {
      // Check if admin already exists
      final existing = await _firestore
          .collection(_adminCollection)
          .where('email', isEqualTo: email)
          .get();

      if (existing.docs.isNotEmpty) {
        return false; // Admin already exists
      }

      // Create admin user in Firebase Auth (optional)
      // You might want to create the user account first
      UserCredential? userCredential;
      try {
        // Generate a temporary password (you can change this logic)
        String tempPassword = _generateTempPassword();

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );

        // Send password reset email so admin can set their own password
        await _auth.sendPasswordResetEmail(email: email);

      } catch (e) {
        print('Error creating auth user: $e');
        // Continue if user already exists or handle differently
      }

      // Add to Firestore
      await _firestore.collection(_adminCollection).add({
        'email': email,
        'name': name,
        'lastLogin': DateTime(2024, 1, 1).toIso8601String(), // Initial last login
        'createdAt': DateTime.now().toIso8601String(),
        'role': role,
        'isActive': true,
        'uid': userCredential?.user?.uid ?? '',
      });

      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }

  // Delete admin
  Future<bool> deleteAdmin(String adminId, String email) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_adminCollection).doc(adminId).delete();

      // Optional: Delete from Firebase Auth
      // Note: You need admin privileges to delete users via Admin SDK
      // This is typically done via Cloud Function

      return true;
    } catch (e) {
      print('Error deleting admin: $e');
      return false;
    }
  }

  // Update admin last login time
  Future<void> updateLastLogin(String email) async {
    try {
      final query = await _firestore
          .collection(_adminCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Update admin status (activate/deactivate)
  Future<bool> updateAdminStatus(String adminId, bool isActive) async {
    try {
      await _firestore.collection(_adminCollection).doc(adminId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      print('Error updating admin status: $e');
      return false;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _firestore
        .collection(_adminCollection)
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Generate temporary password
  String _generateTempPassword() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Temp@${random.substring(random.length - 8)}';
  }

  // Get admin count
  Future<int> getAdminCount() async {
    final snapshot = await _firestore.collection(_adminCollection).get();
    return snapshot.size;
  }
}