import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

class MediaGallery extends StatelessWidget {
  final List<dynamic> mediaItems;
  final bool loadingMedia;
  final String? mediaError;
  final VoidCallback onRetry;

  const MediaGallery({
    super.key,
    required this.mediaItems,
    required this.loadingMedia,
    this.mediaError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaError != null) {
      return AppError(message: mediaError!, onRetry: onRetry);
    }
    if (loadingMedia) {
      return const AppSkeleton(height: 200);
    }
    if (mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayItems = mediaItems.where((item) {
      final type = item['type'] as String?;
      final srcset = item['srcset'] as List<dynamic>?;
      return (type == 'image' || type == 'video') && srcset != null && srcset.isNotEmpty;
    }).toList();

    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Media Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final srcset = item['srcset'] as List<dynamic>;
              final src = srcset.isNotEmpty ? (srcset[0]['src'] as String?) : null;
              final title = item['title'] as String?;
              final type = item['type'] as String?;

              if (src == null) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse('https:$src')); 
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: 'https:$src',  
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => SizedBox(
                          width: 150,
                          height: 150,
                          child: const AppSkeleton(),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                      if (type == 'video')
                        const Icon(Icons.play_circle_outline, size: 50, color: Colors.white),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(4),
                          child: Text(title ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RelatedArticles extends StatelessWidget {
  final List<dynamic> relatedArticles;
  final bool loadingRelated;
  final String? relatedError;
  final void Function(String title) onArticleTap;
  final VoidCallback onRetry;

  const RelatedArticles({
    super.key,
    required this.relatedArticles,
    required this.loadingRelated,
    this.relatedError,
    required this.onArticleTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (relatedError != null) {
      return AppError(message: relatedError!, onRetry: onRetry);
    }
    if (loadingRelated) {
      return const AppSkeleton(height: 200);
    }
    if (relatedArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Related Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedArticles.length,
          itemBuilder: (context, index) {
            final article = relatedArticles[index];
            final title = article['title'] as String?;
            final desc = article['extract'] as String?;
            final thumb = article['thumbnail']?['source'] as String?;

            return ListTile(
              leading: thumb != null
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => SizedBox(
                        width: 56,
                        height: 56,
                        child: const AppSkeleton(),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.article),
                    )
                  : const Icon(Icons.article),
              title: Text(title ?? ''),
              subtitle: desc != null ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
              onTap: () {
                if (title != null) {
                  onArticleTap(title);
                }
              },
            );
          },
        ),
      ],
    );
  }
}