// Stub implementation for non-web platforms
// This file provides empty implementations for html APIs when not on web

class WindowStub {
  NavigatorStub get navigator => NavigatorStub();
  LocationStub get location => LocationStub();
  HistoryStub get history => HistoryStub();
  
  void open(String url, String target) {
    // No-op for non-web platforms
  }
}

class NavigatorStub {
  String get userAgent => '';
}

class LocationStub {
  String get origin => '';
  String get href => '';
}

class HistoryStub {
  void replaceState(dynamic data, String title, String url) {
    // No-op for non-web platforms
  }
}

class ImageElementStub {
  String src = '';
  Stream<dynamic> get onLoad => Stream.empty();
}

// Export stubs with same names as html library
final WindowStub window = WindowStub();
ImageElementStub ImageElement() => ImageElementStub();