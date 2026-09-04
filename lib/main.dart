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
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    setState(() {
      _isLoadingPlayer = true;
      _isVideoPlaying = true;
      _currentVideoTitle = title;
      _currentChannel = author;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final muxedStreams = manifest.muxed.toList();

      if (muxedStreams.isEmpty) {
        throw Exception('No playable stream found for this video');
      }

      var streamInfo = muxedStreams.withHighestBitrate();

      final controller = VideoPlayerController.networkUrl(streamInfo.url);
      _videoController = controller;

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _isLoadingPlayer = false;
      });
      controller.play();
    } catch (e) {
      if (!mounted) return;
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
      YouTubeHomeScreen(ytClient: _yt, onVideoSelect: _startPlayback),
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
            Text(
              'YouTube',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -1),
            ),
            SizedBox(width: 4),
            Text('Premium', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
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
                            : const Center(child: Icon(Icons.error, color: Colors.white))),
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
                              Text(
                                _currentVideoTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_currentChannel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (!_isLoadingPlayer && _videoController != null)
                          IconButton(
                            icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
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
  final yt.YoutubeExplode ytClient;
  final Function(String, String, String) onVideoSelect;

  const YouTubeHomeScreen({super.key, required this.ytClient, required this.onVideoSelect});

  @override
  State<YouTubeHomeScreen> createState() => _YouTubeHomeScreenState();
}

class _YouTubeHomeScreenState extends State<YouTubeHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<yt.Video> _searchedVideos = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialVideos();
  }

  Future<void> _loadInitialVideos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      var searchResult = await widget.ytClient.search.search('Sinhala new songs');
      if (!mounted) return;
      setState(() {
        _searchedVideos = searchResult.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load videos';
      });
    }
  }

  Future<void> _searchYouTube(String query) async {
    if (query.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      var searchResult = await widget.ytClient.search.search(query);
      if (!mounted) return;
      setState(() {
        _searchedVideos = searchResult.take(15).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search failed, try again';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
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
        if (!_isLoading && _errorMessage != null)
          Expanded(
            child: Center(
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            ),
          ),
        if (!_isLoading && _errorMessage == null)
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              video.thumbnails.highResUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                color: Colors.black87,
                                child: Text(
                                  _formatDuration(video.duration),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF3D3D3D),
                              child: Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    video.author,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
