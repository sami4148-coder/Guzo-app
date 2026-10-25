import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../state/favorite_hotels_state.dart';

class FavoriteHotelButton extends StatelessWidget {
  const FavoriteHotelButton({
    required this.hotelId,
    this.size = 40,
    this.iconSize = 19,
    super.key,
  });

  final String hotelId;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthState>().user?.id;
    return Consumer<FavoriteHotelsState>(
      builder: (context, favorites, _) {
        final isFavorite = favorites.contains(hotelId);
        return Material(
          color: Colors.white.withValues(alpha: 0.95),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: userId == null ||
                    favorites.loading ||
                    favorites.isSaving(hotelId)
                ? null
                : () async {
                    try {
                      await favorites.toggle(userId, hotelId);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Could not save favorite: $error')),
                      );
                    }
                  },
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: iconSize,
                color: isFavorite
                    ? const Color(0xFFC05746)
                    : const Color(0xFF183431),
              ),
            ),
          ),
        );
      },
    );
  }
}
