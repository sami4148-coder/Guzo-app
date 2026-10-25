import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api.dart';
import '../../core/theme.dart';

class OwnerHotelPosts extends StatefulWidget {
  const OwnerHotelPosts({required this.onChanged, super.key});

  final VoidCallback onChanged;

  @override
  State<OwnerHotelPosts> createState() => _OwnerHotelPostsState();
}

class _OwnerHotelPostsState extends State<OwnerHotelPosts> {
  List<dynamic> _hotels = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hotels = await ApiClient.instance.getList('/hotels/mine');
      if (!mounted) return;
      setState(() => _hotels = hotels);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() => _edit();

  Future<void> _edit([Map<String, dynamic>? hotel]) async {
    final result = await showDialog<_HotelPostData>(
      context: context,
      builder: (_) => _HotelPostDialog(hotel: hotel),
    );
    if (result == null || !mounted) return;

    try {
      if (hotel == null) {
        await ApiClient.instance.postMultipart(
          '/hotels',
          fields: result.fields,
          images: result.images,
        );
      } else {
        await ApiClient.instance.patchMultipart(
          '/hotels/${hotel['id']}',
          fields: result.fields,
          images: result.images,
        );
      }
      await _load();
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hotel == null
              ? 'Hotel published on Explore.'
              : 'Hotel post updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save hotel post: $error')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> hotel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this hotel post?'),
        content: Text(
          '“${hotel['name']}” will be removed from Explore and cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep post'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC05746),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiClient.instance.delete('/hotels/${hotel['id']}');
      await _load();
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete hotel post: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECE9)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your hotel posts',
                      style: TextStyle(
                        color: GuzoColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create and manage stays shown to travelers.',
                      style: TextStyle(
                        color: GuzoColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add hotel'),
                style: FilledButton.styleFrom(
                  backgroundColor: GuzoColors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ] else if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFC05746))),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ] else if (_hotels.isEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Your listings will appear here after you publish your first hotel.',
              style: TextStyle(color: GuzoColors.muted, height: 1.4),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ..._hotels.map((item) {
              final hotel = Map<String, dynamic>.from(item as Map);
              final status = hotel['status']?.toString() ?? 'PENDING';
              final images =
                  hotel['images'] is List ? hotel['images'] as List : const [];
              final imageUrl = images.isNotEmpty && images.first is Map
                  ? (images.first as Map)['url']?.toString()
                  : hotel['coverImage']?.toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6ECEB)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: imageUrl == null
                          ? const ColoredBox(
                              color: Color(0xFFE7F3F3),
                              child: Icon(Icons.hotel_rounded),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFE7F3F3),
                                child: Icon(Icons.hotel_rounded),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    hotel['name']?.toString() ?? 'Hotel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${hotel['city'] ?? ''} · ${status.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Manage hotel post',
                    onSelected: (action) {
                      if (action == 'edit') {
                        _edit(hotel);
                      } else {
                        _delete(hotel);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit post'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete post'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _HotelPostData {
  const _HotelPostData({required this.fields, required this.images});
  final Map<String, String> fields;
  final List<XFile> images;
}

class _HotelPostDialog extends StatefulWidget {
  const _HotelPostDialog({this.hotel});
  final Map<String, dynamic>? hotel;

  @override
  State<_HotelPostDialog> createState() => _HotelPostDialogState();
}

class _HotelPostDialogState extends State<_HotelPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rooms = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _amenities = TextEditingController();
  final _details = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  String _category = 'luxury';
  bool _saving = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final hotel = widget.hotel;
    if (hotel == null) return;
    _name.text = hotel['name']?.toString() ?? '';
    _rooms.text = hotel['roomsAvailable']?.toString() ?? '1';
    _city.text = hotel['city']?.toString() ?? '';
    _address.text = hotel['address']?.toString() ?? '';
    _price.text = hotel['basePrice']?.toString() ?? '';
    _description.text = hotel['description']?.toString() ?? '';
    _details.text = hotel['otherDetails']?.toString() ?? '';
    _category = switch (hotel['category']?.toString().toLowerCase()) {
      'budget' => 'medium-range',
      'resort' || 'guesthouse' => 'other',
      'medium-range' => 'medium-range',
      'other' => 'other',
      _ => 'luxury',
    };
    final amenities = hotel['amenities'];
    if (amenities is List) {
      _amenities.text = amenities
          .map((item) {
            if (item is Map) {
              final amenity = item['amenity'];
              if (amenity is Map) return amenity['name']?.toString() ?? '';
            }
            return item.toString();
          })
          .where((name) => name.isNotEmpty)
          .join(', ');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _rooms.dispose();
    _city.dispose();
    _address.dispose();
    _price.dispose();
    _description.dispose();
    _amenities.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final selected = await _picker.pickMultiImage(
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (!mounted || selected.isEmpty) return;
      if (selected.length > 8) {
        setState(() => _imageError = 'Choose up to 8 photos.');
        return;
      }
      setState(() {
        _images
          ..clear()
          ..addAll(selected);
        _imageError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _imageError = 'Could not open gallery: $error');
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existingImages = widget.hotel?['images'];
    if (widget.hotel == null && _images.isEmpty) {
      setState(() => _imageError = 'Add at least one hotel photo.');
      return;
    }
    if (widget.hotel != null &&
        _images.isEmpty &&
        (existingImages is! List || existingImages.isEmpty)) {
      setState(() => _imageError = 'Add at least one hotel photo.');
      return;
    }

    setState(() => _saving = true);
    Navigator.of(context).pop(
      _HotelPostData(
        fields: {
          'name': _name.text.trim(),
          'roomsAvailable': _rooms.text.trim(),
          'city': _city.text.trim(),
          'address': _address.text.trim(),
          'basePrice': _price.text.trim(),
          'category': _category,
          'description': _description.text.trim(),
          'amenities': _amenities.text.trim(),
          'otherDetails': _details.text.trim(),
        },
        images: List<XFile>.unmodifiable(_images),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final existingImages = widget.hotel?['images'];
    final screen = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: Text(
          widget.hotel == null ? 'Create a hotel post' : 'Edit hotel post'),
      content: SizedBox(
        width: screen.width > 640 ? 560 : screen.width * 0.86,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screen.height * 0.68),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Share accurate details so travelers can choose your stay with confidence.',
                  style: TextStyle(color: GuzoColors.muted, height: 1.35),
                ),
                const SizedBox(height: 18),
                _field('Hotel name', _name, validator: _required),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Rooms available',
                        _rooms,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_required(value) != null) return 'Required';
                          if (int.tryParse(value!) == null ||
                              int.parse(value) < 1) {
                            return 'Enter at least 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Nightly price (ETB)',
                        _price,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_required(value) != null) return 'Required';
                          if (int.tryParse(value!) == null ||
                              int.parse(value) < 1) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                _field('City or location', _city, validator: _required),
                _field('Street address', _address, validator: _required),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Hotel category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'luxury', child: Text('Luxury')),
                    DropdownMenuItem(
                        value: 'medium-range', child: Text('Medium-Range')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  'Hotel description',
                  _description,
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => (value?.trim().length ?? 0) < 10
                      ? 'Please write at least 10 characters'
                      : null,
                ),
                _field(
                  'Facilities and amenities',
                  _amenities,
                  hint:
                      'Separate items with commas, e.g. Wi-Fi, breakfast, parking',
                  minLines: 2,
                  maxLines: 3,
                ),
                _field(
                  'Other relevant details',
                  _details,
                  hint: 'Check-in details, views, accessibility, and more',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_images.isEmpty
                      ? 'Choose photos from gallery'
                      : 'Choose ${_images.length} photos'),
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => FutureBuilder(
                        future: _images[index].readAsBytes(),
                        builder: (_, snapshot) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: snapshot.hasData
                              ? Image.memory(
                                  snapshot.data!,
                                  width: 86,
                                  height: 78,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox(
                                  width: 86,
                                  height: 78,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                        ),
                      ),
                    ),
                  ),
                ] else if (existingImages is List &&
                    existingImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Current photos are kept unless you select replacement photos.',
                    style: TextStyle(color: GuzoColors.muted, fontSize: 12),
                  ),
                ],
                if (_imageError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageError!,
                    style: const TextStyle(color: Color(0xFFC05746)),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.publish_rounded, size: 18),
          label: Text(widget.hotel == null ? 'Publish' : 'Save changes'),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
