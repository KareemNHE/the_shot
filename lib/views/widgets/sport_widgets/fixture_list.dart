import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/sport_models/fixture.dart';
import 'package:the_shot2/services/sport_services/football_service.dart';

class FixturesList extends StatelessWidget {
  final String leagueId;

  const FixturesList({Key? key, required this.leagueId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final footballService = Provider.of<FootballService>(context, listen: false);

    return FutureBuilder<List<Fixture>>(
      future: footballService.fetchUpcomingFixtures(leagueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No fixtures available'));
        }

        final fixtures = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: fixtures.length,
          itemBuilder: (context, index) {
            final fixture = fixtures[index];
            return Card(
              child: ListTile(
                title: Text('${fixture.homeTeam} vs ${fixture.awayTeam}'),
                subtitle: Text(DateFormat('MMM d, yyyy - HH:mm').format(fixture.date)),
              ),
            );
          },
        );
      },
    );
  }
}