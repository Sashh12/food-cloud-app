import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatMode {
  kitchen,
  support,
  bot,
  orderstatus,
}

class SharedPreferenceService {
  static Future<void> saveChatMode(ChatMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_chat_mode', mode.name);
  }

  static Future<ChatMode?> loadChatMode() async {
    final prefs = await SharedPreferences.getInstance();
    String? mode = prefs.getString('selected_chat_mode');
    if (mode != null) {
      return ChatMode.values.firstWhere((e) => e.name == mode);
    }
    return null;
  }

  static Future<void> saveMessagesForUser(
      String targetId,
      String userId,
      List<Map<String, dynamic>> messages,
      DateTime? lastFetchedTime,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      String jsonData = jsonEncode(messages);
      bool success = await prefs.setString('messages_${userId}_$targetId', jsonData);
      print("Saved messages: $success"); // Debug log

      if (lastFetchedTime != null) {
        await prefs.setString(
            'lastFetched_${userId}_$targetId', lastFetchedTime.toIso8601String());
      }
    } catch (e) {
      print("Error saving messages: $e");
    }
  }


  static List<Map<String, dynamic>> mergeMessages(List<String?> dataList) {
    List<Map<String, dynamic>> merged = [];
    for (String? data in dataList) {
      if (data != null) {
        merged.addAll(jsonDecode(data).cast<Map<String, dynamic>>());
      }
    }
    return merged;
  }

  static Future<List<Map<String, dynamic>>> loadMessagesForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allMessages = [];

    for (String key in prefs.getKeys()) {
      if (key.startsWith('messages_${userId}_')) {
        String? data = prefs.getString(key);
        String? lastFetched = prefs.getString('lastFetched_${userId}_${key.split('_').last}');

        if (lastFetched != null) {
          DateTime lastFetchedTime = DateTime.parse(lastFetched);
          if (DateTime.now().difference(lastFetchedTime) > Duration(hours: 1)) {
            // Delete expired messages
            await prefs.remove(key);
            await prefs.remove('lastFetched_${userId}_${key.split('_').last}');
            print("Deleted expired messages for $key");
            continue; // Skip adding expired messages
          }
        }

        if (data != null) {
          allMessages.addAll(jsonDecode(data).cast<Map<String, dynamic>>());
        }
      }
    }

    return allMessages;
  }



  static Future<DateTime?> loadLastFetchedTime(String userId, String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    String? timeStr = prefs.getString('lastFetched_${userId}_$targetId');
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  static Future<void> clearCacheForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    print("Clearing cache for $userId"); // Debug log
    await prefs.remove('messages_${userId}_kitchen');
    await prefs.remove('messages_${userId}_bot');
    await prefs.remove('messages_${userId}_orderstatus');
    await prefs.remove('selected_chat_mode');
  }


  // Optional: Clear manually if needed
  static Future<void> clearMessages(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages_$userId');
    await prefs.remove('chat_time_$userId');
  }

  static Future<void> saveKitchenMessages(
      String kitchenId, // This will be the logged-in kitchen UID
      String userId,
      List<Map<String, dynamic>> messages
      ) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'kitchen_${kitchenId}_user_${userId}_messages';
    String timeKey = 'kitchen_${kitchenId}_user_${userId}_time';

    await prefs.setString(key, jsonEncode(messages));
    await prefs.setString(timeKey, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>> loadKitchenMessages(
      String kitchenId,
      String userId,
      Function(DateTime?) updateLastFetchedTime,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'kitchen_${kitchenId}_user_${userId}_messages';
    String timeKey = 'kitchen_${kitchenId}_user_${userId}_time';

    String? cachedMessages = prefs.getString(key);
    String? cachedTime = prefs.getString(timeKey);

    if (cachedMessages != null && cachedTime != null) {
      DateTime cacheTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheTime) < Duration(hours: 1)) {
        updateLastFetchedTime(cacheTime); // tell UI the cached time!
        List decoded = jsonDecode(cachedMessages);
        List<Map<String, dynamic>> messages = decoded.cast<Map<String, dynamic>>();

        // Filter out messages that are older than the last fetched time
        messages = messages.where((msg) {
          DateTime msgTime = DateTime.parse(msg['timestamp']);
          return msgTime.isAfter(cacheTime);
        }).toList();

        return messages;
      } else {
        await prefs.remove(key);
        await prefs.remove(timeKey);
      }
    }
    return [];
  }

}
