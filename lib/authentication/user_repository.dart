// lib/authentication/user_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tf_news/authentication/user_model.dart';
import 'package:tf_news/data/opportunity.dart' show kTfApiBaseUrl;
import 'package:tf_news/utils/exceptions/firebase_exceptions.dart';
import 'package:tf_news/utils/exceptions/formate_exceptions.dart';

class UserRepository extends GetxService {
  static UserRepository get instance => Get.find();

  static const String _cloudinaryCloudName = 'ddf0yaapn';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> saveUserRecord(UserModel user) async {
    try {
      await http
          .put(
            Uri.parse('$kTfApiBaseUrl/api/collections/users/${user.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': user.firstName,
              'lastName': user.lastName,
              'username': user.username,
              'email': user.email,
              'phone': user.phone,
              'profilePicture': user.profilePicture,
              'academicLevel': user.academicLevel,
              'grade': user.grade,
              'stemSchool': user.stemSchool,
              'gender': user.gender,
              'birthDate': user.birthDate,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return;
    } catch (_) {}

    try {
      final docRef = _db.collection("users").doc(user.id);
      final existing = await docRef.get();
      if (existing.exists) return;

      await docRef.set(user.toJson());
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.code}';
    } on FormatException catch (_) {
      throw 'Invalid data format.';
    } on PlatformException catch (e) {
      throw 'Platform error: ${e.code}';
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  Future<UserModel> fetchUserDetails() {
    final vpsUser = GetStorage().read('tf_vps_user');
    if (vpsUser is Map && vpsUser['id'] != null) {
      return fetchUserById(vpsUser['id'].toString());
    }
    return fetchUserById(FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  /// Fetch user details by user ID (VPS API primary, Firestore fallback)
  Future<UserModel> fetchUserById(String userId) async {
    if (userId.isEmpty) return UserModel.empty();
    try {
      final res = await http
          .get(Uri.parse('$kTfApiBaseUrl/api/collections/users/$userId'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? body;
        return UserModel(
          id: userId,
          firstName: (data['firstName'] ?? '').toString(),
          lastName: (data['lastName'] ?? '').toString(),
          username: (data['username'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          phone: (data['phone'] ?? '').toString(),
          profilePicture: (data['profilePicture'] ?? '').toString(),
          academicLevel: (data['academicLevel'] ?? '').toString(),
          grade: (data['grade'] ?? '').toString(),
          stemSchool: (data['stemSchool'] ?? '').toString(),
          gender: (data['gender'] ?? '').toString(),
          birthDate: (data['birthDate'] ?? '').toString(),
        );
      }
    } catch (_) {}

    try {
      final documentSnapshot = await _db.collection("users").doc(userId).get();
      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> updateUserDetails(UserModel updatedUser) async {
    try {
      await http
          .put(
            Uri.parse('$kTfApiBaseUrl/api/collections/users/${updatedUser.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': updatedUser.firstName,
              'lastName': updatedUser.lastName,
              'username': updatedUser.username,
              'email': updatedUser.email,
              'phone': updatedUser.phone,
              'profilePicture': updatedUser.profilePicture,
              'academicLevel': updatedUser.academicLevel,
              'grade': updatedUser.grade,
              'stemSchool': updatedUser.stemSchool,
              'gender': updatedUser.gender,
              'birthDate': updatedUser.birthDate,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return;
    } catch (_) {}

    try {
      await _db
          .collection("users")
          .doc(updatedUser.id)
          .update(updatedUser.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> updateSingleField(Map<String, dynamic> json) async {
    final vpsUser = GetStorage().read('tf_vps_user');
    final uid = (vpsUser is Map && vpsUser['id'] != null)
        ? vpsUser['id'].toString()
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    try {
      await http
          .put(
            Uri.parse('$kTfApiBaseUrl/api/collections/users/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(json),
          )
          .timeout(const Duration(seconds: 6));
      return;
    } catch (_) {}

    try {
      await _db.collection("users").doc(uid).update(json);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> removeUserRecord(String userId) async {
    try {
      await http
          .delete(Uri.parse('$kTfApiBaseUrl/api/collections/users/$userId'))
          .timeout(const Duration(seconds: 6));
      return;
    } catch (_) {}

    try {
      await _db.collection("users").doc(userId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Upload any image to Cloudinary
  Future<String> uploadImage(String uploadPreset, XFile image) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw 'Cloudinary upload failed: $responseBody';
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong while uploading the image: $e';
    }
  }
}
