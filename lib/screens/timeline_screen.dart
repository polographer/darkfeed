import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/timeline_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/platform_utils.dart';

/// Full-screen timeline screen with TikTok/Reels-style navigation
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late PageController _pageController;
  bool _showOverlay = false; // Start with overlay hidden for clean view
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Load timeline posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimelineProvider>().loadTimeline();
    });

    // Request focus for keyboard navigation on desktop
    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    debugPrint('TimelineScreen: Toggle overlay called');
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  void _nextPost() {
    final timelineProvider = context.read<TimelineProvider>();
    if (_pageController.hasClients) {
      final nextIndex = timelineProvider.currentIndex + 1;
      if (nextIndex < timelineProvider.posts.length) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPost() {
    if (_pageController.hasClients) {
      final currentIndex = context.read<TimelineProvider>().currentIndex;
      if (currentIndex > 0) {
        _pageController.animateToPage(
          currentIndex - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    debugPrint('TimelineScreen: Logout button pressed');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final timelineProvider = context.read<TimelineProvider>();
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _nextPost();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _previousPost();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              timelineProvider.nextImage();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              timelineProvider.previousImage();
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              _toggleOverlay();
            }
          }
        },
        child: Consumer<TimelineProvider>(
          builder: (context, timelineProvider, child) {
            if (timelineProvider.isLoading && timelineProvider.posts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            if (timelineProvider.error != null &&
                timelineProvider.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load timeline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timelineProvider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => timelineProvider.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (timelineProvider.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts to show',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow some accounts to see their posts here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Main timeline view
            return Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final currentPost = timelineProvider.currentPost;
                  if (currentPost == null) return;

                  // Only handle scroll for multi-image posts
                  if (currentPost.mediaAttachments.length > 1) {
                    // Scroll down (positive delta) - next image
                    if (event.scrollDelta.dy > 0) {
                      // If at last image, allow post navigation
                      if (timelineProvider.currentImageIndex <
                          currentPost.mediaAttachments.length - 1) {
                        timelineProvider.nextImage();
                      } else {
                        _nextPost();
                      }
                    }
                    // Scroll up (negative delta) - previous image
                    else if (event.scrollDelta.dy < 0) {
                      // If at first image, allow post navigation
                      if (timelineProvider.currentImageIndex > 0) {
                        timelineProvider.previousImage();
                      } else {
                        _previousPost();
                      }
                    }
                  }
                  // Single image posts - normal post navigation
                  else {
                    if (event.scrollDelta.dy > 0) {
                      _nextPost();
                    } else if (event.scrollDelta.dy < 0) {
                      _previousPost();
                    }
                  }
                }
              },
              child: Stack(
                children: [
                  // PageView for posts
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: timelineProvider.posts.length,
                    onPageChanged: (index) {
                      timelineProvider.setCurrentIndex(index);
                    },
                    itemBuilder: (context, index) {
                      final post = timelineProvider.posts[index];
                      // Use current image index for the current post, otherwise show first image
                      final isCurrentPost =
                          index == timelineProvider.currentIndex;
                      final imageIndex = isCurrentPost
                          ? timelineProvider.currentImageIndex
                          : 0;
                      final imageUrl = post.mediaAttachments[imageIndex].url;

                      return GestureDetector(
                        onTap: _toggleOverlay,
                        onHorizontalDragEnd: (details) {
                          // Only handle swipes for current post
                          if (index == timelineProvider.currentIndex) {
                            // Swipe left (next image) - velocity is negative
                            if (details.primaryVelocity != null &&
                                details.primaryVelocity! < -500) {
                              timelineProvider.nextImage();
                            }
                            // Swipe right (previous image) - velocity is positive
                            else if (details.primaryVelocity != null &&
                                details.primaryVelocity! > 500) {
                              timelineProvider.previousImage();
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              color: AppColors.backgroundColor,
                              child: Center(
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: AppColors.errorColor,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            // Multiple images indicator (dots)
                            if (post.mediaAttachments.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        post.mediaAttachments.length,
                                        (dotIndex) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: dotIndex == imageIndex
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.4,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Desktop navigation arrows
                  if (isDesktop) ...[
                    // Top navigation (previous post)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _previousPost,
                          child: Container(
                            color: Colors.transparent,
                            child: _showOverlay
                                ? const Center(
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // Bottom navigation (next post)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _nextPost,
                          child: Container(
                            color: Colors.transparent,
                            child: _showOverlay
                                ? const Center(
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // Left navigation (previous image)
                    Consumer<TimelineProvider>(
                      builder: (context, provider, child) {
                        final currentPost = provider.currentPost;
                        final hasMultipleImages =
                            currentPost != null &&
                            currentPost.mediaAttachments.length > 1;
                        final canGoPrevious = provider.currentImageIndex > 0;

                        if (!hasMultipleImages) return const SizedBox();

                        return Positioned(
                          left: 0,
                          top: 100,
                          bottom: 100,
                          width: 100,
                          child: MouseRegion(
                            cursor: canGoPrevious
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: canGoPrevious
                                  ? () => provider.previousImage()
                                  : null,
                              child: Container(
                                color: Colors.transparent,
                                child: _showOverlay && canGoPrevious
                                    ? const Center(
                                        child: Icon(
                                          Icons.keyboard_arrow_left,
                                          size: 48,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Right navigation (next image)
                    Consumer<TimelineProvider>(
                      builder: (context, provider, child) {
                        final currentPost = provider.currentPost;
                        final hasMultipleImages =
                            currentPost != null &&
                            currentPost.mediaAttachments.length > 1;
                        final canGoNext =
                            currentPost != null &&
                            provider.currentImageIndex <
                                currentPost.mediaAttachments.length - 1;

                        if (!hasMultipleImages) return const SizedBox();

                        return Positioned(
                          right: 0,
                          top: 100,
                          bottom: 100,
                          width: 100,
                          child: MouseRegion(
                            cursor: canGoNext
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: canGoNext
                                  ? () => provider.nextImage()
                                  : null,
                              child: Container(
                                color: Colors.transparent,
                                child: _showOverlay && canGoNext
                                    ? const Center(
                                        child: Icon(
                                          Icons.keyboard_arrow_right,
                                          size: 48,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Overlay with post info and actions
                  if (_showOverlay)
                    Positioned.fill(
                      child: GestureDetector(
                        // Tapping on empty areas hides the overlay
                        onTap: _toggleOverlay,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              stops: const [0.0, 0.3, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              children: [
                                // Top bar with logout - prevent tap-through
                                GestureDetector(
                                  onTap: () {
                                    // Absorb taps on top bar
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          appName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.logout,
                                            color: Colors.white,
                                          ),
                                          onPressed: _handleLogout,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Bottom bar with post info and actions - prevent tap-through
                                Consumer<TimelineProvider>(
                                  builder: (context, provider, child) {
                                    final currentPost = provider.currentPost;
                                    if (currentPost == null) {
                                      return const SizedBox();
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        // Absorb taps on bottom bar
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // User info
                                            Row(
                                              children: [
                                                if (currentPost.accountAvatar !=
                                                    null)
                                                  CircleAvatar(
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                          currentPost
                                                              .accountAvatar!,
                                                        ),
                                                    radius: 20,
                                                  )
                                                else
                                                  const CircleAvatar(
                                                    radius: 20,
                                                    child: Icon(Icons.person),
                                                  ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        currentPost
                                                            .accountDisplayName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        '@${currentPost.accountUsername}',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Repost button
                                                IconButton(
                                                  icon: Icon(
                                                    currentPost.reblogged ==
                                                            true
                                                        ? Icons.repeat
                                                        : Icons.repeat,
                                                    color:
                                                        currentPost.reblogged ==
                                                            true
                                                        ? Colors.green
                                                        : Colors.white,
                                                    size: 28,
                                                  ),
                                                  onPressed: () =>
                                                      provider.toggleRepost(),
                                                ),
                                                // Like button
                                                IconButton(
                                                  icon: Icon(
                                                    currentPost.favourited ==
                                                            true
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color:
                                                        currentPost
                                                                .favourited ==
                                                            true
                                                        ? AppColors.likeColor
                                                        : Colors.white,
                                                    size: 28,
                                                  ),
                                                  onPressed: () =>
                                                      provider.toggleLike(),
                                                ),
                                              ],
                                            ),

                                            // Caption
                                            if (currentPost.content != null &&
                                                currentPost
                                                    .content!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                _stripHtmlTags(
                                                  currentPost.content!,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],

                                            // Stats
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  '${currentPost.favouritesCount} likes • ${currentPost.reblogsCount} reposts',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                // Multi-image indicator
                                                if (currentPost
                                                        .mediaAttachments
                                                        .length >
                                                    1) ...[
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${provider.currentImageIndex + 1}/${currentPost.mediaAttachments.length}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Loading more indicator
                  Consumer<TimelineProvider>(
                    builder: (context, provider, child) {
                      if (!provider.isLoadingMore) return const SizedBox();

                      return Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading more...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper to strip HTML tags from content
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
