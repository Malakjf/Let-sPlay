class Player {
  final String id;
  final String name;
  final int goals;
  final int assists;
  final int motm;
  final int matches;
  final int level;
  final Map<String, int> metrics;
  final String imageUrl;
  final String countryFlagUrl;
  final String position;
  final String club;
  final String nationality;
  final int rating;
  final List<String> badges; // Add this field
  final int yellowCards;
  final int redCards;

  Player({
    required this.id,
    required this.name,
    required this.goals,
    required this.assists,
    required this.motm,
    required this.matches,
    required this.level,
    required this.metrics,
    required this.imageUrl,
    required this.countryFlagUrl,
    required this.position,
    required this.club,
    required this.nationality,
    required this.rating,
    required this.badges, // Add this parameter
    required this.yellowCards,
    required this.redCards,
  });
}
