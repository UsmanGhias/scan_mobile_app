import 'package:flutter/material.dart';

class HelperTextField extends StatelessWidget {
  final String htxt;
  String labelText;
  final TextEditingController controller;
  final IconData iconData;
  final bool obscure;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;

  HelperTextField({
    super.key,
    this.labelText = '',
    required this.htxt,
    required this.iconData,
    required this.controller,
    required this.keyboardType,
    this.onChanged,
    this.obscure = false,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fieldWidth = constraints.maxWidth > 600
            ? constraints.maxWidth * 0.6
            : constraints.maxWidth * 0.9;

        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: SizedBox(
            width: fieldWidth,
            child: TextFormField(
              validator: validator,
              obscureText: obscure,
              onChanged: onChanged,
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: htxt, // Use labelText instead of hintText
                floatingLabelBehavior:
                    FloatingLabelBehavior.always, // This keeps it visible
                fillColor: const Color.fromARGB(255, 235, 222, 222),
                filled: true,
                prefixIcon: Icon(iconData),
              ),
            ),
          ),
        );
      },
    );
  }
}
