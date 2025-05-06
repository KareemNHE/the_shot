
//views/bnb.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/services/api_service.dart';
import 'package:the_shot2/views/home_screen.dart';
import 'package:the_shot2/views/profile_screen.dart';
import 'package:the_shot2/views/search_screen.dart';
import 'package:the_shot2/views/post_screen.dart';
import '../components/theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'news_screen.dart';


class BottomNavBar extends StatefulWidget {
  final int initialPage;

  const BottomNavBar({this.initialPage = 0, Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
        (_) => GlobalKey<NavigatorState>(),
  );

  final List<Widget> _screens = [
    HomeScreen(),
    const SearchScreen(),
    const PostScreen(),
    const NewsScreen(),
    const ProfileScreen(),
  ];

  void _onTap(int index) {
    if (_currentIndex == index) {
      // If already on tab, pop to first route
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, _) {
        final profilePicUrl = profileViewModel.profilePictureUrl;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(_screens.length, (index) {
              return Navigator(
                key: _navigatorKeys[index],
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (_) => _screens[index],
                  );
                },
              );
            }),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.shifting,
            selectedItemColor: kPrimaryAccent,
            unselectedItemColor: Colors.grey,
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Colors.white,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
                backgroundColor: Colors.white,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_a_photo),
                label: 'Post',
                backgroundColor: Colors.white,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.newspaper),
                label: 'News',
                backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
                icon: CircleAvatar(
                  radius: 12,
                  backgroundImage: profilePicUrl.startsWith('http')
                      ? NetworkImage(profilePicUrl)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                label: 'Profile',
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

}


