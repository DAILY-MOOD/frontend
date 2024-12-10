import 'package:flutter/material.dart';

class DiaryCreationScreen extends StatelessWidget {
  final String? initialContent;
  final void Function(String) onSave;

  const DiaryCreationScreen({
    super.key,
    this.initialContent,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: initialContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 작성'),
        automaticallyImplyLeading: false, // 왼쪽 상단 뒤로가기 버튼 삭제
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // X 버튼 추가
            onPressed: () {
              Navigator.of(context).pop(); // 뒤로가기
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0), // 날짜와 제목 사이 간격 추가
            const Center(
              child: Text(
                '당신의 이야기를 기록해보세요',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50.0), // 제목과 글 작성 칸 사이 간격 추가
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어보세요',
                ),
                minLines: 8, // 최소 줄 수
              ),
            ),
            const SizedBox(height: 16.0), // 작성 완료 버튼과 입력 칸 사이 간격 추가
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(context).pop(); // 뒤로가기
                },
                child: const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
