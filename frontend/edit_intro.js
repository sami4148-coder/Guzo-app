const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
const lines = fs.readFileSync(file, 'utf8').split(/(?<=\n)/);
const newBlock = `  Widget _intro(bool wide) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: GuzoColors.ink.withValues(alpha: 0.22), blurRadius: 36, offset: const Offset(0, 18)),
          BoxShadow(color: GuzoColors.green.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B5260), Color(0xFF16849A), Color(0xFF43B8AE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF061B2E).withValues(alpha: 0.88),
                      const Color(0xFF0B2545).withValues(alpha: 0.55),
                      const Color(0xFF147D9B).withValues(alpha: 0.25),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 34 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 6),
                        Text('DISCOVER ETHIOPIA', style: TextStyle(color: Colors.white, fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find a place\nthat feels like yours.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 34 : 28,
                      height: 1.08,
                      letterSpacing: -1.0,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'From highland hideaways to city escapes.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: const [
                      _HeroPill(icon: Icons.verified_rounded, label: 'Verified stays'),
                      _HeroPill(icon: Icons.star_rounded, label: 'Top rated'),
                      _HeroPill(icon: Icons.payments_rounded, label: 'Best prices'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
`;
const start = 326; // 0-indexed line 327
// find end: line with '  }' after _intro. Search from start for '
  }
' at column 2? We'll find first occurrence of '\n  }\n' after start+5
let joined = lines.join('');
// We'll locate function boundaries by searching in joined text
const fnStart = joined.indexOf('  Widget _intro(bool wide) {');
const fnEndMarker = '\n  }\n';
const fnEnd = joined.indexOf(fnEndMarker, fnStart) + fnEndMarker.length;
if (fnStart < 0 || fnEnd < 0) { console.log('bounds not found'); process.exit(1); }
const out = joined.slice(0, fnStart) + newBlock + joined.slice(fnEnd);
fs.writeFileSync(file, out, 'utf8');
console.log('done');
