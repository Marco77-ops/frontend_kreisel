import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/services/audio_service.dart';
import 'package:kreisel_frontend/widgets/hover_button.dart';
import 'package:kreisel_frontend/utils/sound_utils.dart';

class MusicButton extends StatefulWidget {
  @override
  _MusicButtonState createState() => _MusicButtonState();
}

class _MusicButtonState extends State<MusicButton> {
  @override
  Widget build(BuildContext context) {
    return HoverButton(
      tooltip: AudioService().isPlaying ? 'Musik aus' : 'Musik an',
      onPressed: () => withClickSound(() {
        AudioService().toggleBackgroundMusic();
        setState(() {}); // Rebuild to update icon
      }),
      child: Icon(
        AudioService().isPlaying
            ? CupertinoIcons.music_note_2
            : CupertinoIcons.music_note,
        color: Color(0xFF007AFF),
        size: 28,
      ),
    );
  }
}