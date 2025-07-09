import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring widget for development
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;
  final List<Duration> _buildDurations = [];

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final buildStart = DateTime.now();
    _buildCount++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buildEnd = DateTime.now();
      final buildDuration = buildEnd.difference(buildStart);
      
      _buildDurations.add(buildDuration);
      if (_buildDurations.length > 100) {
        _buildDurations.removeAt(0);
      }
      
      _lastBuildTime = buildEnd;
    });

    return widget.child;
  }
}

/// Memory usage tracker
class MemoryTracker {
  static final MemoryTracker _instance = MemoryTracker._internal();
  factory MemoryTracker() => _instance;
  MemoryTracker._internal();

  void logMemoryUsage(String tag) {
    if (kDebugMode) {
      // This would integrate with platform-specific memory monitoring
      print('[$tag] Memory usage logged');
    }
  }
}

/// Performance metrics collection
class PerformanceMetrics {
  static final PerformanceMetrics _instance = PerformanceMetrics._internal();
  factory PerformanceMetrics() => _instance;
  PerformanceMetrics._internal();

  final Map<String, List<Duration>> _metrics = {};

  void recordMetric(String name, Duration duration) {
    if (!kDebugMode) return;
    
    _metrics[name] ??= [];
    _metrics[name]!.add(duration);
    
    // Keep only last 100 measurements
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }
  }

  Duration? getAverageMetric(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return null;
    
    final total = metrics.fold<int>(0, (sum, duration) => sum + duration.inMicroseconds);
    return Duration(microseconds: total ~/ metrics.length);
  }

  void printMetrics() {
    if (!kDebugMode) return;
    
    print('Performance Metrics:');
    _metrics.forEach((name, durations) {
      final avg = getAverageMetric(name);
      print('  $name: ${avg?.inMilliseconds}ms avg (${durations.length} samples)');
    });
  }
}

/// Widget build time tracker
mixin BuildTimeTracker<T extends StatefulWidget> on State<T> {
  DateTime? _buildStart;
  
  @override
  Widget build(BuildContext context) {
    _buildStart = DateTime.now();
    final widget = buildWidget(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_buildStart != null) {
        final buildTime = DateTime.now().difference(_buildStart!);
        PerformanceMetrics().recordMetric('${T.toString()}_build', buildTime);
      }
    });
    
    return widget;
  }
  
  Widget buildWidget(BuildContext context);
}

/// Network request timing
class NetworkTimer {
  static final NetworkTimer _instance = NetworkTimer._internal();
  factory NetworkTimer() => _instance;
  NetworkTimer._internal();

  final Map<String, DateTime> _startTimes = {};

  void startTimer(String requestId) {
    _startTimes[requestId] = DateTime.now();
  }

  void endTimer(String requestId, String endpoint) {
    final startTime = _startTimes.remove(requestId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      PerformanceMetrics().recordMetric('network_$endpoint', duration);
    }
  }
}