import 'package:flutter/material.dart';

class ChildTile extends StatelessWidget {
  final String name;
  final dynamic age;
  final dynamic gender;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ChildTile({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xff4ab0d1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(color: Color(0xff254865)),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('العمر: $age'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Color(0xff4ab0d1)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}