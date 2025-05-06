import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/sport_models/standing.dart';
import 'package:the_shot2/services/sport_services/football_service.dart';

class LeagueTable extends StatelessWidget {
  final String leagueId;

  const LeagueTable({Key? key, required this.leagueId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final footballService = Provider.of<FootballService>(context, listen: false);

    return FutureBuilder<List<Standing>>(
      future: footballService.fetchLeagueStandings(leagueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No standings available'));
        }

        final standings = snapshot.data!;
        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Team')),
              DataColumn(label: Text('P')),
              DataColumn(label: Text('W')),
              DataColumn(label: Text('D')),
              DataColumn(label: Text('L')),
              DataColumn(label: Text('Pts')),
            ],
            rows: standings.asMap().entries.map((entry) {
              final standing = entry.value;
              return DataRow(cells: [
                DataCell(Text(standing.position.toString())),
                DataCell(Text(standing.teamName)),
                DataCell(Text(standing.playedGames.toString())),
                DataCell(Text(standing.won.toString())),
                DataCell(Text(standing.drawn.toString())),
                DataCell(Text(standing.lost.toString())),
                DataCell(Text(standing.points.toString())),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}