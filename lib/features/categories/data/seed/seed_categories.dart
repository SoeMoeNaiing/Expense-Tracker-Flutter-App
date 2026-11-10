import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/schema.dart';

class _Seed {
  final String name;
  final IconData icon;
  final Color color;
  const _Seed(this.name, this.icon, this.color);
}

const _seeds = <_Seed>[
  _Seed('Food', Icons.restaurant, Color(0xFFFF6B6B)),
  _Seed('Transport', Icons.directions_car, Color(0xFF4EA8FF)),
  _Seed('Shopping', Icons.shopping_bag, Color(0xFFC084FC)),
  _Seed('Bills', Icons.receipt_long, Color(0xFFFFB020)),
  _Seed('Health', Icons.favorite, Color(0xFFFF6BB5)),
  _Seed('Entertainment', Icons.movie, Color(0xFF7C5CFF)),
  _Seed('Other', Icons.more_horiz, Color(0xFFA0A0A8)),
];

/// Idempotent: safe to call every startup. UNIQUE(name) makes duplicates
/// a no-op.
Future<void> seedDefaultCategories(AppDatabase appDb) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final s in _seeds) {
    await appDb.db.insert(Tables.categories, {
      CategoryCols.name: s.name,
      CategoryCols.iconCode: s.icon.codePoint,
      // ignore: deprecated_member_use
      CategoryCols.colorHex: s.color.value,
      CategoryCols.isDefault: 1,
      CategoryCols.createdAt: now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
