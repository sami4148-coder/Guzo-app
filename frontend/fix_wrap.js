const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
let src = fs.readFileSync(file, 'utf8');
src = src.replace("                  Wrap(\n                    spacing: 10,", "                  const Wrap(\n                    spacing: 10,");
fs.writeFileSync(file, src, 'utf8');
console.log('done');
