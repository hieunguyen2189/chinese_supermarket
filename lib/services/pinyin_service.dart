import 'package:pinyin/pinyin.dart';

class PinyinService {
  PinyinService._();

  static String getPinyin(String text) {
    if (text.trim().isEmpty) {
      return '';
    }

    try {
      return PinyinHelper.getPinyin(
        text,
        separator: ' ',
        format: PinyinFormat.WITH_TONE_MARK,
      );
    } catch (_) {
      return '';
    }
  }

  static bool containsChinese(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x4E00 && rune <= 0x9FFF) {
        return true;
      }
    }

    return false;
  }
}