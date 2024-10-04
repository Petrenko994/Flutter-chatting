import 'dart:convert';
import 'dart:io';
import 'package:ainaglam/models/threadmsg_model.dart';
import 'package:ainaglam/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ainaglam/models/message_model.dart';
import 'package:ainaglam/models/channel_model.dart';
import 'package:ainaglam/models/coworker_model.dart';
import 'package:ainaglam/models/conversation_model.dart';
import 'package:ainaglam/services/chat_service.dart';
import 'package:ainaglam/services/thread_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ThreadService _threadService = ThreadService();
  late IO.Socket? _socket;

  List<Message> _messages = [];
  List<ThreadMsg> _threadMessages = [];
  Message? _selectedMessage;
  bool _isLoading = false;

  String? _errorMessage;
  String? _currentMessageId;
  Coworker? _user;
  Channel? _channelData;
  Conversation? _convData;
  String? _uploadedImageName;
  String? _uploadedVideoName;
  String? _currentChannlId;
  String? _currentConvId;

  List<Message> get messages => _messages;
  List<ThreadMsg> get threadMessages => _threadMessages;
  Message? get selectedMessage => _selectedMessage;
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;
  String? get currentMessageId => _currentMessageId;
  Coworker? get user => _user;
  Channel? get channelData => _channelData;
  Conversation? get convData => _convData;
  String? get uploadedImageName => _uploadedImageName;
  String? get uploadedVideoName => _uploadedVideoName;

  // connect to Socket.IO server
  void connect() {
    _socket = IO.io(
        dotenv.env['API_PUBLIC_SOCKET'],
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to the socket server');
    });

    // Listen for messages from the server
    _socket!.on('message', (data) {
      Message receivedMessage = Message.fromJson(data['newMessage']);

      _messages.add(receivedMessage);
      messageView(receivedMessage);
      notifyListeners(); // Notify UI about the new message
    });

    _socket!.on('channel-updated', (updatedChannel) {
      _channelData = Channel.fromJson(updatedChannel);
      notifyListeners();
    });

    _socket!.on('convo-updated', (updatedConversation) {
      _convData = Conversation.fromJson(updatedConversation);
      notifyListeners();
    });

    _socket!.on('message-update', (data) {
      int index = _messages.indexWhere((item) => item.id == data['_id']);
      // _messages[index].content = data['updatedContent'];
    });
    _socket!.on('message-updated', (data) {
      if (data['id'] == _selectedMessage!.id) {
        Message updated_msg = Message.fromJson(data['message']);
        int index = _messages.indexWhere((item) => item.id == data['id']);
        _messages[index] = updated_msg;
        _selectedMessage = updated_msg;
      }

      if (data['isThread']) {
        ThreadMsg msg = ThreadMsg.fromJson(data['message']);
        int index = _threadMessages.indexWhere((item) => item.id == data['id']);
        _threadMessages[index] = msg;
        _selectedMessage?.threadReplies.add(msg.sender);
      } else {
        Message msg = Message.fromJson(data['message']);
        int index = _messages.indexWhere((item) => item.id == data['id']);
        _messages[index] = msg;
      }
      notifyListeners();
    });
    _socket!.on('thread-message', (data) {
      ThreadMsg receivedMessage = ThreadMsg.fromJson(data['newMessage']);
      _threadMessages.add(receivedMessage);
      notifyListeners(); // Notify UI about the new message
    });

    _socket!.on('message-delete', (data) {
      _messages.removeWhere((item) => item.id == data['messageId']);
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from the socket server');
    });
  }

  void disconnect() {
    _socket!.disconnect();
    _socket!
        .clearListeners(); // Important: Clears all listeners to prevent duplication
  }

  Future<void> fetchChannelData(String channelId) async {
    _isLoading = true;
    _currentChannlId = null;
    notifyListeners();
    try {
      final response = await _chatService.fetchChannelData(channelId);
      if (response['success'] == true) {
        Map<String, dynamic> channelJson =
            json.decode(response['data'])['data'];
        _channelData = Channel.fromJson(channelJson);
        _currentChannlId = _channelData!.id;
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConversationData(String conversationlId) async {
    _isLoading = true;
    _currentConvId = null;
    notifyListeners();
    try {
      final response =
          await _chatService.fetchConversationData(conversationlId);
      if (response['success'] == true) {
        Map<String, dynamic> convJson = json.decode(response['data'])['data'];
        _convData = Conversation.fromJson(convJson);
        _currentConvId = _convData!.id;
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChannelMessages(
      String workspaceId, String channelId) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final response =
          await _chatService.fetchChannelMessages(workspaceId, channelId);
      if (response['success'] == true) {
        List<dynamic> jsonMap = json.decode(response['data'])['data'];

        _messages = jsonMap.map((msg) => Message.fromJson(msg)).toList();

        _user = response['user'];
        _socket?.emit("channel-open", {"id": channelId, 'userId': _user!.id});
      } else {
        _errorMessage = response['msg'];
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConversationMessages(
      String workspaceId, String conversationlId) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _chatService.fetchConversationMessages(
          workspaceId, conversationlId);
      if (response['success'] == true) {
        List<dynamic> jsonMap = json.decode(response['data'])['data'];
        _messages = jsonMap.map((msg) => Message.fromJson(msg)).toList();
        _user = response['user'];
        _socket
            ?.emit("convo-open", {"id": conversationlId, 'userId': _user!.id});
        // print(_user!.displayName);
      } else {
        _errorMessage = response['msg'];
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentMessageId(String? id) {
    _currentMessageId = id;
    notifyListeners();
  }

  Future<void> deleteMessage(Message message) async {
    _socket?.emit('message-delete', {
      'channelId': message.channel,
      'messageId': message.id,
      'userId': user!.id,
      'isThread': false
    });
    _messages.remove(message);
    notifyListeners();
  }

  Future<void> deleteThreadMessage(
      ThreadMsg message, Coworker user, String channelId) async {
    _socket?.emit('message-delete', {
      'channelId': channelId,
      'messageId': message.id,
      'userId': user.id,
      'isThread': true
    });
    _threadMessages.remove(message);
    notifyListeners();
  }

  Future<void> sendMessage(String workspaceId, String channelId,
      Map<String, dynamic> message, bool isChannel) async {
    final msg = {
      'message': message,
      'organisation': workspaceId,
      'hasNotOpen': isChannel
          ? channelData!.collaborators.where((c) => c.id != user!.id).toList()
          : convData!.collaborators.where((c) => c.id != user!.id).toList(),
      'isPublic': isChannel ? true : false
    };
    if (isChannel == true) {
      _currentChannlId = channelId;
      msg['channelId'] = channelId;
      msg['channelName'] = channelData!.name;
      msg['collaborators'] = channelData!.collaborators;
    } else {
      _currentConvId = channelId;
      msg['conversationId'] = channelId;
      msg['collaborators'] = convData!.collaborators;
      msg['isSelf'] =
          convData!.collaborators[0].id == convData!.collaborators[1].id;
    }
    _socket?.emit('message', msg);
    notifyListeners();
  }

  Future<void> addReact(Message message, String emoji) async {
    _selectedMessage = message;
    _socket?.emit('reaction', {
      'emoji': emoji,
      'id': message.id,
      'userId': user!.id,
      'isThread': false
    });
    _socket?.emit('message-view', {
      'messageId': message.id,
      'userId': user!.id,
    });
    notifyListeners();
  }

  void messageView(Message message) async {
    _socket?.emit('message-view', {
      'messageId': message.id,
      'userId': user!.id,
    });
    notifyListeners();
  }

  // Image upload
  Future<void> imageUploadByByte(Uint8List imgData, bool isThread) async {
    _uploadedImageName = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> response;
      if (isThread) {
        response = await _threadService.imageUploadByByte(imgData);
      } else {
        response = await _chatService.imageUploadByByte(imgData);
      }
      if (response['success'] == true) {
        String fileName = response['data']['filename'];
        _uploadedImageName = fileName;
      } else {
        _errorMessage = "Image uplaod failed.";
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> imageUploadByFile(File imgData, bool isThread) async {
    _uploadedImageName = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> response;
      if (isThread) {
        response = await _threadService.imageUploadByFile(imgData);
      } else {
        response = await _chatService.imageUploadByFile(imgData);
      }

      if (response['success'] == true) {
        String fileName = response['data']['filename'];
        _uploadedImageName = fileName;
      } else {
        _errorMessage = "Image upload failed";
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Video upload
  Future<void> videoUploadByByte(Uint8List imgData, bool isThread) async {
    _uploadedVideoName = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> response;
      if (isThread) {
        response = await _threadService.videoUploadByByte(imgData);
      } else {
        response = await _chatService.videoUploadByByte(imgData);
      }
      if (response['success'] == true) {
        String fileName = response['data']['filename'];
        _uploadedVideoName = fileName;
      } else {
        _errorMessage = "Video uplaod failed.";
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> videoUploadByFile(File imgData, bool isThread) async {
    _uploadedVideoName = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> response;
      if (isThread) {
        response = await _threadService.videoUploadByFile(imgData);
      } else {
        response = await _chatService.videoUploadByFile(imgData);
      }

      if (response['success'] == true) {
        String fileName = response['data']['filename'];
        _uploadedVideoName = fileName;
      } else {
        _errorMessage = "Image upload failed";
      }
    } catch (error) {
      _errorMessage = "An error occurred: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socket!.disconnect();
    super.dispose();
  }
}
