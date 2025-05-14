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

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (_selectedCategory == 'All') {
        _allNews = await _newsService.getNews();
      } else {
        _allNews = await _newsService.getNewsByCategory(_selectedCategory);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BBN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchUserScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (String category) {
              setState(() {
                _selectedCategory = category;
              });
              _loadNews();
            },
            itemBuilder: (BuildContext context) {
              return _categories.map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _allNews.length,
                itemBuilder: (context, index) {
                  return NewsCard(news: _allNews[index]);
                },
              ),
            ),
    );
  }
}
