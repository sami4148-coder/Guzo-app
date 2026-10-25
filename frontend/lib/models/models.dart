class Hotel {
  final String id;
  final String name;
  final String city;
  final String address;
  final String description;
  final String category;
  final int basePrice;
  final double rating;
  final String? coverImage;
  final List<RoomType> roomTypes;
  final List<String> amenities;

  Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.rating,
    this.coverImage,
    this.roomTypes = const [],
    this.amenities = const [],
  });

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
        id: j['id'],
        name: j['name'],
        city: j['city'] ?? '',
        address: j['address'] ?? '',
        description: j['description'] ?? '',
        category: j['category'] ?? '',
        basePrice: (j['basePrice'] ?? 0) as int,
        rating: (j['rating'] ?? 0).toDouble(),
        coverImage: (j['images'] is List && (j['images'] as List).isNotEmpty)
            ? (j['images'] as List).first['url']
            : (j['coverImage'] as String?),
        roomTypes: (j['roomTypes'] as List? ?? [])
            .map((r) => RoomType.fromJson(r))
            .toList(),
        amenities: ((j['amenities'] as List?) ?? [])
            .map((a) => (a['amenity']?['name'] ?? '') as String)
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

String hotelDisplayName(String name, String city) {
  final cityName = city.trim();
  if (cityName.isEmpty) return name.trim();

  var displayName = name.replaceAll(
    RegExp('\\b${RegExp.escape(cityName)}\\b', caseSensitive: false),
    ' ',
  );
  if (displayName == name && cityName.contains(' ')) {
    final firstCityWord = cityName.split(RegExp(r'\s+')).first;
    displayName = name.replaceAll(
      RegExp('\\b${RegExp.escape(firstCityWord)}\\b', caseSensitive: false),
      ' ',
    );
  }

  final cleaned = displayName
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,.-]+|[\s,.-]+$'), '')
      .trim();
  return cleaned.isEmpty ? name.trim() : cleaned;
}

class RoomType {
  final String id;
  final String name;
  final int maxGuests;
  final int pricePerNight;
  final int totalRooms;

  RoomType({
    required this.id,
    required this.name,
    required this.maxGuests,
    required this.pricePerNight,
    required this.totalRooms,
  });

  factory RoomType.fromJson(Map<String, dynamic> j) => RoomType(
        id: j['id'],
        name: j['name'],
        maxGuests: (j['maxGuests'] ?? 2) as int,
        pricePerNight: (j['pricePerNight'] ?? 0) as int,
        totalRooms: (j['totalRooms'] ?? 1) as int,
      );
}

class HotelPostNotification {
  final String id;
  final String hotelId;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;

  const HotelPostNotification({
    required this.id,
    required this.hotelId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
  });

  bool get isRead => readAt != null;

  factory HotelPostNotification.fromJson(Map<String, dynamic> json) =>
      HotelPostNotification(
        id: json['id'] as String,
        hotelId: json['hotelId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
        imageUrl: json['imageUrl'] as String?,
      );
}

class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        fullName: j['fullName'],
        phone: j['phone'] as String?,
        role: j['role'],
      );
}

class Booking {
  final String id;
  final String reference;
  final String hotelName;
  final String? hotelImage;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int guests;
  final int totalPrice;
  final String status;

  Booking({
    required this.id,
    required this.reference,
    required this.hotelName,
    this.hotelImage,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guests,
    required this.totalPrice,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> j) {
    final images = (j['hotel']?['images'] as List?) ?? const [];
    return Booking(
      id: j['id'],
      reference: j['reference'],
      hotelName: j['hotel']?['name'] ?? '',
      hotelImage: images.isNotEmpty ? images.first['url'] : null,
      roomName: j['roomType']?['name'] ?? '',
      checkIn: DateTime.parse(j['checkIn']),
      checkOut: DateTime.parse(j['checkOut']),
      nights: j['nights'] ?? 0,
      guests: j['guests'] ?? 1,
      totalPrice: j['totalPrice'] ?? 0,
      status: j['status'] ?? 'PENDING',
    );
  }
}
