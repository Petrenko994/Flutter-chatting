import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ainaglam/providers/auth_provider.dart';
import 'package:ainaglam/providers/home_provider.dart';
import 'package:ainaglam/models/message_model.dart';
import 'package:ainaglam/models/user_model.dart';
import 'package:ainaglam/models/coworker_model.dart';

class ChatService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final AuthProvider _authProvider = AuthProvider();
  final HomeProvider _homeProvider = HomeProvider();

  Future<Map<String, dynamic>> fetchConversationMessages(
      String workspaceId, String conversationId) async {
    User? userData = await _authProvider.loadAuthData();
    Coworker? user = await _homeProvider.loadUserFromPrefs();
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/messages?conversation=$conversationId&organisation=$workspaceId'),
      headers: {'Authorization': 'Bearer ${userData?.token}'},
    );

    if (response.statusCode == 201) {
      return {'success': true, 'msg': '', 'data': response.body, 'user': user};
    } else {
      return {
        'success': false,
        'msg': 'Failed to fetch messages',
        'data': response.body
      };
    }
  }

  Future<Map<String, dynamic>> fetchChannelMessages(
      String workspaceId, String channelId) async {
    User? userData = await _authProvider.loadAuthData();
    Coworker? user = await _homeProvider.loadUserFromPrefs();
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/messages?channelId=$channelId&organisation=$workspaceId'),
      headers: {'Authorization': 'Bearer ${userData?.token}'},
    );
    if (response.statusCode == 201) {
      return {
        "success": true,
        "msg": "Fetched data",
        "data": response.body,
        'user': user
      };
    } else {
      return {
        "success": false,
        "msg": "Failed to fetch data with status: ${response.statusCode}",
        "data": null
      };
    }
  }

  Future<Map<String, dynamic>> fetchChannelData(String channelId) async {
    User? userData = await _authProvider.loadAuthData();
    final response = await http.get(
      Uri.parse('$_baseUrl/channel/$channelId'),
      headers: {'Authorization': 'Bearer ${userData?.token}'},
    );

    if (response.statusCode == 201) {
      return {'success': true, 'msg': '', 'data': response.body};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': response.body
      };
    }
  }

  Future<Map<String, dynamic>> fetchConversationData(
      String conversationId) async {
    User? userData = await _authProvider.loadAuthData();
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/$conversationId'),
      headers: {'Authorization': 'Bearer ${userData?.token}'},
    );

    if (response.statusCode == 201) {
      return {'success': true, 'msg': '', 'data': response.body};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': response.body
      };
    }
  }

  Future<Map<String, dynamic>> imageUploadByFile(File img) async {
    User? userData = await _authProvider.loadAuthData();

    final uri = Uri.parse('$_baseUrl/messages/image-upload');
    var request = http.MultipartRequest('POST', uri);

    Map<String, String> headers = {
      'Authorization':
          'Bearer ${userData!.token}', // Example header for authorization
      'Content-Type': 'multipart/form-data', // Set Content-Type
    };
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('image', img.path));
    final response = await request.send();

    String responseBody = await response.stream.bytesToString();
    var decodedJson = jsonDecode(responseBody);
    print("Parsed JSON: $decodedJson");
    if (response.statusCode == 200) {
      return {'success': true, 'msg': '', 'data': decodedJson};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': decodedJson
      };
    }
  }

  Future<Map<String, dynamic>> imageUploadByByte(Uint8List img) async {
    User? userData = await _authProvider.loadAuthData();

    final uri = Uri.parse('$_baseUrl/messages/image-upload');
    var request = http.MultipartRequest('POST', uri);

    Map<String, String> headers = {
      'Authorization':
          'Bearer ${userData!.token}', // Example header for authorization
      'Content-Type': 'multipart/form-data', // Set Content-Type
    };
    request.headers.addAll(headers);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        img,
        filename: 'image.png',
        // contentType: MediaType('image', 'png'),
      ),
    );
    final response = await request.send();

    String responseBody = await response.stream.bytesToString();
    var decodedJson = jsonDecode(responseBody);
    print("Parsed JSON: $decodedJson");
    if (response.statusCode == 200) {
      return {'success': true, 'msg': '', 'data': decodedJson};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': decodedJson
      };
    }
  }

  Future<Map<String, dynamic>> videoUploadByFile(File img) async {
    User? userData = await _authProvider.loadAuthData();

    final uri = Uri.parse('$_baseUrl/messages/file-upload');
    var request = http.MultipartRequest('POST', uri);

    Map<String, String> headers = {
      'Authorization':
          'Bearer ${userData!.token}', // Example header for authorization
      'Content-Type': 'multipart/form-data', // Set Content-Type
    };
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', img.path));
    final response = await request.send();

    String responseBody = await response.stream.bytesToString();
    var decodedJson = jsonDecode(responseBody);
    print("Parsed JSON: $decodedJson");
    if (response.statusCode == 200) {
      return {'success': true, 'msg': '', 'data': decodedJson};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': decodedJson
      };
    }
  }

  Future<Map<String, dynamic>> videoUploadByByte(Uint8List img) async {
    User? userData = await _authProvider.loadAuthData();

    final uri = Uri.parse('$_baseUrl/messages/file-upload');
    var request = http.MultipartRequest('POST', uri);

    Map<String, String> headers = {
      'Authorization':
          'Bearer ${userData!.token}', // Example header for authorization
      'Content-Type': 'multipart/form-data', // Set Content-Type
    };
    request.headers.addAll(headers);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        img,
        filename: 'video',
        // contentType: MediaType('image', 'png'),
      ),
    );
    final response = await request.send();

    String responseBody = await response.stream.bytesToString();
    var decodedJson = jsonDecode(responseBody);
    print("Parsed JSON: $decodedJson");
    if (response.statusCode == 200) {
      return {'success': true, 'msg': '', 'data': decodedJson};
    } else {
      return {
        'success': false,
        'msg': 'Failed to load messages',
        'data': decodedJson
      };
    }
  }

  Future<Map<String, dynamic>> updatProfile(
      String username,
      String displayName,
      String orgId,
      Uint8List? avatarBytes,
      File? avatarFile,
      bool? isMobile) async {
    User? userData = await _authProvider.loadAuthData();

    final uri = Uri.parse('$_baseUrl/user');
    var request = http.MultipartRequest('PUT', uri);

    Map<String, String> headers = {
      'Authorization':
          'Bearer ${userData!.token}', // Example header for authorization
      'Content-Type': 'multipart/form-data', // Set Content-Type
    };
    request.headers.addAll(headers);
    if (isMobile != null) {
      if (isMobile) {
        request.files.add(await http.MultipartFile.fromPath(
            'file', avatarFile!.path,
            filename: 'avatar'));
      } else {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            avatarBytes!,
            filename: 'avatar',
          ),
        );
      }
    }

    request.fields['organisationId'] = orgId;
    request.fields['usernam'] = username;
    request.fields['displayName'] = displayName;

    final response = await request.send();

    String responseBody = await response.stream.bytesToString();
    var decodedJson = jsonDecode(responseBody);
    Coworker? user = Coworker.fromJson(decodedJson);
    _homeProvider.saveUserToPrefs(user);

    print("Parsed JSON: $decodedJson");
    await _homeProvider.loadUserFromPrefs();
    if (response.statusCode == 200) {
      return {'success': true, 'msg': '', 'data': decodedJson};
    } else {
      return {
        'success': false,
        'msg': 'Failed to update the profile',
        'data': decodedJson
      };
    }
  }
}
