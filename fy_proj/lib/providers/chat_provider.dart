import 'package:flutter/material.dart';
// import '../services/chat_api.dart'; // Assume this is implemented

class ChatProvider extends ChangeNotifier {
  final List<Map<String, String>> _messages = [];
  // final ChatApiService _chatApiService = ChatApiService(); // Assume this is implemented
  
  List<Map<String, String>> get messages => _messages;
  
  Future<void> sendMessage(String message) async {
    // Add user message
    _messages.add({"role": "user", "text": message});
    notifyListeners();
    
    try {
      // Get response from the API
      // final response = await _chatApiService.getChatResponse(message);
      
      // Add bot response
      // _messages.add({"role": "bot", "text": response});
      notifyListeners();
    } catch (e) {
      // Handle error
      _messages.add({"role": "bot", "text": "Sorry, I couldn't process your request."});
      notifyListeners();
    }
  }
}