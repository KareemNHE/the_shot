//views/widgets/search_widgets/search_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/search_viewmodel.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback? onClear;
  final bool showTabs;
  final TabBar? tabBar;

  const SearchAppBar({
    Key? key,
    required this.searchController,
    this.onClear,
    this.showTabs = true,
    this.tabBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              Provider.of<SearchViewModel>(context, listen: false).search('');
              if (onClear != null) onClear!();
            },
          )
              : null,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        ),
        onChanged: (value) {
          Provider.of<SearchViewModel>(context, listen: false).search(value);
        },
      ),
      bottom: showTabs ? tabBar : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    showTabs && tabBar != null ? kToolbarHeight + tabBar!.preferredSize.height : kToolbarHeight,
  );
}