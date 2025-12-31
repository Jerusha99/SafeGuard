class Contact {
  String? id;
  final String name;
  final String phoneNumber;
  final String? deviceId;

  Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'device_id': deviceId,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id']?.toString(),
    name: json['name'],
    phoneNumber: json['phone_number'],
    deviceId: json['device_id'],
  );
}
