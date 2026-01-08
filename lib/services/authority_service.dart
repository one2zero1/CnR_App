import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class AuthorityService {
  Future<void> kickUser(
    String roomId,
    String hostId,
    String targetUserId,
  ) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/authority/$roomId/kick'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"host_id": hostId, "target_user_id": targetUserId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to kick user: ${response.body}');
    }
  }

  Future<void> forceChangeRole(
    String roomId,
    String hostId,
    String targetUserId,
    String newRole,
  ) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/authority/$roomId/role'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "host_id": hostId,
        "target_user_id": targetUserId,
        "new_role": newRole,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to change role: ${response.body}');
    }
  }

  Future<void> updateRoomSettings(
    String roomId,
    String hostId,
    Map<String, dynamic> settings,
  ) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/authority/$roomId/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"host_id": hostId, "settings": settings}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update settings: ${response.body}');
    }
  }
}
