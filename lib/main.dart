// main.dart
import 'package:the_shot2/services/news_service.dart';
import 'package:the_shot2/services/settings_service.dart';
import 'package:the_shot2/services/sport_services/football_service.dart';
import 'package:the_shot2/viewmodels/news_viewmodel.dart';
import 'package:the_shot2/viewmodels/post_actions_viewmodel.dart';
import 'package:the_shot2/viewmodels/post_detail_viewmodel.dart';
import 'package:the_shot2/viewmodels/post_interaction_viewmodel.dart';
import 'package:the_shot2/viewmodels/saved_post_viewmodel.dart';
import 'package:the_shot2/viewmodels/settings_viewmodel.dart';
import 'package:the_shot2/views/email_verification_screen.dart';
import 'package:the_shot2/views/signup_screen.dart';
import 'components/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/services/api_service.dart';
import 'package:the_shot2/viewmodels/camera_viewmodel.dart';
import 'package:the_shot2/viewmodels/edit_profile_viewmodel.dart';
import 'package:the_shot2/viewmodels/message_list_viewmodel.dart';
import 'package:the_shot2/viewmodels/profile_viewmodel.dart';
import 'package:the_shot2/viewmodels/search_viewmodel.dart';
import 'package:the_shot2/views/bnb.dart';
import 'package:the_shot2/views/home_screen.dart';
import 'package:the_shot2/views/login_screen.dart';
import 'package:the_shot2/views/search_screen.dart';
import 'viewmodels/create_post_viewmodel.dart';
import 'viewmodels/captured_photo_viewmodel.dart';
import 'viewmodels/post_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const TheShot());
}

class TheShot extends StatelessWidget {
  const TheShot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (context) => HomeViewModel()),
        ChangeNotifierProvider(create: (context) => PostViewModel()),
        ChangeNotifierProvider(create: (context) => CreatePostViewModel()), //Add back
        ChangeNotifierProvider(create: (context) => CapturedPhotoViewModel()), //Add back
        ChangeNotifierProvider(create: (context) => CameraViewModel()),
        ChangeNotifierProvider(create: (context) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => EditProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel(apiService: ApiService()), child: const SearchScreen(),),
        ChangeNotifierProvider(create: (_) => MessageListViewModel()..loadChats(), child: HomeScreen(),),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(settingsService: SettingsService(),)),
        Provider<NewsService>(create: (_) => NewsService()),
        Provider<FootballService>(create: (_) => FootballService()),
        ChangeNotifierProvider(create: (context) => NewsViewModel(newsService: context.read<NewsService>()),),
        ChangeNotifierProvider(create: (_) => PostInteractionViewModel()),
        ChangeNotifierProvider(create: (_) => PostDetailViewModel()),
        ChangeNotifierProvider(create: (_) => SavedPostsViewModel()),
        ChangeNotifierProvider(create: (_) => PostActionsViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsViewModel, child) {
          return MaterialApp(
            title: 'The Shot',
            theme: settingsViewModel.themePreference == 'dark'
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: Login(),
            routes: {
              '/login': (_) => Login(),
              '/signup': (_) => const Signup(),
              '/home': (_) => const BottomNavBar(),
              '/email_verification': (_) => const EmailVerificationScreen(),
            },
          );
        },
      ),
    );
  }
}
