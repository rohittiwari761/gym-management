// Stub implementation for non-web platforms
class Window {
  Map<String, String> get localStorage => <String, String>{};
}

class Html {
  static Window window = Window();
}