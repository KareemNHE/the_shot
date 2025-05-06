//views/widgets/settings_item.dart
import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    Key? key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      icon: icon,
      title: title,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}