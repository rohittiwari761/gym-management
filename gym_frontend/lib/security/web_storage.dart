// Web storage implementation
import 'dart:html' as html;

class WebStorage {
  static void setItem(String key, String value) {
    html.window.localStorage[key] = value;
  }
  
  static String? getItem(String key) {
    return html.window.localStorage[key];
  }
  
  static void removeItem(String key) {
    html.window.localStorage.remove(key);
  }
}