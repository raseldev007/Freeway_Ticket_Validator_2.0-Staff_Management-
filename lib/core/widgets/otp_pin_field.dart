import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class OtpPinField extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final bool isObscure;
  final FocusNode? firstFocusNode;
  final bool autofocus;
  final bool enabled;

  const OtpPinField({
    super.key,
    this.length = 4,
    required this.controller,
    this.onCompleted,
    this.isObscure = false,
    this.firstFocusNode,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<OtpPinField> createState() => _OtpPinFieldState();
}

class _OtpPinFieldState extends State<OtpPinField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.firstFocusNode ?? FocusNode();
    _focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);

    if (widget.autofocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _refresh() {
    if (!mounted) return;
    if (widget.controller.selection.baseOffset != widget.controller.text.length ||
        widget.controller.selection.extentOffset != widget.controller.text.length) {
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_refresh);
    widget.controller.removeListener(_refresh);
    if (widget.firstFocusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              String char = "";
              if (index < text.length) {
                char = text[index];
              }

              bool isFocused = _focusNode.hasFocus &&
                  (index == text.length ||
                      (index == widget.length - 1 &&
                          text.length == widget.length));

              return Container(
                width: (MediaQuery.of(context).size.width -
                        56 -
                        (widget.length - 1) * 8) /
                    widget.length,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.enabled ? const Color(0xFFF2F4F7) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isFocused && widget.enabled) ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    char.isEmpty ? "" : (widget.isObscure ? "●" : char),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ),
              );
            }),
          ),

          Positioned.fill(
            child: AutofillGroup(
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: Colors.transparent,
                    selectionHandleColor: Colors.transparent,
                    cursorColor: Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  obscureText: widget.isObscure,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textInputAction: TextInputAction.done,
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  enableSuggestions: true,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.oneTimeCode
                  ],
                  textAlign: TextAlign.center,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 32,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (value.length == widget.length &&
                        widget.onCompleted != null) {
                      TextInput.finishAutofillContext();
                      widget.onCompleted!(value);
                    }
                  },
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: "",
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
