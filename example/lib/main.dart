import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_manager/audio_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isPlaying = false;
  Duration _duration;
  Duration _position;
  num _slider;
  String _error;
  num curIndex = 0;
  String _path;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  void dispose() {
    // 释放所有资源
    AudioManager.instance.stop();
    super.dispose();
  }

  final list = [
    {
      "title": "Assets",
      "desc": "local assets playback",
      "url": "assets/audio.mp3",
      "cover": "assets/ic_launcher.png"
    },
    {
      "title": "network",
      "desc": "network resouce playback",
      "url": "https://s3.amazonaws.com/pb_previews/264_sunday-at-the-park/264_full_sunday-at-the-park_0159_preview.mp3",
      "cover":
          "https://avatars0.githubusercontent.com/u/30790621?s=88&u=9421b3089fb9ba30b4433147252960ca07d5d1cf&v=4"
    },
  ];

  loadData() async {
    final dir = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = dir.listSync();
    for (var file in files) {
      list.add({
        "title": "local",
        "desc": "local file",
        "url": "file://${file.path}",
        "cover":
            "http://p1.music.126.net/MVevKfyCw8InBCEmWX1NoQ==/109951164502635067.jpg?param=300x300"
      });
    }
    setState(() {});
  }

  void setupAudio(int idx) {
    final item = list[idx];
    curIndex = idx;
    _path = item["url"];
    AudioManager.instance
        .start(item["url"], item["title"],
            desc: item["desc"], cover: item["cover"])
        .then((err) {
      print(err);
    });

    AudioManager.instance.onEvents((events, args) {
      print("$events, $args");
      switch (events) {
        case AudioManagerEvents.ready:
          print("ready to play");
          AudioManager.instance.seekTo(Duration(seconds: 10));
          break;
        case AudioManagerEvents.buffering:
          print("buffering $args");
          break;
        case AudioManagerEvents.playstatus:
          isPlaying = AudioManager.instance.isPlaying;
          setState(() {});
          break;
        case AudioManagerEvents.timeupdate:
          _duration = AudioManager.instance.duration;
          _position = AudioManager.instance.position;
          _slider = _position.inMilliseconds / _duration.inMilliseconds;
          setState(() {});
          AudioManager.instance.updateLrc(args["position"].toString());
          // print(AudioManager.instance.info);
          break;
        case AudioManagerEvents.error:
          _error = args;
          setState(() {});
          break;
        case AudioManagerEvents.next:
          next();
          break;
        case AudioManagerEvents.previous:
          previous();
          break;
        case AudioManagerEvents.ended:
          next();
          break;
        default:
          break;
      }
    });
  }

  void next() {
    print("next audio");
    int idx = (curIndex + 1) % list.length;
    setupAudio(idx);
  }

  void previous() {
    print("previous audio");
    int idx = curIndex - 1;
    idx = idx < 0 ? list.length - 1 : idx;
    setupAudio(idx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin audio player'),
          actions: <Widget>[
        new IconButton(
            icon: new Icon(Icons.cloud_download),
            tooltip: 'Download song',
            onPressed: () {
              downloadFile('https://s3.amazonaws.com/pb_previews/386_park-day/386_full_park-day_0134_preview.mp3');
            }
        ),
          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView.separated(
                    itemBuilder: (context, item) {
                      return ListTile(
                        title: Text(list[item]["title"],
                            style: TextStyle(fontSize: 18)),
                        subtitle: Text(list[item]["desc"]),
                        onTap: () => setupAudio(item),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        Divider(),
                    itemCount: list.length),
              ),
              Center(child: Text('$_path')),
              Center(
                  child:
                      Text(_error != null ? _error : "lrc text: $_position")),
              bottomPanel()
            ],
          ),
        ),
      ),
    );
  }

  Future downloadFile(String s) async {
    final bytes = await readBytes(s);
    final dir = await getApplicationDocumentsDirectory();
    final time = new DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/$time.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists()) {
      list.add({
        "title": "local",
        "desc": "local file",
        "url": "file://${file.path}",
        "cover":
            "http://p1.music.126.net/MVevKfyCw8InBCEmWX1NoQ==/109951164502635067.jpg?param=300x300"
      });
      setState(() {});
    }
  }

  Widget bottomPanel() {
    return Column(children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            IconButton(
              onPressed: () => previous(),
              icon: Icon(
                Icons.skip_previous,
                size: 32.0,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () async {
                String status = await AudioManager.instance.playOrPause();
                print("await -- $status");
              },
              padding: const EdgeInsets.all(0.0),
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 48.0,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () => next(),
              icon: Icon(
                Icons.skip_next,
                size: 32.0,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blue,
            thumbShape: RoundSliderThumbShape(
              disabledThumbRadius: 5,
              enabledThumbRadius: 5,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: 10,
            ),
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey,
          ),
          child: Slider(
            value: _slider ?? 0,
            onChanged: (value) {
              setState(() {
                _slider = value;
              });
            },
            onChangeEnd: (value) {
              if (_duration != null) {
                Duration msec = Duration(
                    milliseconds: (_duration.inMilliseconds * value).round());
                AudioManager.instance.seekTo(msec);
              }
            },
          )),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: _timer(context),
      ),
    ]);
  }

  Widget _timer(BuildContext context) {
    var style = TextStyle(color: Colors.black);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Text(
          _formatDuration(_position),
          style: style,
        ),
        Text(
          _formatDuration(_duration),
          style: style,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d == null) return "--:--";
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = ((minute < 10) ? "0$minute" : "$minute") +
        ":" +
        ((second < 10) ? "0$second" : "$second");
    return format;
  }
}
