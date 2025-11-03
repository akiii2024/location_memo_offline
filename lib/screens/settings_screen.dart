import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_info.dart';
import '../utils/backup_service.dart';
import '../utils/theme_provider.dart';
import 'about_app_screen.dart';
import 'map_list_screen.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final success = await BackupService.shareBackupFile();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'バックアップを作成しました' : 'バックアップの作成に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('バックアップの作成中にエラーが発生しました: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.importData(context);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('バックアップの読み込み中にエラーが発生しました: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _SectionHeader(title: '表示'),
          Card(
            child: SwitchListTile(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              title: const Text('ダークモード'),
              subtitle: const Text('ライト / ダークテーマを切り替えます'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'データ管理'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('バックアップを書き出す'),
                  subtitle: const Text('全メモと地図をJSONファイルに保存します'),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isExporting ? null : _exportBackup,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('バックアップを読み込む'),
                  subtitle: const Text('JSONバックアップファイルからデータを復元します'),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isImporting ? null : _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'ナビゲーション'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('地図一覧'),
                  subtitle: const Text('保存した地図を管理します'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MapListScreen()),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('チュートリアル'),
                  subtitle: const Text('アプリの使い方をもう一度確認します'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TutorialScreen()),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('アプリについて'),
                  subtitle: const Text('ライセンス情報などを確認します'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'アプリ情報'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('バージョン'),
              subtitle: Text(AppInfo.version),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
