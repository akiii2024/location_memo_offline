import 'package:flutter/material.dart';
import '../utils/app_info.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリについて'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アプリアイコンと基本情報
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppInfo.appName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'バージョン ${AppInfo.version}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // 開発者情報
            const Text(
              'Developed by',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.account_circle, size: 32),
                    title: Text(
                      'Akihisa Iwata',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Location Memo プロジェクト作成者'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.account_circle, size: 32),
                    title: Text(
                      'Haruto Tomikawa',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Location Memo オフライン版メンテナンス'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // 開発状況リンク
            const Text(
              '開発状況',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blueGrey.withOpacity(0.3)
                    : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueGrey
                      : Colors.blueGrey.shade200,
                ),
              ),
              child: const Text(
                'オフライン版ではオンラインの開発ボードへのリンクを提供していません。\n最新情報はアプリの更新履歴をご確認ください。',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

            const SizedBox(height: 16),

            // 開発版注意書き
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.shade900.withOpacity(0.3)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.shade700
                      : Colors.orange.shade200,
                  width: 1.5,
                ),
              ),
              child: Text(
                '⚠️ このアプリは開発版です。重要なデータは必ずバックアップを取ってからご利用ください。',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.shade200
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
