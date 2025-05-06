//views/news_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/news_viewmodel.dart';
import 'package:the_shot2/views/sport_news_screen.dart';
import 'package:the_shot2/views/widgets/sport_tile.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sports News',
          style: GoogleFonts.merriweather(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: Consumer<NewsViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            onRefresh: () async {
              viewModel.clearError();
              if (viewModel.sports.isNotEmpty) {
                await viewModel.fetchNewsForSport(viewModel.sports.first.query);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search sports',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (query) {
                      viewModel.setSportSearchQuery(query);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sports',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: viewModel.filteredSports.length,
                      itemBuilder: (context, index) {
                        final sport = viewModel.filteredSports[index];
                        return SportTile(
                          sport: sport,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SportNewsScreen(sport: sport),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}