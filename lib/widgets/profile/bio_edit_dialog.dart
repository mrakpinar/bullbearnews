// widgets/profile/bio_edit_dialog.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BioEditDialog extends StatefulWidget {
  final String currentBio;
  final VoidCallback onBioUpdated;

  const BioEditDialog({
    super.key,
    required this.currentBio,
    required this.onBioUpdated,
  });

  @override
  State<BioEditDialog> createState() => _BioEditDialogState();
}

class _BioEditDialogState extends State<BioEditDialog> {
  late TextEditingController _bioController;
  bool _isLoading = false;
  final int _maxLength = 160; // Twitter tarzı karakter limiti

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveBio() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.updateBio(_bioController.text.trim());

      widget.onBioUpdated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Bio updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingChars = _maxLength - _bioController.text.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF393E46) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF393E46), Color(0xFF948979)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit Bio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bio Text Field
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: _maxLength,
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
              decoration: InputDecoration(
                hintText:
                    'Tell people about yourself...\n🚀 Crypto enthusiast\n💎 Diamond hands\n📈 Always HODL',
                hintStyle: TextStyle(
                  color: const Color(0xFF948979).withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF222831).withOpacity(0.5)
                    : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF948979).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF948979),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterText: '', // Hide default counter
              ),
              onChanged: (value) {
                setState(() {
                  // Rebuild to update character counter
                });
              },
            ),

            // Character Counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remainingChars characters remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: remainingChars < 0
                      ? Colors.red
                      : remainingChars < 20
                          ? Colors.orange
                          : const Color(0xFF948979),
                  fontFamily: 'DMSerif',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: const Color(0xFF948979).withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || remainingChars < 0) ? null : _saveBio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF948979),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'DMSerif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
