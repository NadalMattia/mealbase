import 'package:flutter/material.dart';
import '../utils/app_snackbar.dart';

/// Profilo utente. Le voci non ancora disponibili si limitano a segnalarlo
/// tramite snackbar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Il Tuo Profilo',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.person,
                      size: 50, color: Colors.grey.shade400),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'NOME UTENTE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'utente@example.com',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          _ProfileTile(
            icon: Icons.person_outline,
            label: 'Dati personali',
            onTap: () => AppSnackbar.showComingSoon(context, 'Dati personali'),
          ),
          _ProfileTile(
            icon: Icons.home_outlined,
            label: 'Gestione case',
            onTap: () => AppSnackbar.showComingSoon(context, 'Gestione case'),
          ),
          _ProfileTile(
            icon: Icons.notifications_none,
            label: 'Notifiche',
            onTap: () => AppSnackbar.showComingSoon(context, 'Notifiche'),
          ),
          _ProfileTile(
            icon: Icons.shield_outlined,
            label: 'Privacy e sicurezza',
            onTap: () => AppSnackbar.showComingSoon(context, 'Privacy e sicurezza'),
          ),
          _ProfileTile(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => AppSnackbar.showComingSoon(context, 'Logout'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.grey.shade500, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}