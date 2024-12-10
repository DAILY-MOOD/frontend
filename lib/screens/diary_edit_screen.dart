import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'diary_list_screen.dart'; // DiaryListScreen을 import

class DiaryCreationResultScreen extends StatefulWidget {
  final Map<String, dynamic> diary;

  const DiaryCreationResultScreen({Key? key, required this.diary}) : super(key: key);

  @override
  _DiaryCreationResultScreenState createState() => _DiaryCreationResultScreenState();
}

class _DiaryCreationResultScreenState extends State<DiaryCreationResultScreen> {
  late TextEditingController _contentController;
  late TextEditingController _emojiController;
  late List<String> _tags;
  String? _token;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.diary['contents']);
    _emojiController = TextEditingController(text: widget.diary['emoji_origin']);
    _tags = List<String>.from(widget.diary['tags'] ?? []);
    _loadToken();
    _loadSavedData();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contentController.text = prefs.getString('diary_content') ?? widget.diary['contents'];
      _emojiController.text = prefs.getString('diary_emoji') ?? widget.diary['emoji_origin'];
      _tags = prefs.getStringList('diary_tags') ?? List<String>.from(widget.diary['tags'] ?? []);
    });
  }

  Future<void> _saveDiary() async {
    final url = Uri.parse('https://haloworlds.org/api/diary/${widget.diary['diarySeq']}');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode({
        'diaryDate': widget.diary['diaryDate'],
        'contents': _contentController.text,
        'emoji': _emojiController.text,
        'tags': _tags,
      }),
    );

    final responseBody = utf8.decode(response.bodyBytes);
    final decodedResponse = json.decode(responseBody);

    if (response.statusCode == 200 && decodedResponse['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기가 저장되었습니다.')),
      );
      // 일기 저장 후 메인 화면으로 돌아가기
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    } else {
      print('일기 저장 실패: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 저장 실패: ${decodedResponse['message']}')),
      );
    }
  }

  Future<void> _deleteDiary() async {
    final url = Uri.parse('https://haloworlds.org/api/diary/${widget.diary['diarySeq']}');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    final responseBody = utf8.decode(response.bodyBytes);
    final decodedResponse = json.decode(responseBody);

    if (response.statusCode == 200 && decodedResponse['isSuccess']) {
      Navigator.of(context).pop();
    } else {
      print('일기 삭제 실패: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 삭제 실패: ${decodedResponse['message']}')),
      );
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diary_content', _contentController.text);
    await prefs.setString('diary_emoji', _emojiController.text);
    await prefs.setStringList('diary_tags', _tags);
  }

  @override
  void dispose() {
    _saveState();
    _contentController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String date = widget.diary['diaryDate'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0), // 간격 추가
            const Text('PickyPoky가 읽은 나의 일기', style: TextStyle(fontSize: 18)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _deleteDiary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16.0),
              Center(
                child: const Text('나의 감정', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emojiController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '이모지를 입력하세요',
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '일기 내용을 입력하세요',
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '키워드를 입력하세요',
                ),
                onSubmitted: (value) {
                  setState(() {
                    _tags.add(value);
                  });
                },
              ),
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: _saveDiary,
                  child: const Text('일기를 저장할게요'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
