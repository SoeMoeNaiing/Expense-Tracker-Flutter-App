abstract final class Tables {
  static const categories = 'categories';
  static const expenses = 'expenses';
  static const budgets = 'budgets';
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
  static const paymentMethod = 'payment_method';
}

abstract final class BudgetCols {
  static const id = 'id';
  static const categoryId = 'category_id';
  static const amount = 'amount';
  static const createdAt = 'created_at';
}
