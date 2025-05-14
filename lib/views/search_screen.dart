//views/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/post_interaction_viewmodel.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_app_bar.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_accounts.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_hashtags.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_posts.dart';
import '../viewmodels/search_viewmodel.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => Provider.of<SearchViewModel>(context, listen: false).fetchAllUserPosts());
    _searchController.addListener(() {
      Provider.of<SearchViewModel>(context, listen: false).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostInteractionViewModel(),
      child: Scaffold(
        appBar: SearchAppBar(
          searchController: _searchController,
          showTabs: true,
          tabBar: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF8A56AC),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF8A56AC),
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Hashtags'),
              Tab(text: 'Accounts'),
            ],
          ),
        ),
        body: Consumer<SearchViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && !viewModel.isRefreshing) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.errorMessage!),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        viewModel.clearError();
                        viewModel.fetchAllUserPosts(isRefresh: true);
                      },
                    ),
                  ),
                );
              });
              return const Center(child: Text('Error loading posts. Please try again.'));
            }

            return TabBarView(
              controller: _tabController,
              children: const [
                SearchTabPosts(),
                SearchTabHashtags(),
                SearchTabAccounts(),
              ],
            );
          },
        ),
      ),
    );
  }
}