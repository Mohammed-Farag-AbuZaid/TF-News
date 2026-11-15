// lib/authentication/change_academic_info_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/pages/home_page.dart';
import 'package:tf_news/utils/popups/loaders.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

class ChangeAcademicInfo extends StatefulWidget {
  const ChangeAcademicInfo({
    super.key,
    this.showBackArrow = true,
    this.fullMessage = true,
    this.title = 'Complete Your Profile',
    this.description =
        'Update your name, academic track, and school right here.',
  });

  final String title;
  final String description;
  final bool fullMessage;
  final bool showBackArrow;

  @override
  State<ChangeAcademicInfo> createState() => _ChangeAcademicInfoState();
}

class _ChangeAcademicInfoState extends State<ChangeAcademicInfo> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  String _level = 'STEM';
  String _grade = 'Grade 11';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = UserController.instance.user.value;
    _firstCtrl.text = u.firstName;
    _lastCtrl.text = u.lastName;
    _schoolCtrl.text = u.stemSchool;
    if (u.academicLevel.isNotEmpty) _level = u.academicLevel;
    if (u.grade.isNotEmpty) _grade = u.grade;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final first = _firstCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      final full = '$first $last'.trim();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': first,
        'lastName': last,
        'fullName': full,
        'academicLevel': _level,
        'level': _level,
        'grade': _grade,
        'stemSchool': _schoolCtrl.text.trim(),
        'school': _schoolCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await UserController.instance.fetchUserRecord();
      if (!mounted) return;
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Save failed', message: e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      showBack: widget.showBackArrow,
      title: widget.title,
      subtitle: widget.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstCtrl,
                  decoration: authInput('First name', Icons.person_outline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lastCtrl,
                  decoration: authInput('Last name', Icons.person_outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: authInput('Academic level', Icons.school_outlined),
            items: const [
              DropdownMenuItem(value: 'STEM', child: Text('STEM')),
              DropdownMenuItem(value: 'Thanawy', child: Text('Thanawy')),
              DropdownMenuItem(value: 'Prep School', child: Text('Prep School')),
              DropdownMenuItem(value: 'University', child: Text('University')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _level = v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _grade,
            decoration: authInput('Grade / Year', Icons.grade_outlined),
            items: const [
              DropdownMenuItem(value: 'Grade 9', child: Text('Grade 9')),
              DropdownMenuItem(value: 'Grade 10', child: Text('Grade 10')),
              DropdownMenuItem(value: 'Grade 11', child: Text('Grade 11')),
              DropdownMenuItem(value: 'Grade 12', child: Text('Grade 12')),
              DropdownMenuItem(value: 'Undergrad', child: Text('Undergrad')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _grade = v);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _schoolCtrl,
            decoration:
                authInput('School / University', Icons.account_balance_outlined),
          ),
          const SizedBox(height: 20),
          TfPrimaryButton(
            label: _saving ? 'Saving...' : 'Save and continue',
            expand: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
