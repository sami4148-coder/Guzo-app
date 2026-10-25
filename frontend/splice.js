const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
const blockFile = 'C:\\Users\\hp\\sami13\\frontend\\intro_block.txt';
const block = fs.readFileSync(blockFile, 'utf8');
const src = fs.readFileSync(file, 'utf8');
const start = src.indexOf('  Widget _intro(bool wide) {');
if (start < 0) { console.log('start not found'); process.exit(1); }
const marker = '\n  }\n';
const end = src.indexOf(marker, start);
if (end < 0) { console.log('end not found'); process.exit(1); }
const out = src.slice(0, start) + block + src.slice(end + marker.length);
fs.writeFileSync(file, out, 'utf8');
console.log('done');
