import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'another_diary_screen.dart';
import 'diary_detail_screen.dart';
import 'diary_edit_screen.dart';
import 'diary_list_screen.dart';

class DiaryListView extends StatelessWidget {
  final List<Map<String, dynamic>> diaries; // 날짜별 일기가 아니라 개별 일기 리스트
  final void Function(Map<String, dynamic>) onDiaryTap;
  final void Function(Map<String, dynamic>) onDeleteDiary;

  const DiaryListView({
    Key? key,
    required this.diaries,
    required this.onDiaryTap,
    required this.onDeleteDiary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: diaries.map((diary) {
        return Dismissible(
          key: Key(diary['diarySeq'].toString()), // diarySeq를 사용하여 고유 키 설정
          background: Container(
            color: Colors.red,
            child: const Align(
              alignment: Alignment.centerRight, // 오른쪽에서 왼쪽으로 스와이프
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프
          onDismissed: (direction) {
            onDeleteDiary(diary); // 일기 삭제 처리
          },
          child: ListTile(
            title: Text(diary['contents']),
            subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(diary['createdAt']))),
            trailing: Text(diary['emoji'] ?? ''),
            onTap: () {
              onDiaryTap(diary);
            },
          ),
        );
      }).toList(),
    );
  }
}

class DiaryScreen extends StatefulWidget {
  final DateTime selectedDay;
  final VoidCallback onClose;

  const DiaryScreen({
    Key? key,
    required this.selectedDay,
    required this.onClose,
  }) : super(key: key);

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _currentDay;
  final TextEditingController _diaryController = TextEditingController();
  String? _token;
  List<Map<String, dynamic>> _diaries = []; // 날짜별 일기가 아니라 개별 일기 리스트

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _loadToken().then((_) {
      _fetchDiaries(); // 일기 데이터를 가져오는 함수 호출
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
  }

  Future<void> _fetchDiaries() async {
    if (_token == null) {
      print('Token is null');
      return;
    }

    final url = Uri.parse('https://haloworlds.org/api/diary/list?diaryDate=${DateFormat('yyyy-MM-dd').format(_currentDay)}');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = utf8.decode(response.bodyBytes); // UTF-8로 디코딩
      final Map<String, dynamic> decodedResponse = json.decode(responseBody);

      if (decodedResponse['isSuccess']) {
        final resultList = decodedResponse['result'] as List<dynamic>;

        // 선택한 날짜의 일기만 필터링
        final List<Map<String, dynamic>> tempDiaries = [];
        for (var dayData in resultList) {
          final diaryDate = dayData['diaryDate'] as String;
          if (diaryDate == DateFormat('yyyy-MM-dd').format(_currentDay)) {
            final diaries = dayData['diaries'] as List<dynamic>;
            tempDiaries.addAll(diaries.map((item) => item as Map<String, dynamic>).toList());
          }
        }

        setState(() {
          _diaries = tempDiaries;
        });
      } else {
        print('Failed to fetch diaries: ${decodedResponse['message']}');
      }
    } else {
      print('Failed to fetch diaries: ${response.body}');
    }
  }

  Future<void> _saveDiary(String content) async {
    const int maxContentLength = 1000;

    if (content.length > maxContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기는 최대 $maxContentLength 자까지 작성 가능합니다!')),
      );
      return;
    }

    if (_token == null) {
      print('Token is null');
      return;
    }

    final url = Uri.parse('https://haloworlds.org/api/diary');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode({
        'diaryDate': DateFormat('yyyy-MM-dd').format(_currentDay),
        'contents': content,
      }),
    );

    final responseBody = utf8.decode(response.bodyBytes);
    final decodedResponse = json.decode(responseBody);

    if (response.statusCode == 200 && decodedResponse['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기가 저장되었습니다.')),
      );

      setState(() {
        _diaryController.clear();
      });

      await _fetchDiaries(); // 일기 저장 후 목록 갱신

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiaryCreationResultScreen(
            diary: decodedResponse['result'],
          ),
        ),
      );
    } else {
      print('Failed to save diary: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 저장 실패: ${decodedResponse['message']}')),
      );
    }
  }

  void _navigateToDiaryCreation([String? content]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryCreationScreen(
          initialContent: content,
          onSave: (newContent) async {
            await _saveDiary(newContent);
            await _fetchDiaries(); // 일기 저장 후 목록 갱신
          },
        ),
      ),
    );
  }

  void _viewDiaryDetail(Map<String, dynamic> diary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          diary: diary,
          onEdit: () {
            Navigator.of(context).pop();
            _navigateToDiaryCreation(diary['contents']);
          },
        ),
      ),
    );
  }

  void _changeDate(int offset) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: offset));
      _fetchDiaries(); // 날짜 변경 시 일기 목록 갱신
    });
  }

  Future<void> _showExitConfirmationDialog() async {
    if (_diaryController.text.isNotEmpty) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            titlePadding: EdgeInsets.all(0),
            contentPadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            title: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Image.asset('assets/ic_alert.png'),
                ),
                const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Text(
                    '정말 나가시나요?',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              '지금까지 작성한 모든 내용이 사라져요!',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Color(0xF7F7F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Color(0xFFA89AFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('나가기'),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (shouldExit == true) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteDiary(Map<String, dynamic> diary) async {
    if (_token == null) {
      print('Token is null');
      return;
    }

    final diarySeq = diary['diarySeq']; // diarySeq를 사용하여 URL 생성
    final url = Uri.parse('https://haloworlds.org/api/diary/$diarySeq');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기가 삭제되었습니다.')),
      );

      await _fetchDiaries(); // 삭제 후 목록 갱신
    } else {
      print('Failed to delete diary: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 삭제 실패: ${decodedResponse['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeDate(-1),
            ),
            Text(
              DateFormat('yyyy년 M월 d일').format(_currentDay),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 30),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmationDialog,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _diaries.isNotEmpty
                  ? DiaryListView(
                diaries: _diaries,
                onDiaryTap: _viewDiaryDetail,
                onDeleteDiary: _deleteDiary,
              )
                  : TextField(
                controller: _diaryController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어볼까요?',
                ),
                minLines: 8,
              ),
            ),
            if (_diaries.isEmpty) // 일기가 없을 때만 표시
              const SizedBox(height: 8.0),
            if (_diaries.isEmpty) // 일기가 없을 때만 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pickypocky와 내 감정 보러가기 →',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA89AFD),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_diaryController.text.isNotEmpty) {
                        _saveDiary(_diaryController.text);
                      } else {
                        _navigateToDiaryCreation();
                      }
                    },
                    child: Image.asset('assets/analysis_start.png'),
                  ),
                ],
              ),
            if (_diaries.isEmpty) // 일기가 없을 때만 표시
              const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: () => _navigateToDiaryCreation(),
                child: Icon(Icons.add),
                tooltip: '새 일기 작성',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
