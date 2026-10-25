const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
const src = fs.readFileSync(file, 'utf8');
const block = fs.readFileSync('C:\\Users\\hp\\sami13\\frontend\\methods_block.txt', 'utf8');
const marker = '\n}\n\nclass _ExploreAppBarButton';
if (!src.includes(marker)) { console.log('marker missing'); process.exit(1); }
const out = src.replace(marker, '\n' + block + '}\n\nclass _ExploreAppBarButton');
fs.writeFileSync(file, out, 'utf8');
console.log('done');
