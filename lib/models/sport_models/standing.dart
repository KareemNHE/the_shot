class Standing {
  final String teamName;
  final int position;
  final int points;
  final int playedGames;
  final int won;
  final int drawn;
  final int lost;

  Standing({
    required this.teamName,
    required this.position,
    required this.points,
    required this.playedGames,
    required this.won,
    required this.drawn,
    required this.lost,
  });

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      teamName: json['team']['name'] ?? '',
      position: json['position'] ?? 0,
      points: json['points'] ?? 0,
      playedGames: json['playedGames'] ?? 0,
      won: json['won'] ?? 0,
      drawn: json['draw'] ?? 0,
      lost: json['lost'] ?? 0,
    );
  }
}