// バリデーション関連のユーティリティ
import 'dart:core';

class ValidationUtils {
  // メールアドレスの妥当性をチェック
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // パスワードの強度をチェック
  static Map<String, dynamic> validatePassword(String password) {
    final result = {
      'isValid': false,
      'score': 0,
      'messages': <String>[],
    };

    if (password.isEmpty) {
      result['messages'].add('パスワードを入力してください');
      return result;
    }

    int score = 0;
    final messages = <String>[];

    // 長さチェック
    if (password.length >= 8) {
      score += 20;
    } else {
      messages.add('8文字以上で入力してください');
    }

    // 大文字チェック
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 20;
    } else {
      messages.add('大文字を含めてください');
    }

    // 小文字チェック
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 20;
    } else {
      messages.add('小文字を含めてください');
    }

    // 数字チェック
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 20;
    } else {
      messages.add('数字を含めてください');
    }

    // 記号チェック
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 20;
    } else {
      messages.add('記号を含めてください');
    }

    result['score'] = score;
    result['isValid'] = score >= 60;
    result['messages'] = messages;

    return result;
  }

  // 電話番号の妥当性をチェック（日本の電話番号）
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(
      r'^(\+81|0)[0-9]{1,4}-?[0-9]{1,4}-?[0-9]{3,4}$',
    );
    return phoneRegex.hasMatch(phoneNumber.replaceAll(' ', ''));
  }

  // 郵便番号の妥当性をチェック（日本の郵便番号）
  static bool isValidPostalCode(String postalCode) {
    final postalRegex = RegExp(r'^\d{3}-?\d{4}$');
    return postalRegex.hasMatch(postalCode);
  }

  // URLの妥当性をチェック
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // 日本語の名前の妥当性をチェック
  static bool isValidJapaneseName(String name) {
    if (name.isEmpty || name.length > 50) return false;
    
    // ひらがな、カタカナ、漢字、英字のみ許可
    final nameRegex = RegExp(r'^[ひらがなカタカナ漢字a-zA-Z\s]+$');
    return nameRegex.hasMatch(name);
  }

  // 数値の範囲チェック
  static bool isInRange(num value, num min, num max) {
    return value >= min && value <= max;
  }

  // 文字列の長さチェック
  static bool isValidLength(String text, int minLength, int maxLength) {
    return text.length >= minLength && text.length <= maxLength;
  }

  // 必須フィールドのチェック
  static bool isRequired(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  // クレジットカード番号の妥当性をチェック（Luhnアルゴリズム）
  static bool isValidCreditCard(String cardNumber) {
    // 数字以外を除去
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhnアルゴリズム
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  // 年齢の妥当性をチェック
  static bool isValidAge(int age, {int minAge = 0, int maxAge = 150}) {
    return age >= minAge && age <= maxAge;
  }

  // 日付の妥当性をチェック
  static bool isValidDate(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 未来の日付かどうかをチェック
  static bool isFutureDate(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // 過去の日付かどうかをチェック
  static bool isPastDate(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // カタカナのみかどうかをチェック
  static bool isKatakanaOnly(String text) {
    final katakanaRegex = RegExp(r'^[ァ-ヶー\s]+$');
    return katakanaRegex.hasMatch(text);
  }

  // ひらがなのみかどうかをチェック
  static bool isHiraganaOnly(String text) {
    final hiraganaRegex = RegExp(r'^[あ-ん\s]+$');
    return hiraganaRegex.hasMatch(text);
  }

  // 漢字が含まれているかをチェック
  static bool containsKanji(String text) {
    final kanjiRegex = RegExp(r'[一-龯]');
    return kanjiRegex.hasMatch(text);
  }

  // 英数字のみかどうかをチェック
  static bool isAlphanumeric(String text) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(text);
  }

  // 数字のみかどうかをチェック
  static bool isNumericOnly(String text) {
    final numericRegex = RegExp(r'^[0-9]+$');
    return numericRegex.hasMatch(text);
  }

  // HTMLタグが含まれているかをチェック
  static bool containsHtmlTags(String text) {
    final htmlRegex = RegExp(r'<[^>]*>');
    return htmlRegex.hasMatch(text);
  }

  // SQLインジェクションの危険な文字列をチェック
  static bool containsDangerousChars(String text) {
    final dangerousPatterns = [
      RegExp(r"'"),
      RegExp(r'"'),
      RegExp(r'--'),
      RegExp(r'/\*'),
      RegExp(r'\*/'),
      RegExp(r'xp_'),
      RegExp(r'sp_'),
      RegExp(r'union', caseSensitive: false),
      RegExp(r'select', caseSensitive: false),
      RegExp(r'insert', caseSensitive: false),
      RegExp(r'delete', caseSensitive: false),
      RegExp(r'update', caseSensitive: false),
      RegExp(r'drop', caseSensitive: false),
    ];

    return dangerousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  // ファイルサイズの妥当性をチェック（バイト単位）
  static bool isValidFileSize(int fileSizeBytes, int maxSizeBytes) {
    return fileSizeBytes > 0 && fileSizeBytes <= maxSizeBytes;
  }

  // ファイル拡張子の妥当性をチェック
  static bool isValidFileExtension(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.map((e) => e.toLowerCase()).contains(extension);
  }

  // IPアドレスの妥当性をチェック
  static bool isValidIpAddress(String ipAddress) {
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ipAddress);
  }

  // バリデーション結果のヘルパークラス
  static String getValidationMessage(String fieldName, String validationType) {
    final messages = {
      'required': '$fieldNameは必須です',
      'email': '正しいメールアドレスを入力してください',
      'phone': '正しい電話番号を入力してください',
      'postal': '正しい郵便番号を入力してください（例：123-4567）',
      'url': '正しいURLを入力してください',
      'password_weak': 'より強いパスワードを設定してください',
      'too_short': '$fieldNameが短すぎます',
      'too_long': '$fieldNameが長すぎます',
      'invalid_format': '$fieldNameの形式が正しくありません',
      'future_date_required': '未来の日付を選択してください',
      'past_date_required': '過去の日付を選択してください',
    };

    return messages[validationType] ?? '$fieldNameが無効です';
  }
}
