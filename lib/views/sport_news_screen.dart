//views/sport_news_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/sport_category.dart';
import 'package:the_shot2/viewmodels/news_viewmodel.dart';
import 'package:the_shot2/views/widgets/sport_widgets/fixture_list.dart';
import 'package:the_shot2/views/widgets/sport_widgets/league_table.dart';
import 'package:the_shot2/views/widgets/news_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class SportNewsScreen extends StatefulWidget {
  final SportCategory sport;

  const SportNewsScreen({Key? key, required this.sport}) : super(key: key);

  @override
  _SportNewsScreenState createState() => _SportNewsScreenState();
}

class _SportNewsScreenState extends State<SportNewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.sport.name.toLowerCase() == 'football' ? 3 : 1,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final viewModel = context.read<NewsViewModel>();
      Future.microtask(() => viewModel.fetchNewsForSport(widget.sport.query));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<NewsViewModel>();
    final isFootball = widget.sport.name.toLowerCase() == 'football';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.sport.name} News',
          style: GoogleFonts.merriweather(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        bottom: isFootball
            ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'News'),
            Tab(text: 'Table'),
            Tab(text: 'Fixtures'),
          ],
        )
            : null,
      ),
      body: isFootball
          ? TabBarView(
        controller: _tabController,
        children: [
          _buildNewsContent(context, viewModel),
          LeagueTable(leagueId: 'PL'),
          FixturesList(leagueId: 'PL'),
        ],
      )
          : _buildNewsContent(context, viewModel),
    );
  }

  Widget _buildNewsContent(BuildContext context, NewsViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search team, date, or event',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (query) {
                viewModel.setArticleSearchQuery(query);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Trending ${widget.sport.name} Posts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('sportCategory', isEqualTo: widget.sport.name)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading trending posts'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No trending posts available'));
              }
              return SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final post = snapshot.data!.docs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CachedNetworkImage(
                        imageUrl: post['thumbnailUrl'] ?? '',
                        width: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.sport.name} News',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                DropdownButton<String>(
                  value: context.watch<NewsViewModel>().sortMode,
                  items: const [
                    DropdownMenuItem(value: 'relevancy', child: Text('Relevancy')),
                    DropdownMenuItem(value: 'latest', child: Text('Latest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setSortMode(value);
                      viewModel.fetchNewsForSport(widget.sport.query, sortMode: value);
                    }
                  },
                ),
              ],
            ),
          ),
          Consumer<NewsViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(viewModel.errorMessage!),
                      ElevatedButton(
                        onPressed: () {
                          viewModel.clearError();
                          viewModel.fetchNewsForSport(widget.sport.query);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.filteredArticles.isEmpty) {
                return const Center(child: Text('No news available'));
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.fetchNewsForSport(widget.sport.query),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: viewModel.filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = viewModel.filteredArticles[index];
                    return NewsTile(article: article);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}