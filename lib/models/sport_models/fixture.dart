class Fixture {
  final String homeTeam;
  final String awayTeam;
  final DateTime date;

  Fixture({
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      homeTeam: json['homeTeam']['name'] ?? '',
      awayTeam: json['awayTeam']['name'] ?? '',
      date: DateTime.parse(json['utcDate'] ?? ''),
    );
  }
}