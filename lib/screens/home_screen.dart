import 'dart:io';

import 'package:flutter/material.dart';

import '../models/map_info.dart';
import '../utils/database_helper.dart';
import 'add_map_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MapInfo> _maps = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final maps = await DatabaseHelper.instance.readAllMaps();
      setState(() {
        _maps = maps;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('地図の読み込みに失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openMap(MapInfo mapInfo) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => MapScreen(mapInfo: mapInfo),
          ),
        )
        .then((_) => _loadMaps());
  }

  Future<void> _addNewMap() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMapScreen()),
    );
    if (created == true) {
      await _loadMaps();
    }
  }

  Future<void> _renameMap(MapInfo mapInfo) async {
    final controller = TextEditingController(text: mapInfo.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('地図の名称を変更'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '地図の名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('変更'),
            ),
          ],
        );
      },
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != mapInfo.title &&
        mounted) {
      try {
        final updated = MapInfo(
          id: mapInfo.id,
          title: newTitle,
          imagePath: mapInfo.imagePath,
        );
        await DatabaseHelper.instance.updateMap(updated);
        await _loadMaps();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地図名を「$newTitle」に更新しました')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('名称の変更に失敗しました: $error')),
        );
      }
    }
  }

  Future<void> _deleteMap(MapInfo mapInfo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('地図を削除'),
          content: Text(
            '「${mapInfo.title}」を削除しますか？\n\n'
            'この地図に関連するメモもすべて削除されます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        if (mapInfo.id != null) {
          await DatabaseHelper.instance.deleteMap(mapInfo.id!);
        }

        if (mapInfo.imagePath != null) {
          final file = File(mapInfo.imagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「${mapInfo.title}」を削除しました')),
          );
        }
        await _loadMaps();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('地図の削除に失敗しました: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存した地図'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadMaps,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMap,
        tooltip: '地図を追加',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _maps.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMaps,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _maps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final map = _maps[index];
                      return _MapCard(
                        mapInfo: map,
                        onOpen: () => _openMap(map),
                        onRename: () => _renameMap(map),
                        onDelete: () => _deleteMap(map),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'まだ地図がありません',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '右下のボタンからカスタム地図を作成できます。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.mapInfo,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final MapInfo mapInfo;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.map, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mapInfo.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (mapInfo.imagePath != null &&
                        mapInfo.imagePath!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          mapInfo.imagePath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                      break;
                    case 'rename':
                      onRename();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('開く'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('名称を変更'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('削除'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
