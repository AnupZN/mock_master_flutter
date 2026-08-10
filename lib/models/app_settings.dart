import '../core/constants.dart';

class AppSettings {
  final String theme;
  final bool isDarkMode;
  final double fontSize;
  final int dailyTarget;
  final String userName;
  final String userTitle;
  final bool isAdmin;

  AppSettings({
    this.theme = DefaultSettings.theme,
    this.isDarkMode = DefaultSettings.isDarkMode,
    this.fontSize = DefaultSettings.fontSize,
    this.dailyTarget = DefaultSettings.dailyTarget,
    this.userName = DefaultSettings.userName,
    this.userTitle = DefaultSettings.userTitle,
    this.isAdmin = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] ?? DefaultSettings.theme,
      isDarkMode: json['isDarkMode'] ?? DefaultSettings.isDarkMode,
      fontSize: (json['fontSize'] ?? DefaultSettings.fontSize).toDouble(),
      dailyTarget: json['dailyTarget'] ?? DefaultSettings.dailyTarget,
      userName: json['userName'] ?? DefaultSettings.userName,
      userTitle: json['userTitle'] ?? DefaultSettings.userTitle,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'isDarkMode': isDarkMode,
      'fontSize': fontSize,
      'dailyTarget': dailyTarget,
      'userName': userName,
      'userTitle': userTitle,
      'isAdmin': isAdmin,
    };
  }

  AppSettings copyWith({
    String? theme,
    bool? isDarkMode,
    double? fontSize,
    int? dailyTarget,
    String? userName,
    String? userTitle,
    bool? isAdmin,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      userName: userName ?? this.userName,
      userTitle: userTitle ?? this.userTitle,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
