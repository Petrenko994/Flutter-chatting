import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';
import '../models/workspace_model.dart';

class ApiService {
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  static Future<List<Message>> fetchMessages(
      String workspaceId, String channelId) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/workspaces/$workspaceId/channels/$channelId/messages'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((message) => Message.fromJson(message)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<Message> sendMessage(
      String workspaceId, String channelId, String content) async {
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/workspaces/$workspaceId/channels/$channelId/messages'),
      body: jsonEncode({'content': content}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message');
    }
  }

  static Future<List<Workspace>> fetchWorkspaces() async {
    final Map<String, String> queryParams = {
      'param1': 'value1',
      'param2': 'value2',
    };
    final Uri uri = Uri.parse('$_baseUrl/organisation/workspaces')
        .replace(queryParameters: queryParams);
    final http.Response response = await http.get(uri);

    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((workspace) => Workspace.fromJson(workspace)).toList();
    } else {
      throw Exception('Failed to load workspaces');
    }
  }

  static Future<Message> replyToThread(
      String parentMessageId, String content) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/$parentMessageId/replies'),
      body: jsonEncode({'content': content}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to reply to thread');
    }
  }

  // Add more API methods as needed
}
