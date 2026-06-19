import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final int residenceId;
  final VoidCallback? onChanged;

  const FavoriteButton({
    super.key,
    required this.residenceId,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final fav = await FavoritesService.isFavorite(
      widget.residenceId.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final fav = await FavoritesService.toggleFavorite(
      widget.residenceId.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
    });

    widget.onChanged?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fav
              ? 'Ajouté aux favoris'
              : 'Retiré des favoris',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white,
      ),
    );
  }
}