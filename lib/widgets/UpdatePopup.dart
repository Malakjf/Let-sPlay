// A lightweight, focused update popup dialog used by UpdateService
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePopup extends StatelessWidget {
  final Map<String, dynamic> data;

  const UpdatePopup({super.key, required this.data});

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] as String?) ?? 'Update Available';
    final description = (data['description'] as String?) ?? '';
    final imageUrl = (data['imageUrl'] as String?) ?? '';
    final storeUrl =
        (data['storeUrl'] as String?) ?? (data['downloadUrl'] as String?);
    final isMandatory = (data['isMandatory'] as bool?) ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF081225),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (description.isNotEmpty)
              Text(
                description,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (storeUrl != null) {
                      _openUrl(storeUrl);
                    }
                    if (!isMandatory) Navigator.of(context).pop();
                  },
                  child: Text(isMandatory ? 'Update Required' : 'Update'),
                ),
                const SizedBox(width: 12),
                if (!isMandatory)
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
