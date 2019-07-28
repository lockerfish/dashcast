import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Boring Show!',
      home: BoringPage(),
    );
  }
}

class BoringPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DashCastApp(),
      ),
    );
  }
}

class DashCastApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          flex: 9,
          child: Placeholder(),
        ),
        Flexible(
          flex: 2,
          child: PlaybackButtons(),
        )
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PlaybackButtons(),
      ],
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonsState createState() => _PlaybackButtonsState();
}

class _PlaybackButtonsState extends State<PlaybackButtons> {
  bool _isPaused = false;
  FlutterSound _sound;
  double _playPosition;
  double _maxDuration;
  String _currentTime;
  StreamSubscription<PlayStatus> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    _playPosition = 0.0;
    _maxDuration = 0.0;
    _currentTime = '00:00:00';
  }

  Future<String> setupMusicFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/surf_skimmy.mp3');
    if (!await file.exists()) {
      var data = await rootBundle.load('assets/surf_skimmy.mp3');
      await file.writeAsBytes(data.buffer.asInt8List());
    }
    return file.path;
  }

  void _stop() async {
    await _sound.stopPlayer();
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
    setState(() {
      _currentTime = '00:00:00';
      _playPosition = 0.0;
    });
  }

  void _pause() async {
    await _sound.pausePlayer();
    setState(() => _isPaused = true);
  }

  void _play() async {
    if (!_isPaused) {
      var uri = await setupMusicFile();
      await _sound.startPlayer(uri);
      _playerSubscription = _sound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt());
          String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
          setState(() {
            _maxDuration = e.duration;
            _playPosition = e.currentPosition;
            _currentTime = txt.substring(0, 8);
          });
        }
      });
    } else {
      _sound.resumePlayer();
      setState(() => _isPaused = false);
    }
  }

  void _fastForward() {
    // forward 1 second
    _sound.seekToPlayer((_playPosition + 1000.0).toInt());
  }

  void _rewind() {
    // rewind 1 second
    _sound.seekToPlayer((_playPosition - 1000.0).toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Slider(
          value: _playPosition,
          min: 0.0,
          max: _maxDuration,
          onChanged: (double value) async {
            await _sound.seekToPlayer(value.toInt());
          },
          divisions: 1000,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: (_sound.isPlaying ? () => _rewind() : null),
            ),
            IconButton(
                icon: _sound.isPlaying && !_isPaused
                    ? Icon(Icons.pause)
                    : Icon(Icons.play_arrow),
                onPressed: () {
                  if (_sound.isPlaying && !_isPaused) {
                    _pause();
                  } else {
                    _play();
                  }
                }),
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: (_sound.isPlaying ? () => _stop() : null),
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: (_sound.isPlaying ? () => _fastForward() : null),
            ),
          ],
        ),
        Text(_currentTime),
      ],
    );
  }
}
