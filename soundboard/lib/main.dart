import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

void main() {
  runApp(const SoundBoardApp());
}

class SoundBoardApp extends StatelessWidget {
  const SoundBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sound Board',
      theme: ThemeData(useMaterial3: true),
      home: const SoundBoardPage(),
    );
  }
}

class SoundSlot {
  String label;
  String? filePath;

  SoundSlot({
    required this.label,
    this.filePath,
  });
}

class SoundBoardPage extends StatefulWidget {
  const SoundBoardPage({super.key});

  @override
  State<SoundBoardPage> createState() => _SoundBoardPageState();
}

class _SoundBoardPageState extends State<SoundBoardPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final List<SoundSlot> _slots = List.generate(
    6,
    (i) => SoundSlot(label: 'Sound ${i + 1}'),
  );

  bool _isRecording = false;
  int? _recordingIndex;

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _buildFilePath(int index) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/sound_slot_$index.m4a';
  }

  Future<void> _recordToSlot(int index) async {
    try {
      if (_isRecording && _recordingIndex == index) {
        final path = await _recorder.stop();
        setState(() {
          _isRecording = false;
          _recordingIndex = null;
          if (path != null) {
            _slots[index].filePath = path;
          }
        });
        return;
      }

      if (_isRecording) {
        await _recorder.stop();
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }

      final path = await _buildFilePath(index);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingIndex = index;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e')),
      );
    }
  }

  Future<void> _playSlot(int index) async {
    final path = _slots[index].filePath;
    if (path == null || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording in this slot yet')),
      );
      return;
    }

    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: $e')),
      );
    }
  }

  Future<void> _deleteSlot(int index) async {
    final path = _slots[index].filePath;

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    setState(() {
      _slots[index].filePath = null;
    });
  }

  Future<void> _renameSlot(int index) async {
    final controller = TextEditingController(text: _slots[index].label);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Rename sound'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Label',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _slots[index].label =
                      controller.text.trim().isEmpty
                          ? 'Sound ${index + 1}'
                          : controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildSlotCard(int index) {
    final slot = _slots[index];
    final hasSound =
        slot.filePath != null && File(slot.filePath!).existsSync();
    final isThisRecording = _isRecording && _recordingIndex == index;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Icon(
              hasSound ? Icons.graphic_eq : Icons.mic_none,
              size: 42,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _playSlot(index),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _recordToSlot(index),
              icon: Icon(isThisRecording ? Icons.stop : Icons.mic),
              label: Text(isThisRecording ? 'Stop' : 'Record'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _renameSlot(index),
                  child: const Text('Rename'),
                ),
                TextButton(
                  onPressed: hasSound ? () => _deleteSlot(index) : null,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Board'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) => buildSlotCard(index),
        ),
      ),
    );
  }
}