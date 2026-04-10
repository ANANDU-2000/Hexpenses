/// Categories and account used when running with `--dart-define=NO_API=true` (or `DEV_OFFLINE_UI`).
final noApiDemoCategories = <Map<String, dynamic>>[
  {
    'id': 'offline_cat_food',
    'name': 'Food & dining',
    'type': 'expense',
    'subCategoryRows': <Map<String, dynamic>>[],
  },
  {
    'id': 'offline_cat_transport',
    'name': 'Transport',
    'type': 'expense',
    'subCategoryRows': <Map<String, dynamic>>[],
  },
  {
    'id': 'offline_cat_home',
    'name': 'Home & utilities',
    'type': 'expense',
    'subCategoryRows': <Map<String, dynamic>>[],
  },
  {
    'id': 'offline_cat_other',
    'name': 'Other',
    'type': 'expense',
    'subCategoryRows': <Map<String, dynamic>>[],
  },
];

const noApiDemoAccountId = 'offline_demo_cash';
