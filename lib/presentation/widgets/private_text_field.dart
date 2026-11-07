import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field with the keyboard's incognito flags set: no personalised
/// learning, no suggestions, no autocorrect, no autofill. On Android this
/// sets IME_FLAG_NO_PERSONALIZED_LEARNING and TYPE_TEXT_FLAG_NO_SUGGESTIONS.
class PrivateTextField extends StatelessWidget {
  const PrivateTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.decoration,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      minLines: obscure ? null : minLines,
      maxLines: obscure ? 1 : maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      // Incognito keyboard.
      enableIMEPersonalizedLearning: false,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: null,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helper,
            helperMaxLines: 3,
            errorText: errorText,
            errorMaxLines: 3,
          ),
    );
  }
}
