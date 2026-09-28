import 'package:flutter/material.dart';

import '../services/pinyin_service.dart';

class ChineseText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextStyle? pinyinStyle;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  const ChineseText({
    super.key,
    required this.text,
    this.textStyle,
    this.pinyinStyle,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  void _showPinyinPopup(BuildContext context) {
    final pinyin = PinyinService.getPinyin(text);

    if (pinyin.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 340,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle ??
                      const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  pinyin,
                  textAlign: TextAlign.center,
                  style: pinyinStyle ??
                      TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        _showPinyinPopup(context);
      },
      child: Text(
        text,
        textAlign: textAlign,
        softWrap: true,
        style: textStyle,
      ),
    );
  }
}