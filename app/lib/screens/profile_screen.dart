import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../widgets/mohana_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MohanaAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: MohanaSpacing.xxl),
            const _AvatarSection(),
            const SizedBox(height: MohanaSpacing.lg),
            const _UserInfoSection(),
            const SizedBox(height: MohanaSpacing.base),
            const _InterestTags(),
            const SizedBox(height: MohanaSpacing.sectionGap),
            _ConfigSection(
              darkMode: ThemeController.isDark,
              onDarkModeChanged: (_) {
                ThemeController.toggle();
                setState(() {});
              },
            ),
            const SizedBox(height: MohanaSpacing.xl),
            const _SupportSection(),
            const SizedBox(height: MohanaSpacing.xl),
            const _SocialLinksSection(),
            const SizedBox(height: MohanaSpacing.xxl),
            const _LogoutButton(),
            const SizedBox(height: MohanaSpacing.lg),
            const _FooterText(),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // Gradient ring
          Container(
            width: 110,
            height: 110,
            decoration: MohanaDecorations.avatarRing,
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: MohanaColors.surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: MohanaColors.primary50,
                child: Icon(
                  Icons.person_outline,
                  size: 50,
                  color: MohanaColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          // Edit badge
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: MohanaColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                size: 14,
                color: MohanaColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Elena Ramírez',
          style: GoogleFonts.breeSerif(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: MohanaColors.onSurface,
          ),
        ),
        const SizedBox(height: MohanaSpacing.xs),
        Text(
          'elena.community@lamohana.org',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: MohanaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InterestTags extends StatelessWidget {
  const _InterestTags();

  @override
  Widget build(BuildContext context) {
    const tags = ['#MUJERES', '#CULTURA', '#RADIOVIVA'];

    return Wrap(
      spacing: MohanaSpacing.sm,
      children: tags
          .map((tag) => Chip(
                label: Text(tag),
                backgroundColor: MohanaColors.primary,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MohanaColors.onPrimary,
                  letterSpacing: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: MohanaRadius.smAll,
                  side: BorderSide.none,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: MohanaSpacing.xs),
              ))
          .toList(),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const _ConfigSection({
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MohanaColors.primary,
            ),
          ),
          const SizedBox(height: MohanaSpacing.md),
          Container(
            decoration: MohanaDecorations.card,
            child: Column(
              children: [
                _ConfigTile(
                  icon: Icons.person_outline,
                  title: 'Editar Perfil',
                  trailing: const Icon(Icons.chevron_right,
                      color: MohanaColors.onSurfaceVariant),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _ConfigTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Activas',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: MohanaSpacing.xs),
                      const Icon(Icons.chevron_right,
                          color: MohanaColors.onSurfaceVariant),
                    ],
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _ConfigTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        darkMode ? 'Oscuro' : 'Claro',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: MohanaSpacing.xs),
                      Switch(
                        value: darkMode,
                        onChanged: onDarkModeChanged,
                        activeTrackColor: MohanaColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ConfigTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MohanaRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MohanaSpacing.base,
          vertical: MohanaSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MohanaColors.primary50,
                borderRadius: MohanaRadius.mdAll,
              ),
              child: Icon(icon, color: MohanaColors.primary, size: 20),
            ),
            const SizedBox(width: MohanaSpacing.md),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: MohanaColors.onSurface,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soporte',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MohanaColors.primary,
            ),
          ),
          const SizedBox(height: MohanaSpacing.md),
          Container(
            decoration: MohanaDecorations.card,
            child: _ConfigTile(
              icon: Icons.help_outline,
              title: 'Centro de Ayuda',
              trailing: const Icon(Icons.chevron_right,
                  color: MohanaColors.onSurfaceVariant),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar Sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MohanaColors.primary,
            side: const BorderSide(color: MohanaColors.secondary),
            backgroundColor: MohanaColors.secondary50,
            padding: const EdgeInsets.symmetric(vertical: MohanaSpacing.base),
          ),
        ),
      ),
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  const _SocialLinksSection();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redes Sociales',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MohanaColors.primary,
            ),
          ),
          const SizedBox(height: MohanaSpacing.md),
          Container(
            decoration: MohanaDecorations.card,
            child: Column(
              children: [
                _ConfigTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Instagram',
                  trailing: const Icon(Icons.chevron_right,
                      color: MohanaColors.onSurfaceVariant),
                  onTap: () => _openUrl(
                      'https://www.instagram.com/emisoralamohana/'),
                ),
                const Divider(height: 1, indent: 56),
                _ConfigTile(
                  icon: Icons.facebook,
                  title: 'Facebook',
                  trailing: const Icon(Icons.chevron_right,
                      color: MohanaColors.onSurfaceVariant),
                  onTap: () => _openUrl(
                      'https://www.facebook.com/p/Emisora-la-Mohana-100090784130166/'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_ofp.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: MohanaSpacing.md),
        Text(
          'LA MOHANA DIGITAL V2.4.0',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MohanaColors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: MohanaSpacing.xxs),
        Text(
          'Orgullosamente Comunitaria',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: MohanaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
