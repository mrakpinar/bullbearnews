import 'package:flutter/material.dart';

class ProfilePictureAddIconWidget extends StatelessWidget {
  final VoidCallback seeFullSizeOfImage;
  final VoidCallback uploadProfileImage;
  final String? profileImageUrl;
  final String defaultImagePath;
  final bool isDarkMode;
  const ProfilePictureAddIconWidget(
      {super.key,
      required this.seeFullSizeOfImage,
      required this.uploadProfileImage,
      required this.profileImageUrl,
      required this.defaultImagePath,
      required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: () => seeFullSizeOfImage(),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF948979).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profileImageUrl!.isNotEmpty
                  ? Image.network(
                      profileImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        defaultImagePath,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      defaultImagePath,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        // Add icon butonu
        Positioned(
          right: -1,
          bottom: -14,
          child: Container(
            width: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF948979),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF393E46)
                    : const Color(0xFFF5F5F5),
                width: 5,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add_a_photo,
                size: 16,
                color: Colors.white,
              ),
              onPressed: uploadProfileImage,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        )
      ],
    );
  }
}
