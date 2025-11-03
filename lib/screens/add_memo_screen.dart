import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:geolocator/geolocator.dart';  // 一時的に無効化
import '../models/memo.dart';
import '../models/map_info.dart';
import '../utils/database_helper.dart';
import '../utils/collaboration_sync_coordinator.dart';
import '../utils/audio_service.dart';
import '../utils/image_helper.dart';
import 'location_picker_screen.dart';
import '../utils/default_values.dart';

class AddMemoScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final int? mapId;
  final int? layer;

  const AddMemoScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.mapId,
    this.layer,
  }) : super(key: key);

  @override
  _AddMemoScreenState createState() => _AddMemoScreenState();
}

class _AddMemoScreenState extends State<AddMemoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _discovererController = TextEditingController();
  final TextEditingController _specimenNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;
  bool _isSaving = false;
  DateTime? _discoveryTime;
  String? _selectedCategory;
  int? _selectedMapId;
  int? _layer;
  List<MapInfo> _maps = [];

  List<String> _imagePaths = []; // 保存済み画像パスのリスト
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  // キノコ詳細情報の状態変数
  String? _selectedMushroomHabitat;
  String? _selectedMushroomGrowthPattern;

  final List<String> _categories = [
    'カテゴリを選択してください',
    '植物',
    'キノコ',
    '動物',
    '昆虫',
    '鉱物',
    '化石',
    '地形',
    'その他',
  ];

  // キノコ専用の選択肢
  final List<String> _mushroomHabitatOptions = [
    '選択してください',
    '地面（土）',
    '木（生木）',
    '枯木',
    '落ち葉',
    '草地',
    '苔むした場所',
    'その他',
  ];

  final List<String> _mushroomGrowthPatternOptions = [
    '選択してください',
    '単生（1本のみ）',
    '群生（数本がまとまって生える）',
    '束生（根元から多数まとまる）',
  ];

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _selectedMapId = widget.mapId; // 渡された地図IDを設定
    _layer = widget.layer; // 現在のレイヤーを設定
    _discoveryTime = DateTime.now(); // デフォルトで現在時刻を設定
    _selectedCategory = _categories[0]; // デフォルトで最初のカテゴリを選択
    _loadMaps();
    _loadDefaultValues();
  }

  Future<void> _loadMaps() async {
    try {
      final maps = await DatabaseHelper.instance.readAllMaps();
      print('読み込んだ地図数: ${maps.length}');
      if (maps.isNotEmpty) {
        print(
            '地図一覧: ${maps.map((m) => 'ID:${m.id} タイトル:${m.title}').join(', ')}');
      }
      print('初期選択されたMapID: $_selectedMapId');

      // IDがnullの地図をチェック
      final mapsWithNullId = maps.where((map) => map.id == null).toList();
      if (mapsWithNullId.isNotEmpty) {
        print('警告: IDがnullの地図が${mapsWithNullId.length}個見つかりました');
        for (final map in mapsWithNullId) {
          print('  - タイトル: ${map.title}, imagePath: ${map.imagePath}');
        }
      }

      setState(() {
        _maps = maps;
        // 初期選択されたmapIdが実際の地図リストに存在するかチェック
        if (_selectedMapId != null) {
          final mapExists = _maps.any((map) => map.id == _selectedMapId);
          print('選択されたMapIDが存在するか: $mapExists');
          if (!mapExists) {
            // 存在しない場合はnullに設定（「地図を選択しない」を選択）
            print('選択されたMapIDが存在しないため、nullに設定します');
            _selectedMapId = null;
          }
        }
      });
      print('最終的な選択MapID: $_selectedMapId');
      print(
          '有効な地図数（IDがnullでない）: ${maps.where((map) => map.id != null).length}');
    } catch (e) {
      // エラーは無視（地図が存在しない場合もある）
      print('地図の読み込みでエラーが発生しました: $e');
    }
  }

  Future<void> _loadDefaultValues() async {
    final values = await DefaultValues.getAllDefaultValues();
    if (values['discoverer'] != null && values['discoverer']!.isNotEmpty) {
      _discovererController.text = values['discoverer']!;
    }
    if (values['specimenNumberPrefix'] != null &&
        values['specimenNumberPrefix']!.isNotEmpty) {
      _specimenNumberController.text = values['specimenNumberPrefix']!;
    }
    if (values['category'] != null && values['category']!.isNotEmpty) {
      if (_categories.contains(values['category'])) {
        setState(() {
          _selectedCategory = values['category'];
        });
      }
    }
    if (values['notes'] != null && values['notes']!.isNotEmpty) {
      _notesController.text = values['notes']!;
    }
  }

  Future<void> _selectLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // 利用可能な地図を取得
      final maps = await DatabaseHelper.instance.readAllMaps();
      MapInfo? selectedMap;

      // デフォルトの地図を選択（選択された地図がある場合はそれを使用）
      if (_selectedMapId != null && maps.isNotEmpty) {
        selectedMap = maps.firstWhere(
          (map) => map.id == _selectedMapId,
          orElse: () => maps.first,
        );
      } else if (maps.isNotEmpty) {
        selectedMap = maps.first;
      }

      final result = await Navigator.push<Map<String, double>>(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            mapInfo: selectedMap,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _latitude = result['latitude'];
          _longitude = result['longitude'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '位置を設定しました\n緯度: ${_latitude!.toStringAsFixed(6)}\n経度: ${_longitude!.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('位置選択中にエラーが発生しました: $e')),
      );
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _discoveryTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_discoveryTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _discoveryTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveMemo() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory == 'カテゴリを選択してください') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }

    // 保存確認ダイアログ
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('記録を保存'),
          content: const Text('この記録を保存しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 同じ地図の既存のメモを取得して次のピン番号を決定
      final existingMemos =
          await DatabaseHelper.instance.readMemosByMapId(_selectedMapId);
      final layerMemos = existingMemos
          .where((memo) => (memo.layer ?? 0) == (_layer ?? 0))
          .toList();
      int nextPinNumber = 1;
      if (layerMemos.isNotEmpty) {
        final maxPinNumber = layerMemos
            .where((memo) => memo.pinNumber != null)
            .map((memo) => memo.pinNumber!)
            .fold(0, (max, number) => number > max ? number : max);
        nextPinNumber = maxPinNumber + 1;
      }

      final memo = Memo(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        discoveryTime: _discoveryTime,
        discoverer: _discovererController.text.trim().isEmpty
            ? null
            : _discovererController.text.trim(),
        specimenNumber: _specimenNumberController.text.trim().isEmpty
            ? null
            : _specimenNumberController.text.trim(),
        category:
            _selectedCategory == 'カテゴリを選択してください' ? null : _selectedCategory,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        pinNumber: nextPinNumber, // 自動的に次の番号を割り当て
        mapId: _selectedMapId, // 選択された地図ID
        layer: _layer, // レイヤー番号
        audioPath: _audioPath, // 音声ファイルのパス
        imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null, // 画像パス配列
        // キノコ詳細情報（「選択してください」は保存しない）
        mushroomHabitat: _selectedMushroomHabitat == '選択してください'
            ? null
            : _selectedMushroomHabitat,
        mushroomGrowthPattern: _selectedMushroomGrowthPattern == '選択してください'
            ? null
            : _selectedMushroomGrowthPattern,
      );

      final savedMemo = await DatabaseHelper.instance.create(memo);
      try {
        await CollaborationSyncCoordinator.instance
            .onLocalMemoCreated(savedMemo);
      } catch (error, stackTrace) {
        debugPrint('Failed to sync memo creation: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('共同編集への同期に失敗しました: $error'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記録を保存しました！ピン番号: $nextPinNumber'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未設定';
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMushroomDetailsSummary() {
    final details = <String>[];

    if (_selectedMushroomHabitat != null &&
        _selectedMushroomHabitat != '選択してください') {
      details.add('発生場所: ${_selectedMushroomHabitat}');
    }
    if (_selectedMushroomGrowthPattern != null &&
        _selectedMushroomGrowthPattern != '選択してください') {
      details.add('生育状態: ${_selectedMushroomGrowthPattern}');
    }

    if (details.isEmpty) {
      return '';
    }

    return '\n• キノコ詳細: ${details.join(', ')}${details.length < 2 ? ' など' : ''}';
  }

  // 音声録音の開始/停止
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // 録音停止
      final path = await AudioService.stopRecording();
      if (path != null) {
        setState(() {
          _audioPath = path;
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('録音が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // 録音開始
      final success = await AudioService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('録音を開始しました'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        String errorMessage = '録音の開始に失敗しました';
        if (kIsWeb) {
          errorMessage = '録音の開始に失敗しました\n'
              '• HTTPS接続を確認してください\n'
              '• マイクへのアクセス許可を確認してください\n'
              '• ブラウザでマイクが有効か確認してください';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 音声再生の開始/停止
  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await AudioService.stopPlaying();
      setState(() {
        _isPlaying = false;
      });
    } else {
      final success = await AudioService.playAudio(_audioPath!);
      if (success) {
        setState(() {
          _isPlaying = true;
        });

        // 再生完了を監視
        Future.delayed(const Duration(seconds: 1), () async {
          while (AudioService.isPlaying && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      }
    }
  }

  // 音声削除
  Future<void> _deleteAudio() async {
    if (_audioPath != null) {
      await AudioService.deleteAudioFile(_audioPath!);
      setState(() {
        _audioPath = null;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音声メモを削除しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 画像を追加
  Future<void> _addImage() async {
    try {
      final imagePath = await ImageHelper.pickAndSaveImage(context);
      if (imagePath != null) {
        setState(() {
          _imagePaths.add(imagePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の追加に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 画像を削除
  Future<void> _removeImage(int index) async {
    if (index >= 0 && index < _imagePaths.length) {
      final imagePath = _imagePaths[index];

      // 確認ダイアログ
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('画像削除'),
          content: const Text('この画像を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // ファイルを削除
        await ImageHelper.deleteImage(imagePath);

        // リストから削除
        setState(() {
          _imagePaths.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // 画像を全て削除（画面を閉じる時のクリーンアップ用）
  Future<void> _clearAllImages() async {
    for (final imagePath in _imagePaths) {
      await ImageHelper.deleteImage(imagePath);
    }
    _imagePaths.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.initialLatitude != null && widget.initialLongitude != null
            ? const Text('選択地点の記録')
            : const Text('新しい記録'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: '保存',
            onPressed: _isSaving ? null : _saveMemo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 位置情報表示
            if (widget.initialLatitude != null &&
                widget.initialLongitude != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade600),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'マップで選択した地点の記録を作成中\n緯度: ${widget.initialLatitude!.toStringAsFixed(6)}\n経度: ${widget.initialLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 基本情報
            const Text('基本情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル *',
                border: OutlineInputBorder(),
                helperText: '必須項目',
              ),
            ),
            const SizedBox(height: 16),

            // カテゴリ選択
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  // カテゴリが変更された場合、キノコの詳細情報をリセット
                  if (value != 'キノコ') {
                    _selectedMushroomHabitat = null;
                    _selectedMushroomGrowthPattern = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // キノコが選択された場合の詳細フィールド
            if (_selectedCategory == 'キノコ') ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'キノコの詳細情報',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 発生場所
                      DropdownButtonFormField<String>(
                        value: _selectedMushroomHabitat,
                        decoration: const InputDecoration(
                          labelText: '発生場所',
                          border: OutlineInputBorder(),
                        ),
                        items: _mushroomHabitatOptions.map((habitat) {
                          return DropdownMenuItem(
                            value: habitat,
                            child: Text(habitat),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMushroomHabitat = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 生育状態
                      DropdownButtonFormField<String>(
                        value: _selectedMushroomGrowthPattern,
                        decoration: const InputDecoration(
                          labelText: '生育状態',
                          border: OutlineInputBorder(),
                        ),
                        items: _mushroomGrowthPatternOptions.map((pattern) {
                          return DropdownMenuItem(
                            value: pattern,
                            child: Text(pattern),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMushroomGrowthPattern = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 発見時間
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '発見日時',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDateTime(_discoveryTime)),
              ),
            ),
            const SizedBox(height: 16),

            // 発見者
            TextField(
              controller: _discovererController,
              decoration: const InputDecoration(
                labelText: '発見者',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 標本番号
            TextField(
              controller: _specimenNumberController,
              decoration: const InputDecoration(
                labelText: '標本番号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 地図選択
            if (_maps.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                key: ValueKey(_maps.length), // 地図リスト変更時に再構築
                value: _selectedMapId,
                decoration: const InputDecoration(
                  labelText: '地図',
                  border: OutlineInputBorder(),
                  helperText: 'この記録を関連付ける地図を選択',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('地図を選択しない'),
                  ),
                  // IDがnullでない地図のみを表示
                  ..._maps.where((map) => map.id != null).map((map) {
                    return DropdownMenuItem<int?>(
                      value: map.id,
                      child: Text(map.title),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMapId = value;
                  });
                },
              ),
            ] else ...[
              // 地図がない場合の表示
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '地図',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '使用可能な地図がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '地図を作成してから記録を関連付けることができます',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 詳細情報
            const Text('詳細情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容・説明',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 16),

            const Text('音声メモ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kIsWeb) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          'WebブラウザではHTTPS接続とマイクの許可が必要です。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleRecording,
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            label: Text(_isRecording
                                ? '🎙️ 録音停止'
                                : kIsWeb
                                    ? '🎙️ Web音声録音'
                                    : '🎙️ 音声録音'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isRecording ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_audioPath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _togglePlayback,
                            icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow),
                            color: Colors.blue,
                            tooltip: _isPlaying ? '再生停止' : '再生',
                          ),
                          IconButton(
                            onPressed: _deleteAudio,
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            tooltip: '削除',
                          ),
                        ],
                      ],
                    ),
                    if (_audioPath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.audiotrack,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '音声メモが録音されました。再生ボタンで内容を確認できます。',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isRecording) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.fiber_manual_record,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '録音中...',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 位置情報
            const Text('位置情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '位置情報',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _isLocationLoading ? null : _selectLocation,
                          icon: _isLocationLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.map),
                          label: const Text('位置設定'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (_latitude != null && _longitude != null)
                      Text(
                        '設定された位置：\n緯度: ${_latitude!.toStringAsFixed(6)}\n経度: ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      )
                    else
                      const Text(
                        '位置情報が設定されていません\n「位置設定」ボタンから地図で位置を選択してください',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMemo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('保存中...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text('記録を保存', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // 保存内容の説明
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '保存される内容:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• タイトル: ${_titleController.text.trim().isEmpty ? "未入力" : _titleController.text.trim()}\n'
                    '• カテゴリ: ${_selectedCategory ?? "未選択"}${_selectedCategory == 'キノコ' ? " (詳細情報入力済み)" : ""}\n'
                    '• 発見日時: ${_formatDateTime(_discoveryTime)}\n'
                    '• 発見者: ${_discovererController.text.trim().isEmpty ? "未入力" : _discovererController.text.trim()}\n'
                    '• 位置情報: ${_latitude != null && _longitude != null ? "設定済み" : "未設定"}\n'
                    '• 添付画像: ${_imagePaths.length}枚\n'
                    '• 音声メモ: ${_audioPath != null ? "録音済み" : "なし"}${_selectedCategory == 'キノコ' ? _getMushroomDetailsSummary() : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _discovererController.dispose();
    _specimenNumberController.dispose();
    _notesController.dispose();
    AudioService.dispose(); // AudioServiceのリソース解放
    // 保存されていない画像をクリーンアップ（メモ保存が完了していない場合のみ）
    // Note: 実際の実装では、画面を閉じる前に保存確認が必要
    super.dispose();
  }
}
