import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/menu/presentation/main_menu_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
import '../features/achievements/presentation/achievements_screen.dart';
import '../features/game/presentation/game_play_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GamePlayScreen(),
    ),
  ],
);
