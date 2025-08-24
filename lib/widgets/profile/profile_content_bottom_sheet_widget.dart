import 'package:flutter/material.dart';

class ProfileContentBottomSheetWidget extends StatelessWidget {
  // final String title;
  final Widget content;
  final IconData icon;
  final Color iconColor;

  const ProfileContentBottomSheetWidget({
    super.key,
    // required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
  });

  static void show({
    required BuildContext context,
    required String title,
    required Widget content,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onClosed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ProfileContentBottomSheetWidget(
          // title: title,
          content: content,
          icon: icon,
          iconColor: iconColor,
        );
      },
    ).then((_) {
      // Bottom sheet kapandığında callback çağır
      onClosed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header with title and close button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon and title
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 1,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
