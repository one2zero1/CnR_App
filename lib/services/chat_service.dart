import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ChatService {
  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String message,
    String team = 'all', // "all" | "police" | "thief"
  }) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/chat/$roomId/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId, "message": message, "team": team}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
