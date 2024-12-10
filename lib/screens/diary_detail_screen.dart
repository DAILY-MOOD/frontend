import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DiaryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> diary;
  final VoidCallback onEdit;

  const DiaryDetailScreen({
    super.key,
    required this.diary,
    required this.onEdit,
  });

  Future<void> _deleteDiary(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final url = Uri.parse('https://haloworlds.org/api/diary/${diary['diarySeq']}');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기가 삭제되었습니다.')),
        );
        Navigator.of(context).pop(); // Return to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기 삭제 실패: ${responseBody['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 삭제 실패: ${response.body}')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 사용자 의도치 않은 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            '정말로 이 일기를 삭제하시겠습니까?',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼들 중앙 정렬
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                    },
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      _deleteDiary(context); // 일기 삭제
                    },
                    child: const Text('삭제'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diary['contents'] ?? '',
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              '작성 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(diary['createdAt']))}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Text(
              '태그: ${diary['tags']?.join(', ') ?? ''}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Text(
              '이모지: ${diary['emoji'] ?? ''}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
