// lib/authentication/user_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tf_news/authentication/user_model.dart';
import 'package:tf_news/utils/exceptions/firebase_exceptions.dart';
import 'package:tf_news/utils/exceptions/formate_exceptions.dart';

class UserRepository extends GetxService {
  static UserRepository get instance => Get.find();

  static const String _cloudinaryCloudName = 'ddf0yaapn';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> saveUserRecord(UserModel user) async {
    try {
      final docRef = _db.collection("users").doc(user.id);
      final existing = await docRef.get();
      if (existing.exists) {
        final existingData = existing.data() ?? <String, dynamic>{};
        final updates = <String, dynamic>{};
        user.toJson().forEach((key, value) {
          if (value != null &&
              value is! FieldValue &&
              value.toString().trim().isNotEmpty) {
            final prev = existingData[key];
            if (prev == null || prev.toString().trim().isEmpty) {
              updates[key] = value;
            }
          }
        });
        if (updates.isNotEmpty) {
          await docRef.set(updates, SetOptions(merge: true));
        }
        return;
      }

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
    return fetchUserById(FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  /// Fetch user details directly from Cloud Firestore `users/{uid}`
  Future<UserModel> fetchUserById(String userId) async {
    if (userId.isEmpty) return UserModel.empty();
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
      await _db
          .collection("users")
          .doc(updatedUser.id)
          .set(updatedUser.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> updateSingleField(Map<String, dynamic> json) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      await _db
          .collection("users")
          .doc(uid)
          .set(json, SetOptions(merge: true));
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
