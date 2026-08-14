import 'package:flutter/material.dart';
import '../config/theme.dart';

class MohanaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MohanaAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/images/logo_emisora.png',
        height: 36,
        fit: BoxFit.contain,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: MohanaSpacing.base),
          child: Center(
            child: Image.asset(
              'assets/images/logo_ofp.jpeg',
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
