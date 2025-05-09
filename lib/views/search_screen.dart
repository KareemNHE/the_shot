//views/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/post_interaction_viewmodel.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/search_user_list_screen.dart';
import 'package:the_shot2/views/user_profile_screen.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_accounts.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_hashtags.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_tab_posts.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';
import '../viewmodels/home_viewmodel.dart';
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
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(35.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (query) {
                  Provider.of<SearchViewModel>(context, listen: false).search(query);
                },
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<SearchViewModel>(context, listen: false).fetchAllUserPosts(isRefresh: true);
          },
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          displacement: 40.0,
          child: Consumer<SearchViewModel>(
            builder: (context, viewModel, child) {
              print('SearchScreen: isLoading=${viewModel.isLoading}, posts=${viewModel.allPosts.length}');
              if (viewModel.isLoading && !viewModel.isRefreshing) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                print('SearchScreen error: ${viewModel.errorMessage}');
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

              final users = viewModel.filteredUsers;
              final posts = viewModel.allPosts;
              final query = _searchController.text.trim();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (query.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: const Color(0xFF8A56AC),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: const Color(0xFF8A56AC),
                              tabs: const [
                                Tab(text: 'Accounts'),
                                Tab(text: 'Hashtags'),
                                Tab(text: 'Posts'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 120,
                            child: TabBarView(
                              controller: _tabController,
                              children: const [
                                SearchTabAccounts(),
                                SearchTabHashtags(),
                                SearchTabPosts(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (query.isNotEmpty && users.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Accounts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchUserListScreen(query: query),
                                  ),
                                );
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(color: Color(0xFF8A56AC)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (query.isNotEmpty && users.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profile_picture.isNotEmpty
                                  ? (user.profile_picture.startsWith('http')
                                  ? NetworkImage(user.profile_picture)
                                  : AssetImage(user.profile_picture) as ImageProvider)
                                  : const AssetImage('assets/default_profile.png'),
                            ),
                            title: Text(user.username),
                            subtitle: Text('${user.first_name} ${user.last_name}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(userId: user.id),
                                ),
                              ).then((_) {
                                Provider.of<HomeViewModel>(context, listen: false).fetchPosts();
                              });
                            },
                          );
                        },
                        childCount: users.length,
                      ),
                    ),
                  if (query.isNotEmpty && users.isNotEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverPadding(
                    padding: const EdgeInsets.all(10.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final post = posts[index];
                          print('Rendering search post ${post.id}: isArchived=${post.isArchived}');
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.hardEdge,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(post: post),
                                  ),
                                );
                              },
                              child: post.type == 'video'
                                  ? VideoPostCard(
                                post: post,
                                isThumbnailOnly: true,
                                isGridView: true,
                              )
                                  : Image.network(
                                post.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: posts.isEmpty && users.isEmpty && !viewModel.isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No results found')),
                    )
                        : const SizedBox(height: 10),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}



