import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget that pre-warms input fields when the screen loads
/// Place this widget anywhere in your widget tree to reduce first-tap delay
class InputFieldWarmer extends StatefulWidget {
  final Widget child;
  
  const InputFieldWarmer({
    super.key,
    required this.child,
  });

  @override
  State<InputFieldWarmer> createState() => _InputFieldWarmerState();
}

class _InputFieldWarmerState extends State<InputFieldWarmer> {
  @override
  void initState() {
    super.initState();
    _warmUpInputFields();
  }

  /// Pre-warm input fields to reduce first-tap delay
  void _warmUpInputFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // Create a temporary, invisible text field to warm up the text input system
          final dummyController = TextEditingController();
          final dummyFocusNode = FocusNode();
          
          // Create invisible text field
          final invisibleTextField = Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: dummyController,
                focusNode: dummyFocusNode,
              ),
            ),
          );
          
          // Temporarily add it to trigger text input initialization
          if (context.mounted) {
            // Request focus briefly to initialize text input system
            dummyFocusNode.requestFocus();
            
            // Clean up after a short delay
            Future.delayed(const Duration(milliseconds: 50), () {
              dummyFocusNode.unfocus();
              dummyController.dispose();
              dummyFocusNode.dispose();
            });
          }
        } catch (e) {
          // Silently fail - this is just an optimization
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin to add to screens that contain text fields
mixin TextFieldOptimizationMixin<T extends StatefulWidget> on State<T> {
  
  @override
  void initState() {
    super.initState();
    _preWarmTextFields();
  }
  
  /// Call this in initState to pre-warm text fields
  void _preWarmTextFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Pre-initialize text input connection
        try {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        } catch (e) {
          // Ignore errors - this is just an optimization
        }
      }
    });
  }
}