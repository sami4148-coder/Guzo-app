const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
let src = fs.readFileSync(file, 'utf8');

// _showFilters: add onGuestsChanged after onSortChanged
src = src.replace(
  "        onSortChanged: (s) => setState(() => _sort = s),\n        onApply: () {",
  "        onSortChanged: (s) => setState(() => _sort = s),\n        onGuestsChanged: (g) => setState(() => _guests = g),\n        onApply: () {"
);

// desktop panel: add onGuestsChanged after onSortChanged
src = src.replace(
  "                       onSortChanged: (s) => setState(() => _sort = s),\n                       onApply: _load,",
  "                       onSortChanged: (s) => setState(() => _sort = s),\n                       onGuestsChanged: (g) => setState(() => _guests = g),\n                       onApply: _load,"
);

fs.writeFileSync(file, src, 'utf8');
console.log('done');
