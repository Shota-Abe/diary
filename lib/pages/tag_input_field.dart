import 'package:flutter/material.dart';

// このウィジェットはTextField本体とFocusNodeだけを管理する
class TagInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const TagInputField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        hintText: 'タグを入力してください...',
        border: OutlineInputBorder(),
      ),
    );
  }
}