import 'package:flutter_test/flutter_test.dart';
import 'package:gym_management/utils/html_decoder.dart';

void main() {
  group('HtmlDecoder', () {
    test('should decode apostrophe HTML entities correctly', () {
      expect(HtmlDecoder.decode('Rohit&amp;#x27;s Fitness Center'), equals("Rohit's Fitness Center"));
      expect(HtmlDecoder.decode('John&#39;s Gym'), equals("John's Gym"));
      expect(HtmlDecoder.decode('Mary&apos;s Studio'), equals("Mary's Studio"));
    });

    test('should decode common HTML entities correctly', () {
      expect(HtmlDecoder.decode('Rock &amp; Roll Gym'), equals('Rock & Roll Gym'));
      expect(HtmlDecoder.decode('&lt;Premium&gt; Fitness'), equals('<Premium> Fitness'));
      expect(HtmlDecoder.decode('&quot;Elite&quot; Gym'), equals('"Elite" Gym'));
      expect(HtmlDecoder.decode('Gym&nbsp;Center'), equals('Gym Center'));
    });

    test('should handle multiple HTML entities in one string', () {
      expect(
        HtmlDecoder.decode('Rock &amp; Roll &amp;#x27;s &lt;Premium&gt; Gym'),
        equals("Rock & Roll 's <Premium> Gym"),
      );
    });

    test('should handle numeric HTML entities', () {
      expect(HtmlDecoder.decode('Test&#65;gym'), equals('TestAgym'));
      expect(HtmlDecoder.decode('Test&#x41;gym'), equals('TestAgym'));
    });

    test('should return empty string for null input', () {
      expect(HtmlDecoder.decode(null), equals(''));
    });

    test('should return empty string for empty input', () {
      expect(HtmlDecoder.decode(''), equals(''));
    });

    test('should return unchanged string if no HTML entities', () {
      expect(HtmlDecoder.decode('Regular Gym Name'), equals('Regular Gym Name'));
    });

    test('should handle gym name convenience method', () {
      expect(HtmlDecoder.decodeGymName('Rohit&amp;#x27;s Fitness Center'), equals("Rohit's Fitness Center"));
      expect(HtmlDecoder.decodeGymName(null), equals(''));
    });

    test('should handle text convenience method', () {
      expect(HtmlDecoder.decodeText('A &quot;premium&quot; gym experience'), equals('A "premium" gym experience'));
      expect(HtmlDecoder.decodeText(null), equals(''));
    });
  });
}