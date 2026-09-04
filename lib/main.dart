import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:video_player/video_player.dart';

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
  
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _isLoadingPlayer = false;
  String _currentVideoTitle = '';
  String _currentChannel = '';
  
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  Future<void> _startPlayback(String videoId, String title, String author) async {
    _videoController?.dispose();
    
    setState(() {
      _isLoadingPlayer = true;
      _isVideoPlaying = true;
      _currentVideoTitle = title;
      _currentChannel = author;
    });

    try {
      // YouTube එකෙන් සැබෑ වීඩියෝ ලින්ක් එක ලබා ගැනීම
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.muxed.withHighestBitrate();
      
      _videoController = VideoPlayerController.networkUrl(streamInfo.url)
        ..initialize().then((_) {
          setState(() {
            _isLoadingPlayer = false;
            _videoController!.play();
          });
        });
    } catch (e) {
      setState(() => _isLoadingPlayer = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback Error! Please try another video.')),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      YouTubeHomeScreen(onVideoSelect: _startPlayback),
      const Center(child: Text('Shorts Feed', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Subscriptions', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Library', style: TextStyle(color: Colors.white, fontSize: 18))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.red, size: 30),
            SizedBox(width: 6),
            Text('YouTube', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -1)),
            SizedBox(width: 4),
            Text('Premium', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Native Video Player Implementation
          if (_isVideoPlaying)
            Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black,
                    child: _isLoadingPlayer
                        ? const Center(child: CircularProgressIndicator(color: Colors.red))
                        : (_videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const Center(child: Icon(Icons.error))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentVideoTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(_currentChannel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isVideoPlaying = false;
                              _videoController?.pause();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Shorts'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions_outlined), label: 'Subscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_outlined), label: 'You'),
        ],
      ),
    );
  }
}

class YouTubeHomeScreen extends StatefulWidget {
  final Function(String, String, String) onVideoSelect;
  const YouTubeHomeScreen({super.key, required this.onVideoSelect});

  @override
  State<YouTubeHomeScreen> createState() => _YouTubeHomeScreenState();
}

class _YouTubeHomeScreenState extends State<YouTubeHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final yt.YoutubeExplode _ytExplode = yt.YoutubeExplode();
  List<yt.Video> _searchedVideos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialVideos();
  }

  Future<void> _loadInitialVideos() async {
    setState(() => _isLoading = true);
    try {
      var searchResult = await _ytExplode.search.search('Sinhala new songs');
      setState(() {
        _searchedVideos = searchResult.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchYouTube(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      var searchResult = await _ytExplode.search.search(query);
      setState(() {
        _searchedVideos = searchResult.take(15).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ytExplode.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search YouTube Videos...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF272727),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: _searchYouTube,
          ),
        ),
        if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.red))),
        if (!_isLoading)
          Expanded(
            child: ListView.builder(
              itemCount: _searchedVideos.length,
              itemBuilder: (context, index) {
                final video = _searchedVideos[index];
                return InkWell(
                  onTap: () => widget.onVideoSelect(video.id.value, video.title, video.author),
                  child: Column(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: const Color(0xFF222222),
                        child: Image.network(video.thumbnails.mediumResUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.play_arrow, size: 50)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.grey, radius: 18, child: Icon(Icons.music_note)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
