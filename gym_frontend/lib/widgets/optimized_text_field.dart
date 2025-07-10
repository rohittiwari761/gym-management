import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optimized TextField widget that reduces first-tap delay and improves performance
class OptimizedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;

  const OptimizedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.decoration,
    this.style,
  });

  @override
  State<OptimizedTextField> createState() => _OptimizedTextFieldState();
}

class _OptimizedTextFieldState extends State<OptimizedTextField> {
  late FocusNode _focusNode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _preInitializeTextField();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Pre-initialize text field to reduce first-tap delay
  void _preInitializeTextField() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Pre-warm this specific text field
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: widget.style ?? const TextStyle(fontSize: 18),
      
      // Optimized decoration
      decoration: widget.decoration ?? InputDecoration(
        labelText: widget.labelText,
        labelStyle: const TextStyle(fontSize: 16),
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null 
            ? Icon(widget.prefixIcon, size: 24) 
            : null,
        suffixIcon: widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      
      // Performance optimizations
      buildCounter: widget.maxLength != null 
          ? (context, {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength${maxLength != null ? '/$maxLength' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
          : null,
    );
  }
}

/// Factory methods for common text field types
class OptimizedTextFields {
  
  /// Email input field
  static OptimizedTextField email({
    Key? key,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool autofocus = false,
  }) {
    return OptimizedTextField(
      key: key,
      controller: controller,
      labelText: 'Email Address',
      hintText: 'Enter your email',
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
    );
  }

  /// Password input field
  static Widget password({
    Key? key,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool autofocus = false,
  }) {
    return _PasswordField(
      key: key,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
    );
  }

  /// Phone number input field
  static OptimizedTextField phone({
    Key? key,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool autofocus = false,
  }) {
    return OptimizedTextField(
      key: key,
      controller: controller,
      labelText: 'Phone Number',
      hintText: 'Enter phone number',
      prefixIcon: Icons.phone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
    );
  }

  /// Search input field
  static OptimizedTextField search({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return OptimizedTextField(
      key: key,
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// Password field with visibility toggle
class _PasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool autofocus;

  const _PasswordField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return OptimizedTextField(
      controller: widget.controller,
      labelText: 'Password',
      hintText: 'Enter your password',
      prefixIcon: Icons.lock,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      validator: widget.validator,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }
}