import 'package:flutter/material.dart';

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
  bool _isVideoPlaying = false;
  String _currentVideoTitle = '';
  String _currentChannel = '';

  void _playVideo(Map<String, String> video) {
    setState(() {
      _isVideoPlaying = true;
      _currentVideoTitle = video['title']!;
      _currentChannel = video['channel']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      YouTubeHomeScreen(onVideoSelect: _playVideo),
      const Center(child: Text('Shorts Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Subscriptions Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('You (Library) Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
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
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 6.0),
            child: CircleAvatar(backgroundColor: Colors.blueAccent, radius: 14, child: Text('N')),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isVideoPlaying)
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(width: 100, height: 60, color: Colors.grey, child: const Icon(Icons.play_arrow)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentVideoTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_currentChannel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.pause), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isVideoPlaying = false)),
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

class YouTubeHomeScreen extends StatelessWidget {
  final Function(Map<String, String>) onVideoSelect;
  const YouTubeHomeScreen({super.key, required this.onVideoSelect});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> dummyVideos = [
      {'title': 'Build a YouTube Clone App in Flutter', 'channel': 'Tech Code LK', 'duration': '14:20'},
      {'title': 'Amazing Sri Lankan Travel Vlog 2026', 'channel': 'Lanka Explorer', 'duration': '22:05'},
      {'title': 'New Nonstop Remix Songs Collection', 'channel': 'Music Box', 'duration': '1:05:40'},
    ];

    return ListView.builder(
      itemCount: dummyVideos.length,
      itemBuilder: (context, index) {
        final video = dummyVideos[index];
        return InkWell(
          onTap: () => onVideoSelect(video),
          child: Column(
            children: [
              Container(height: 200, color: Colors.grey, child: const Center(child: Icon(Icons.play_arrow, size: 50, color: Colors.white54))),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(backgroundColor: Colors.grey, radius: 18, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video['title']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                          Text(video['channel']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    );
  }
}
