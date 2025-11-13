import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isSelected;

  // 🔹 Colores personalizables
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultBg = backgroundColor ??
        (isSelected
            ? Theme.of(context).primaryColorDark
            : const Color(0xFF111827));
    final Color defaultText = textColor ?? Colors.white;
    final Color? border = borderColor ?? (isSelected ? Colors.white : null);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: defaultBg,
          borderRadius: BorderRadius.circular(8),
          border: border != null ? Border.all(color: border, width: 2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (icon != null) Icon(icon, color: defaultText),
            if (icon != null) const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(color: defaultText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
