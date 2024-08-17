import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> imagePaths = [];

  final Stopwatch _stopwatch = Stopwatch();
  int _imagesCount = 0;
  int _imagesLoaded = 0;
  bool _isCachingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadImagePaths();
  }

  Future<void> _loadImagePaths() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _imagesLoaded = 0;
    _stopwatch.reset();
    _stopwatch.start();
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final paths = manifestMap.keys
        .where((String key) =>
            key.contains('assets/images') && key.endsWith('.jpg'))
        .toList();

    _imagesCount = paths.length;
    setState(() {
      imagePaths = paths;
    });
  }

  void _reloadImages() {
    setState(() {
      _loadImagePaths();
    });
  }

  _countLoadedImages() {
    _imagesLoaded += 1;
    if (_imagesLoaded == _imagesCount) {
      _stopwatch.stop();
      print(
          'Caching: ${_isCachingEnabled ? "Enabled" : "Disabled"}. Loaded $_imagesCount images in ${_stopwatch.elapsedMilliseconds}ms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          const Text('Caching'),
          Switch(
            value: _isCachingEnabled,
            onChanged: (bool value) {
              setState(() {
                _loadImagePaths();
                _isCachingEnabled = value;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadImages,
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 0,
          mainAxisSpacing: 8,
          childAspectRatio: 2,
        ),
        restorationId: 'sampleItemListView',
        itemCount: imagePaths.length,
        itemBuilder: (BuildContext context, int index) {
          final imagePath = imagePaths[index];

          return Image.asset(
            imagePath,
            cacheHeight: _isCachingEnabled
                ? 400
                : null, // removing the caching fixes the issue
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                _countLoadedImages();
              } else {
                if (frame == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  _countLoadedImages();
                }
              }
              return child;
            },
          );
        },
      ),
    );
  }
}
