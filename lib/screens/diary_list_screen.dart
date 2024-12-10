import 'package:flutter/material.dart';

class DiaryListView extends StatelessWidget {
  final List<dynamic> diaries;
  final void Function(Map<String, dynamic>) onDiaryTap;

  const DiaryListView({
    Key? key,
    required this.diaries,
    required this.onDiaryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: diaries.length,
      itemBuilder: (context, index) {
        final diary = diaries[index];
        return ListTile(
          title: Text(diary['contents']),
          onTap: () => onDiaryTap(diary),
        );
      },
    );
  }
}
