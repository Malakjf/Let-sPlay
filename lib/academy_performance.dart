import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A simple model for an academy player, containing only the necessary fields
/// for this page.
class AcademyPlayer {
  final String id;
  final String name;
  final int age;
  final String position;
  final String avatarUrl;
  int rating; // Mutable for direct adjustment on the list
  String notes; // Mutable for coach feedback

  AcademyPlayer({
    required this.id,
    required this.name,
    required this.age,
    required this.position,
    required this.avatarUrl,
    this.rating = 50, // Default rating
    this.notes = '', // Default empty notes
  });
}

class AcademyPerformancePage extends StatefulWidget {
  const AcademyPerformancePage({super.key});

  @override
  State<AcademyPerformancePage> createState() => _AcademyPerformancePageState();
}

class _AcademyPerformancePageState extends State<AcademyPerformancePage> {
  // Define custom colors for the dark theme
  static const Color _backgroundColor = Color(0xFF151924);
  static const Color _cardColor = Color(0xFF222836);
  static const Color _primaryColor = Color(0xFF29C5EE);
  static const Color _textColor = Colors.white;
  static const Color _subtitleColor = Colors.white70;

  // Robust text style helper to prevent white screen if font fails to load
  TextStyle _safeStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.normal, Color color = _textColor}) {
    try { return GoogleFonts.saira(fontSize: fontSize, fontWeight: fontWeight, color: color); }
    catch (e) { return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, fontFamily: 'sans-serif'); }
  }

  // Dummy data for demonstration
  final List<AcademyPlayer> _players = [
    AcademyPlayer(
      id: 'p1',
      name: 'Alice Smith',
      age: 16,
      position: 'Forward',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      rating: 78,
    ),
    AcademyPlayer(
      id: 'p2',
      name: 'Bob Johnson',
      age: 17,
      position: 'Midfielder',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      rating: 85,
    ),
    AcademyPlayer(
      id: 'p3',
      name: 'Charlie Brown',
      age: 15,
      position: 'Defender',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      rating: 62,
    ),
    AcademyPlayer(
      id: 'p4',
      name: 'Diana Prince',
      age: 16,
      position: 'Goalkeeper',
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
      rating: 70,
    ),
    AcademyPlayer(
      id: 'p5',
      name: 'Eve Adams',
      age: 17,
      position: 'Forward',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      rating: 91,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          'Academy Performance',
          style: _safeStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          return _buildPlayerCard(player);
        },
      ),
    );
  }

  // Helper to validate image URLs safely
  bool _isValidUrl(String? url) {
    return url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  Widget _buildPlayerCard(AcademyPlayer player) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Circular Profile Photo
            CircleAvatar(
              radius: 30,
              backgroundImage: _isValidUrl(player.avatarUrl)
                  ? NetworkImage(player.avatarUrl)
                  : null, // No background image if URL is invalid
              backgroundColor: _primaryColor.withOpacity(0.3),
              child: !_isValidUrl(player.avatarUrl)
                  ? Icon(
                      Icons.person,
                      color: _textColor.withOpacity(0.7),
                      size: 30,
                    ) // Fallback icon
                  : null,
            ),
            const SizedBox(width: 16),
            // Player Name, Age, Position
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: _safeStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${player.age} yrs | ${player.position}',
                    style: _safeStyle(fontSize: 14, color: _subtitleColor),
                  ),
                ],
              ),
            ),
            // Rating Display with +/- buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: _primaryColor,
                  ),
                  onPressed: () => _updateRating(player, -1),
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    player.rating.toString(),
                    style: _safeStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: _primaryColor,
                  ),
                  onPressed: () => _updateRating(player, 1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Notes Icon Button
            IconButton(
              icon: const Icon(Icons.notes, color: _primaryColor),
              onPressed: () => _showNotesSheet(player),
            ),
          ],
        ),
      ),
    );
  }

  void _updateRating(AcademyPlayer player, int increment) {
    setState(() {
      player.rating = (player.rating + increment).clamp(0, 100);
    });
  }

  void _showNotesSheet(AcademyPlayer player) {
    final TextEditingController notesController = TextEditingController(
      text: player.notes,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      backgroundColor: Colors.transparent, // For rounded corners
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notes for ${player.name}',
                  style: _safeStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: notesController,
                  maxLines: 5,
                  minLines: 3,
                  style: _safeStyle(),
                  decoration: InputDecoration(
                    hintText: 'Enter detailed feedback here...',
                    hintStyle: _safeStyle(color: _subtitleColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _primaryColor.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _backgroundColor,
                  ),
                  cursorColor: _primaryColor,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        player.notes = notesController.text;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notes for ${player.name} saved!',
                            style: _safeStyle(),
                          ),
                          backgroundColor: _primaryColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Save Notes',
                      style: _safeStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _backgroundColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
