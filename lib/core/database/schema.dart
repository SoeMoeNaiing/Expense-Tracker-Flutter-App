/// Table and column name constants. Referenced by migrations, data
/// sources, and tests — never write a raw string in a query.
abstract final class Tables {
  static const categories = 'categories';
  static const expenses = 'expenses';
}

abstract final class CategoryCols {
  static const id = 'id';
  static const name = 'name';
  static const iconCode = 'icon_code';
  static const colorHex = 'color_hex';
  static const isDefault = 'is_default';
  static const createdAt = 'created_at';
}

abstract final class ExpenseCols {
  static const id = 'id';
  static const amount = 'amount';
  static const categoryId = 'category_id';
  static const note = 'note';
  static const occurredAt = 'occurred_at';
  static const createdAt = 'created_at';
}
