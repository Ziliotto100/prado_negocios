import 'package:flutter/material.dart';
import '../screens/banned_users_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/featured_ads_screen.dart'; // <-- NOVO
import '../screens/my_ads_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Prado Negócios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            text: 'Meu Perfil',
            onTap: () {
              if (currentUser != null) {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(userId: currentUser.uid),
                  ),
                );
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.inventory_2_outlined,
            text: 'Meus Anúncios',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyAdsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.favorite_border,
            text: 'Meus Favoritos',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.chat_bubble_outline,
            text: 'Minhas Conversas',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          const Divider(),
          FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.push_pin_outlined, // <-- NOVO
                      text: 'Gerir Fixados',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const FeaturedAdsScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.security,
                      text: 'Gerir Banidos',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const BannedUsersScreen()),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Sair',
            onTap: () async {
              Navigator.of(context).pop();
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }
}
