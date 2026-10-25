const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
let src = fs.readFileSync(file, 'utf8');

// Add onGuestsChanged param to _FilterSheet constructor signature
src = src.replace(
  "    required this.onSortChanged,\n    required this.onApply,\n    required this.onReset,\n  });\n\n  final RangeValues price;",
  "    required this.onSortChanged,\n    required this.onGuestsChanged,\n    required this.onApply,\n    required this.onReset,\n  });\n\n  final RangeValues price;"
);
// Add field after sort field in _FilterSheet
src = src.replace(
  "  final String sort;\n  final int? guests;\n  final String? category;\n  final ValueChanged<String?> onCategoryChanged;",
  "  final String sort;\n  final int? guests;\n  final String? category;\n  final ValueChanged<int?> onGuestsChanged;\n  final ValueChanged<String?> onCategoryChanged;"
);
// In _FilterSheet build, pass onGuestsChanged to _filterBody instead of no-op
src = src.replace(
  "                onSortChanged: onSortChanged,\n                onGuestsChanged: (g) {},\n                onCityChanged: (_) {},",
  "                onSortChanged: onSortChanged,\n                onGuestsChanged: onGuestsChanged,\n                onCityChanged: (_) {},"
);

// Add onGuestsChanged param to _DesktopFilterPanel constructor signature
src = src.replace(
  "    required this.onSortChanged,\n    required this.onApply,\n    required this.onReset,\n  });\n\n  final RangeValues price;\n  final double minRating;\n  final String sort;\n  final int? guests;\n  final String? category;\n  final TextEditingController city;",
  "    required this.onSortChanged,\n    required this.onGuestsChanged,\n    required this.onApply,\n    required this.onReset,\n  });\n\n  final RangeValues price;\n  final double minRating;\n  final String sort;\n  final int? guests;\n  final String? category;\n  final ValueChanged<int?> onGuestsChanged;\n  final TextEditingController city;"
);
// In desktop _filterBody call, pass onGuestsChanged
src = src.replace(
  "              onSortChanged: onSortChanged,\n              onGuestsChanged: (g) => onCategoryChanged(category),",
  "              onSortChanged: onSortChanged,\n              onGuestsChanged: onGuestsChanged,"
);

fs.writeFileSync(file, src, 'utf8');
console.log('done');
