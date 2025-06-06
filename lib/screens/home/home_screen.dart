import 'package:bullbearnews/screens/home/search_user_screen.dart';
import 'package:bullbearnews/widgets/news_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  List<NewsModel> _allNews = [];
  final List<String> _categories = [
    'All',
    'Trending',
    'New',
    'Teknoloji',
    'Sağlık'
  ];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<NewsModel>> _newsCache = {};

  Widget? _cachedAppBarTitle;

  @override
  void initState() {
    super.initState();
    _loadNews();
    // _scrollController.addListener(() {
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    // Cache kontrolü
    if (_newsCache.containsKey(_selectedCategory)) {
      setState(() {
        _allNews = _newsCache[_selectedCategory]!;
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      List<NewsModel> news;
      if (_selectedCategory == 'All') {
        news = await _newsService.getNews();
      } else {
        news = await _newsService.getNewsByCategory(_selectedCategory);
      }

      // Cache'e kaydet
      _newsCache[_selectedCategory] = news;

      if (mounted) {
        setState(() {
          _allNews = news;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Haber yükleme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAppBarTitle() {
    _cachedAppBarTitle ??= Text(
      'BBN',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 25,
        color: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        fontFamily: 'RobotoMono',
        letterSpacing: 1.2,
        wordSpacing: 1.2,
        height: 1.5,
      ),
    );
    return _cachedAppBarTitle!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: _buildAppBarTitle(),
                  floating: true,
                  centerTitle: true,
                  snap: true,
                  pinned: false, // Bu false olmalı
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 0, // Genişletilmiş alan yok
                  forceElevated: false,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchUserScreen())),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                      ),
                      onSelected: (String category) {
                        setState(() => _selectedCategory = category);
                        _loadNews();
                      },
                      itemBuilder: (BuildContext context) => _categories
                          .map((category) => PopupMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ],
              body: Padding(
                padding: const EdgeInsets.only(bottom: 70.0),
                child: RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _allNews.length,
                    itemBuilder: (context, index) =>
                        NewsCard(news: _allNews[index]),
                  ),
                ),
              ),
            ),
    );
  }
}
