import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/categories/presentation/screens/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this.initial);
  final List<Category> initial;

  @override
  Future<List<Category>> build() async => initial;
}

void main() {
  testWidgets('renders default + user categories', (tester) async {
    final cats = [
      const Category(
        id: 1,
        name: 'Food',
        iconCode: 0,
        colorHex: 0xFFFF6B6B,
        isDefault: true,
      ),
      const Category(
        id: 2,
        name: 'Coffee',
        iconCode: 0,
        colorHex: 0xFF7C5CFF,
        isDefault: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(() => _FakeCategoriesNotifier(cats)),
        ],
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: CategoriesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
