import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class UserProfileHeader extends StatelessWidget {
  final User? user;
  final VoidCallback? onImageUpload;
  final String? profileImageUrl;

  const UserProfileHeader(
      {super.key,
      required this.user,
      this.onImageUpload,
      this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onImageUpload,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          )
                        ]),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Email: ${user?.email ?? 'Not available'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
