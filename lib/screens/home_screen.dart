import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/expense_service.dart';
import '../widgets/preview_expense_dialog.dart';
import 'categories_screen.dart';
import 'feed_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _expenseService = ExpenseService();

  int _currentTabIndex = 0; // 0: Camera, 1: Feed, 2: Thống kê, 3: Danh mục
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  Future<void> _captureOrPickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null && mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PreviewExpenseDialog(photoPath: pickedFile.path),
          ),
        );

        if (result == true && mounted) {
          setState(() => _currentTabIndex = 1);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMockPhotoOptions();
      }
    }
  }

  void _showMockPhotoOptions() {
    final samplePhotos = [
      {
        'title': 'Cà phê & Bánh ngọt',
        'url': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600',
        'desc': 'Ảnh ly cà phê sáng',
      },
      {
        'title': 'Bữa trưa / Ăn uống',
        'url': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
        'desc': 'Tô phở / cơm trưa',
      },
      {
        'title': 'Hoá đơn siêu thị',
        'url': 'https://images.unsplash.com/photo-1580828343064-fde4fc206bc6?w=600',
        'desc': 'Bill mua sắm đồ ăn',
      },
      {
        'title': 'Quần áo / Mua sắm',
        'url': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=600',
        'desc': 'Trang phục mới',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF19191D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chọn mẫu chi tiêu để trải nghiệm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in samplePhotos)
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item['url']!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    item['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item['desc']!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PreviewExpenseDialog(photoPath: item['url']!),
                          ),
                        )
                        .then((res) {
                          if (res == true && mounted) {
                            setState(() => _currentTabIndex = 1);
                          }
                        });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildCameraTab(),
          FeedScreen(onOpenSnap: () => setState(() => _currentTabIndex = 0)),
          const StatsScreen(),
          const CategoriesScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFD233),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt_rounded),
              label: 'Chụp ảnh',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library_rounded),
              label: 'Feed bạn bè',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded),
              label: 'Thống kê',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category_rounded),
              label: 'Danh mục',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraTab() {
    final latestTx = _expenseService.transactions.isNotEmpty
        ? _expenseService.transactions.first
        : null;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxVfSize = math.min(
            constraints.maxWidth - 40,
            constraints.maxHeight - 200,
          );
          final viewfinderSize = math.max(120.0, math.min(maxVfSize, 360.0));

          return Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Avatar button
                    GestureDetector(
                      key: const ValueKey('openCategoriesFromHome'),
                      onTap: () => setState(() => _currentTabIndex = 3),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A30),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD233),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          _expenseService.currentUserAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Audience selector (Locket style)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Color(0xFFFFD233),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bạn bè (${_expenseService.friends.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats shortcut button
                    IconButton(
                      key: const ValueKey('openStatsFromHome'),
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => setState(() => _currentTabIndex = 2),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Locket Viewfinder (Centered 1:1 Rounded Square)
              Center(
                child: Container(
                  width: viewfinderSize,
                  height: viewfinderSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF19191D),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera viewfinder representation
                      Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Color(0xFF232329), Color(0xFF121215)],
                            radius: 0.9,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_rounded,
                                size: 56,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chụp món đồ bạn vừa chi tiêu',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top controls overlay (Flash & Flip)
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: _isFlashOn
                                    ? const Color(0xFFFFD233)
                                    : Colors.white70,
                              ),
                              onPressed: () =>
                                  setState(() => _isFlashOn = !_isFlashOn),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white70,
                              ),
                              onPressed: () => setState(
                                () => _isFrontCamera = !_isFrontCamera,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prompt banner at bottom of viewfinder
                      Positioned(
                        bottom: 14,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                color: Color(0xFFFFD233),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chụp hoá đơn, ly nước, món ăn để ghi sổ...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Bottom Control Bar (Gallery Button, Big Shutter, Feed Thumbnail)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pick from Gallery / Mock
                    IconButton(
                      key: const ValueKey('galleryButton'),
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => _captureOrPickImage(ImageSource.gallery),
                    ),

                    // Big Locket Shutter Button
                    GestureDetector(
                      key: const ValueKey('shutterButton'),
                      onTap: () => _captureOrPickImage(ImageSource.camera),
                      child: Container(
                        width: 74,
                        height: 74,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD233),
                            width: 3.5,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Feed Thumbnail Button
                    GestureDetector(
                      key: const ValueKey('feedThumbnailButton'),
                      onTap: () => setState(() => _currentTabIndex = 1),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            latestTx?.photoPath != null &&
                                latestTx!.photoPath!.startsWith('http')
                            ? Image.network(
                                latestTx.photoPath!,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.view_carousel_rounded,
                                  color: Colors.white54,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }
}
