import 'package:flutter/material.dart';

class AccountListTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String balance;
  final VoidCallback? onTap;

  const AccountListTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        child: Text(
          name.isEmpty ? '؟' : name.characters.first,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Text(
        balance,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
