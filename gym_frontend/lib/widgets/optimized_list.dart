import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Optimized list widget with smart rebuilding
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.separator,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('No items found'),
      );
    }

    return ListView.separated(
      itemCount: widget.items.length,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      separatorBuilder: (context, index) => widget.separator ?? const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return RepaintBoundary(
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}

/// Optimized grid view
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('No items found'),
      );
    }

    return GridView.builder(
      gridDelegate: widget.gridDelegate,
      itemCount: widget.items.length,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return RepaintBoundary(
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}

/// Provider selector for optimized rebuilds
class OptimizedSelector<T, R> extends StatelessWidget {
  final R Function(T) selector;
  final Widget Function(BuildContext, R, Widget?) builder;
  final Widget? child;

  const OptimizedSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<T, R>(
      selector: (context, value) => selector(value),
      builder: builder,
      child: child,
    );
  }
}

/// Lazy loading list view
class LazyListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) loader;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int pageSize;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const LazyListView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loader(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ?? Center(child: Text('Error: $_error'));
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return ListView.builder(
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          // Load more trigger
          if (!_isLoading) {
            _loadNextPage();
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return RepaintBoundary(
          child: widget.itemBuilder(context, _items[index], index),
        );
      },
    );
  }
}