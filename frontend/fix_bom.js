const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
let src = fs.readFileSync(file, 'utf8');
// remove BOM
src = src.replace(/\uFEFF/g, '');
// add _ExploreAppBarButton class before _HeroPill if missing
const cls = `class _ExploreAppBarButton extends StatelessWidget {
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
if (!src.includes('class _ExploreAppBarButton')) {
  const marker = 'class _HeroPill extends StatelessWidget {';
  src = src.replace(marker, cls + marker);
}
fs.writeFileSync(file, src, 'utf8');
console.log('done');
