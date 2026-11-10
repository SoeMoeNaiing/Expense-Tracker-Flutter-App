import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/features/settings/data/backup_file_io.dart';
import 'package:expense_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backup_file_io.dart';
import '../helpers/fake_category_repository.dart';
import '../helpers/fake_expense_repository.dart';

const _food = Category(
  id: 1,
  name: 'Food',
  iconCode: 0,
  colorHex: 0xFFFF6B6B,
  isDefault: true,
);

const _validCsv =
    'date,category,amount,payment_method,note\n'
    '2026-01-15,Food,2500,cash,Lunch\n';

/// Pump enough frames to let async work + dialog entrance animation finish.
/// NOTE: cannot use `pumpAndSettle` because while `_busy == true` the
/// `CircularProgressIndicator` spins forever (it doesn't honor
/// `MediaQuery.disableAnimations`), so `pumpAndSettle` times out.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<(FakeBackupFileIO, FakeExpenseRepository)> _mount(
  WidgetTester tester, {
  String? importContent,
  List<dynamic> expenses = const [],
}) async {
  final io = FakeBackupFileIO()..nextImportContent = importContent;
  final expRepo = FakeExpenseRepository();
  final catRepo = FakeCategoryRepository(const [_food]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupFileIOProvider.overrideWithValue(io),
        expenseRepositoryProvider.overrideWithValue(expRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
      ],
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle(); // OK here: _busy is false, no spinner
  return (io, expRepo);
}

void main() {
  testWidgets('renders export + import rows', (tester) async {
    await _mount(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Import CSV'), findsOneWidget);
  });

  testWidgets('export writes CSV via file IO', (tester) async {
    final (io, _) = await _mount(tester);

    await tester.tap(find.byKey(const Key('export_button')));
    await _pumpFrames(tester);

    expect(io.lastWrittenContent, isNotNull);
    expect(io.lastWrittenContent, contains('date,category,amount'));
    expect(io.lastSuggestedName, endsWith('.csv'));
  });

  testWidgets('import cancelled when file picker returns null', (tester) async {
    await _mount(tester, importContent: null);

    await tester.tap(find.byKey(const Key('import_button')));
    await _pumpFrames(tester);

    expect(find.text('Import CSV?'), findsNothing);
  });

  testWidgets('import shows confirm dialog with valid row count', (
    tester,
  ) async {
    await _mount(tester, importContent: _validCsv);

    await tester.tap(find.byKey(const Key('import_button')));
    await _pumpFrames(tester);

    expect(find.text('Import CSV?'), findsOneWidget);
    expect(find.text('1 valid row found.'), findsOneWidget);
  });

  testWidgets('import cancel does not insert', (tester) async {
    final (_, expRepo) = await _mount(tester, importContent: _validCsv);

    await tester.tap(find.byKey(const Key('import_button')));
    await _pumpFrames(tester);
    await tester.tap(find.text('Cancel'));
    await _pumpFrames(tester);

    expect(expRepo.items, isEmpty);
  });

  testWidgets('import confirm inserts rows', (tester) async {
    final (_, expRepo) = await _mount(tester, importContent: _validCsv);

    await tester.tap(find.byKey(const Key('import_button')));
    await _pumpFrames(tester);
    await tester.tap(find.text('Import'));
    await _pumpFrames(tester, frames: 15);

    expect(expRepo.items.length, 1);
    expect(expRepo.items.single.amount, 2500);
  });

  testWidgets('import with bad CSV shows error snackbar', (tester) async {
    await _mount(tester, importContent: 'garbage\nnot-csv');

    await tester.tap(find.byKey(const Key('import_button')));
    await _pumpFrames(tester);

    expect(find.textContaining('Missing required column'), findsOneWidget);
  });
}
