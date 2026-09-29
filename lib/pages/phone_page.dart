import 'package:flutter/material.dart';

import '../models/customer_review.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class PhonePage extends StatelessWidget {
  final GameState gameState;
  final SaveService saveService;

  const PhonePage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF3),
      appBar: AppBar(
        title: const ChineseText(
          text: '📱 手机',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: const Color(0xFFF7F8FA),
              child: Column(
                children: [
                  _buildPhoneHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _buildRatingCard(context),
                          const SizedBox(height: 18),
                          _buildAppGrid(context),
                          const SizedBox(height: 20),
                          _buildHomeIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneHeader() {
    return Container(
      height: 34,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text(
        '9:41',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    final rating = gameState.shopRatingTenths / 10.0;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ReviewsPage(
              gameState: gameState,
            ),
          ),
        );
      },
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFB74D),
              Color(0xFFFF9800),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              '🏪',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 4),
            const ChineseText(
              text: '超市评价',
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '★★★★★',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 27,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ChineseText(
              text: '${gameState.reviewCount} 条评价',
              textStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 14,
      mainAxisSpacing: 18,
      childAspectRatio: 0.9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildApp(
          context,
          icon: '🏪',
          title: '评价',
          color: const Color(0xFFFFE0B2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ReviewsPage(
                  gameState: gameState,
                ),
              ),
            );
          },
        ),
        _buildComingSoonApp(
          icon: '📦',
          title: '采购',
          color: const Color(0xFFE3F2FD),
        ),
        _buildComingSoonApp(
          icon: '📈',
          title: '股票',
          color: const Color(0xFFE8F5E9),
        ),
        _buildComingSoonApp(
          icon: '🪙',
          title: '黄金',
          color: const Color(0xFFFFF3CD),
        ),
        _buildComingSoonApp(
          icon: '📰',
          title: '新闻',
          color: const Color(0xFFF3E5F5),
        ),
        _buildComingSoonApp(
          icon: '💬',
          title: '消息',
          color: const Color(0xFFE0F7FA),
        ),
      ],
    );
  }

  Widget _buildApp(
      BuildContext context, {
        required String icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 7),
              ChineseText(
                text: title,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonApp({
    required String icon,
    required String title,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 7),
                ChineseText(
                  text: title,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 7,
            top: 7,
            child: Text(
              '🔒',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      width: 90,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _ReviewsPage extends StatelessWidget {
  final GameState gameState;

  const _ReviewsPage({
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '🏪 客户评价',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: gameState.customerReviews.isEmpty
          ? const Center(
        child: ChineseText(
          text: '还没有客户评价。',
          textStyle: TextStyle(
            fontSize: 17,
            color: Colors.black54,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gameState.customerReviews.length,
        itemBuilder: (context, index) {
          final review =
          gameState.customerReviews[index];

          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(CustomerReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChineseText(
                    text: '第 ${review.day} 天',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              review.stars,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            ChineseText(
              text: review.comment,
              textStyle: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ChineseText(
              text:
              '服务 ${review.servedCustomers} 人 · 跳过 ${review.skippedCustomers} 人',
              textStyle: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}