const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
const src = fs.readFileSync(file, 'utf8');
const cls = `
class _ExploreAppBarButton extends StatelessWidget {
  const _ExploreAppBarButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: GuzoColors.ink),
        ),
      ),
    );
  }
}
`;
const marker = 'class _FilterButton extends StatelessWidget {';
if (!src.includes(marker)) { console.log('marker missing'); process.exit(1); }
const out = src.replace(marker, cls + '\n' + marker);
fs.writeFileSync(file, out, 'utf8');
console.log('done');
