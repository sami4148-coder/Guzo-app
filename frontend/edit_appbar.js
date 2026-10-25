const fs = require('fs');
const file = 'C:\\Users\\hp\\sami13\\frontend\\lib\\features\\explore\\explore_page.dart';
const lines = fs.readFileSync(file, 'utf8').split(/(?<=\n)/);
const newBlock = `       appBar: PreferredSize(
         preferredSize: const Size.fromHeight(96),
         child: SafeArea(
           bottom: false,
           child: Padding(
             padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(26),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                       colors: [
                         Colors.white.withValues(alpha: 0.86),
                         GuzoColors.cream.withValues(alpha: 0.78),
                       ],
                     ),
                     borderRadius: BorderRadius.circular(26),
                     border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 1.2),
                     boxShadow: [
                       BoxShadow(color: GuzoColors.ink.withValues(alpha: 0.10), blurRadius: 30, offset: const Offset(0, 12)),
                       BoxShadow(color: GuzoColors.green.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6)),
                     ],
                   ),
                   child: Row(
                     children: [
                       _ExploreAppBarButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/')),
                       const SizedBox(width: 12),
                       Container(
                         width: 40,
                         height: 40,
                         decoration: BoxDecoration(
                           gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [GuzoColors.green, GuzoColors.gold]),
                           borderRadius: BorderRadius.circular(14),
                           boxShadow: [BoxShadow(color: GuzoColors.green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                         ),
                         child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 20),
                       ),
                       const SizedBox(width: 12),
                       const Expanded(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Explore stays', style: TextStyle(color: GuzoColors.ink, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontSize: 19, height: 1.05)),
                             SizedBox(height: 2),
                             Text('Find your perfect getaway', style: TextStyle(color: GuzoColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
                           ],
                         ),
                       ),
                       if (!wide) _FilterButton(activeCount: _activeFilterCount, onTap: _showFilters),
                     ],
                   ),
                 ),
               ),
             ),
           ),
         ),
       ),
`;
// replace lines 138..227 (1-indexed)
const start = 137; // 0-indexed start
const end = 227;   // 0-indexed exclusive
const out = lines.slice(0, start).concat(newBlock).concat(lines.slice(end));
fs.writeFileSync(file, out.join(''), 'utf8');
console.log('done');
