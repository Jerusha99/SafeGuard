class AppSettings {
  final String? id;
  final String deviceId;
  final bool voiceDetectionEnabled;
  final List<String> voiceKeywords;
  final bool notificationsEnabled;
  final String? emergencyContact;
  final bool shakeToSos;
  final bool locationInSos;
  final String quickMsgHelp;
  final String quickMsgNoSignal;
  final String quickMsgComing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppSettings({
    this.id,
    required this.deviceId,
    this.voiceDetectionEnabled = true,
    this.voiceKeywords = const ['help', 'emergency'],
    this.notificationsEnabled = true,
    this.emergencyContact,
    this.shakeToSos = true,
    this.locationInSos = true,
    this.quickMsgHelp = 'Help me!',
    this.quickMsgNoSignal = 'No signal. I might be offline.',
    this.quickMsgComing = "I'm coming",
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'voice_detection_enabled': voiceDetectionEnabled,
    'voice_keywords': voiceKeywords.join(','),
    'notifications_enabled': notificationsEnabled,
    'emergency_contact': emergencyContact,
    'shake_to_sos': shakeToSos,
    'location_in_sos': locationInSos,
    'quick_msg_help': quickMsgHelp,
    'quick_msg_no_signal': quickMsgNoSignal,
    'quick_msg_coming': quickMsgComing,
    'created_at':
        createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final keywordsStr = json['voice_keywords']?.toString() ?? 'help,emergency';
    final keywords = keywordsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return AppSettings(
      id: json['id']?.toString(),
      deviceId: json['device_id'] ?? '',
      voiceDetectionEnabled: json['voice_detection_enabled'] ?? true,
      voiceKeywords: keywords.isEmpty ? ['help', 'emergency'] : keywords,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emergencyContact: json['emergency_contact'],
      shakeToSos: json['shake_to_sos'] ?? true,
      locationInSos: json['location_in_sos'] ?? true,
      quickMsgHelp: json['quick_msg_help'] ?? 'Help me!',
      quickMsgNoSignal:
          json['quick_msg_no_signal'] ?? 'No signal. I might be offline.',
      quickMsgComing: json['quick_msg_coming'] ?? "I'm coming",
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  AppSettings copyWith({
    String? id,
    String? deviceId,
    bool? voiceDetectionEnabled,
    List<String>? voiceKeywords,
    bool? notificationsEnabled,
    String? emergencyContact,
    bool? shakeToSos,
    bool? locationInSos,
    String? quickMsgHelp,
    String? quickMsgNoSignal,
    String? quickMsgComing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      voiceDetectionEnabled:
          voiceDetectionEnabled ?? this.voiceDetectionEnabled,
      voiceKeywords: voiceKeywords ?? this.voiceKeywords,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      shakeToSos: shakeToSos ?? this.shakeToSos,
      locationInSos: locationInSos ?? this.locationInSos,
      quickMsgHelp: quickMsgHelp ?? this.quickMsgHelp,
      quickMsgNoSignal: quickMsgNoSignal ?? this.quickMsgNoSignal,
      quickMsgComing: quickMsgComing ?? this.quickMsgComing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
