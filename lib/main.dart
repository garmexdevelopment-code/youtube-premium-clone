import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const YouTubePremiumClone());

class YouTubePremiumClone extends StatelessWidget {
  const YouTubePremiumClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F), elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  YoutubePlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isVideoPlaying = false;
  bool _isAudioMode = false;
  String _currentVideoId = '';
  String _currentVideoTitle = 'Loading...';
  String _currentChannel = '';
  
  bool _isLoggedIn = false;
  String _userEmail = '';

  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  void _startPlayback(String videoId, String title, String author) {
    _videoController?.dispose();
    _audioPlayer.stop();

    setState(() {
      _currentVideoId = videoId;
      _currentVideoTitle = title;
      _currentChannel = author;
      _isAudioMode = false;
      _isVideoPlaying = true;
      
      _videoController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    });
  }

  Future<void> _switchToAudioOnly() async {
    if (_currentVideoId.isEmpty) return;
    
    _videoController?.pause();
    setState(() {
      _isAudioMode = true;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(_currentVideoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      await _audioPlayer.setUrl(audioStream.url.toString());
      _audioPlayer.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background Audio Mode Active! You can lock phone.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio Stream Error! Trying again.')),
      );
    }
  }

  Future<void> _downloadMP3() async {
    if (_currentVideoId.isEmpty) return;

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading MP3 File... Please wait.')),
    );

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(_currentVideoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      
      Directory? downloadsDir = await getExternalStorageDirectory();
      String cleanTitle = _currentVideoTitle.replaceAll(RegExp(r'[^\w\s]+'), '');
      String path = "${downloadsDir!.path}/$cleanTitle.mp3";

      await Dio().download(audioStream.url.toString(), path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded successfully to: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed or permission denied.')),
      );
    }
  }

  void _showLoginDialog() {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Row(
          children: [
            Image.network('https://wikimedia.org', height: 24, width: 24, errorBuilder: (c, e, s) => const Icon(Icons.account_circle)),
            const SizedBox(width: 10),
            const Text('Sign in with Google', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: 'Enter your Gmail account', labelText: 'Email Address'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter account password', labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              if (emailController.text.contains('@gmail.com')) {
                setState(() {
                  _isLoggedIn = true;
                  _userEmail = emailController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $_userEmail')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Gmail address.')));
              }
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      YouTubeHomeScreen(onVideoSelect: _startPlayback),
      const Center(child: Text('Shorts Feed (Ad-Free)', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Subscriptions Panel', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Library & Offline MP3s', style: TextStyle(color: Colors.white, fontSize: 18))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.red, size: 32),
            const SizedBox(width: 6),
            const Text('YouTube', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -1)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              child: const Text('Premium', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          GestureDetector(
            onTap: _isLoggedIn ? null : _showLoginDialog,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 6.0),
              child: CircleAvatar(
                backgroundColor: _isLoggedIn ? Colors.green : Colors.blueAccent,
                radius: 15,
                child: Text(_isLoggedIn ? _userEmail.substring(0, 1).toUpperCase() : 'L', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isVideoPlaying)
            Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  _isAudioMode
                      ? Container(
                          height: 140,
                          color: Colors.black,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radio, size: 30, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('YMusic Background Audio Playing...', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : YoutubePlayer(controller: _videoController!, showVideoProgressIndicator: true, progressIndicatorColor: Colors.red),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentVideoTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
