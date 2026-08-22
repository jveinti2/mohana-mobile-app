import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/drive_config.dart';
import '../config/theme.dart';
import '../models/news_article.dart';
import '../services/content_service.dart';
import '../widgets/article_list_card.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/load_notice.dart';
import 'article_detail_screen.dart';

/// Todas las publicaciones de la emisora, de la más reciente a la más antigua.
///
/// El home muestra el titular y las últimas; aquí está el listado completo.
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<NewsArticle> _articles = const [];
  bool _loading = true;
  bool _failed = false;

  /// IDs ya animados, para no repetir la entrada al volver a la pestaña.
  final Set<String> _seenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (!DriveConfig.isConfigured) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    setState(() {
      _loading = _articles.isEmpty;
      _failed = false;
    });
    try {
      // Comparte caché con el home: cambiar de pestaña no vuelve a descargar.
      final content = await ContentService.loadHomeContent(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _articles = [
          if (content.titular != null) content.titular!,
          ...content.articulos,
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MohanaGradients.homeTonal),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Publicaciones',
            style: GoogleFonts.breeSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
            ),
          ),
        ),
        body: _loading ? const FeedSkeleton() : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: MohanaColors.primary,
      onRefresh: () => _load(force: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.sm)),

          if (_failed)
            SliverToBoxAdapter(
              child: LoadNotice(
                message: 'No se pudieron cargar las publicaciones',
                detail: 'Desliza hacia abajo para reintentar.',
                onRetry: () => _load(force: true),
              ),
            )
          else if (_articles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Todavía no hay publicaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MohanaColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: _articles.length,
              itemBuilder: (_, index) {
                final article = _articles[index];
                final firstSeen = _seenIds.add(article.id);
                return StaggeredEntrance(
                  index: index,
                  animate: firstSeen,
                  child: PressableScale(
                    onTap: () => _openArticle(article),
                    child: ArticleListCard(article: article),
                  ),
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MohanaSpacing.base),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xxl)),
        ],
      ),
    );
  }
}
