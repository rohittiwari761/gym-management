/// HTML decoding utility for handling HTML entities in text
class HtmlDecoder {
  /// Map of common HTML entities to their decoded characters
  static const Map<String, String> _htmlEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&#x27;': "'",
    '&#39;': "'",
    '&nbsp;': ' ',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
  };

  /// Decode HTML entities in a string
  static String decode(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }

    String decoded = text;
    
    // Replace each HTML entity with its decoded character
    _htmlEntities.forEach((entity, character) {
      decoded = decoded.replaceAll(entity, character);
    });

    // Handle numeric HTML entities like &#123; and &#x1F;
    decoded = decoded.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final code = int.tryParse(match.group(1)!);
        if (code != null) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    // Handle hexadecimal HTML entities like &#x1F;
    decoded = decoded.replaceAllMapped(
      RegExp(r'&#x([0-9A-Fa-f]+);'),
      (match) {
        final code = int.tryParse(match.group(1)!, radix: 16);
        if (code != null) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    return decoded;
  }

  /// Decode HTML entities in a gym name specifically
  /// This is a convenience method for gym names
  static String decodeGymName(String? gymName) {
    return decode(gymName);
  }

  /// Decode HTML entities in any text that might contain special characters
  static String decodeText(String? text) {
    return decode(text);
  }
}