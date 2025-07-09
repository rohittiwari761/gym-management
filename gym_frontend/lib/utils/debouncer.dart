import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer utility to prevent excessive API calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility to limit function calls
class Throttler {
  final Duration duration;
  DateTime? _lastExecuted;

  Throttler({required this.duration});

  bool canExecute() {
    final now = DateTime.now();
    if (_lastExecuted == null || now.difference(_lastExecuted!) >= duration) {
      _lastExecuted = now;
      return true;
    }
    return false;
  }
}

/// Cache manager for API responses
class CacheManager<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration defaultTtl;

  CacheManager({this.defaultTtl = const Duration(minutes: 5)});

  void put(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}