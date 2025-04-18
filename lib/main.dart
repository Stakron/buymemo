import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

const List<String> initialCategories = [
  '野菜',
  '肉',
  '魚',
  '乳製品',
  '豆',
  '調味料',
  '練り物',
  '穀物',
  'お菓子',
  'その他'
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buy memo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // 英語
        const Locale('ja', ''), // 日本語
        const Locale('es', ''), // スペイン語
      ],
      home: ShoppingListScreen(),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with TickerProviderStateMixin {
  final List<String> _dailyShoppingList = [];
  final List<String> _generalShoppingList = [];
  final List<String> _categoryNames = [
    '野菜',
    '肉',
    '魚',
    '乳製品',
    '豆',
    '調味料',
    '練り物',
    '穀物',
    'お菓子',
    'その他'
  ];
  final Map<String, List<String>> _categoryLists = {
    '野菜': [
      'キャベツ',
      'にんじん',
      'レタス',
      'トマト',
      'ブロッコリー',
      'ごぼう',
      '小松菜',
      '大根',
      'さつまいも',
      '白菜',
      'えのき',
      'ほうれん草',
    ],
    '肉': ['卵', '鶏もも肉', '鶏むね肉', '豚バラ', '豚小間肉', '牛肉'],
    '魚': ['さんま', 'しゃけ', 'さば'],
    '乳製品': ['牛乳', 'チーズ', 'ヨーグルト'],
    '豆': ['納豆', '豆腐', '豆乳'],
    '調味料': [
      '油',
      'しょうゆ',
      'さとう',
      '酒',
      'みりん',
      '鶏ガラ',
      '昆布',
      '白だし',
      '酒',
      'ごま油',
      'ポン酢'
    ],
    '練り物': ['はんぺん', 'ごぼう天', '平天'],
    '穀物': ['米', 'パン', '中華そば', 'うどん', 'そば'],
    'お菓子': ['ポテトチップス', 'コカコーラ', 'じゃがりこ'],
    'その他': ['アイス'],
  };
  final Set<String> _crossedOutItems = {};
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late TabController _generalTabController;
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _mainTabController = TabController(length: 2, vsync: this);
    _generalTabController =
        TabController(length: _categoryNames.length, vsync: this);
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6562846915003119/3030250417',
      // Replace with your actual Ad Unit ID
      // Real ID ca-app-pub-6562846915003119/3030250417'
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyShoppingList.addAll(
          (prefs.getStringList('dailyShoppingList') ?? []).map((e) => e));
      _generalShoppingList.addAll(
          (prefs.getStringList('generalShoppingList') ?? []).map((e) => e));
      _categoryNames.clear();
      _categoryNames
          .addAll(prefs.getStringList('categoryNames') ?? initialCategories);
      final categoryListsJson = prefs.getString('categoryLists') ?? '{}';
      final decodedCategoryLists =
          json.decode(categoryListsJson) as Map<String, dynamic>;
      decodedCategoryLists.forEach((key, value) {
        _categoryLists[key] =
            (value as List<dynamic>).map((e) => e as String).toList();
      });
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dailyShoppingList', _dailyShoppingList);
    await prefs.setStringList('generalShoppingList', _generalShoppingList);
    await prefs.setStringList('categoryNames', _categoryNames);
    await prefs.setString('categoryLists', json.encode(_categoryLists));
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _generalTabController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Buy memo'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _showAddOptionsDialog,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.todayShopping),
              Tab(text: AppLocalizations.of(context)!.usualList),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildShoppingList(_dailyShoppingList),
                      _buildGeneralTabBar(),
                    ],
                  ),
                ),
              ],
            ),
            if (_isBannerAdReady)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        _getNavigationBarHeight(context),
                  ),
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _getNavigationBarHeight(BuildContext context) {
    // ナビゲーションバーの高さを取得（デバイスごとに調整）
    var navigationBarHeight = MediaQuery.of(context).padding.bottom;
    if (navigationBarHeight == 0) {
      // 3-button navigationの場合
      return kBottomNavigationBarHeight;
    } else {
      // Gesture navigationの場合
      return 0;
    }
  }

  Widget _buildShoppingList(List<String> shoppingList) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: shoppingList.length,
          itemBuilder: (context, index) {
            final item = shoppingList[index];
            final crossedOut = _crossedOutItems.contains(item);
            return ListTile(
              title: Text(
                item,
                style: TextStyle(
                  decoration: crossedOut
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: crossedOut ? Colors.grey : Colors.black,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    if (crossedOut) {
                      shoppingList.removeAt(index);
                      _crossedOutItems.remove(item);
                    } else {
                      _crossedOutItems.add(item);
                    }
                    _saveData();
                  });
                },
              ),
              onLongPress: () {
                setState(() {
                  shoppingList.removeAt(index);
                  _crossedOutItems.remove(item);
                  _saveData();
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGeneralTabBar() {
    if (_generalTabController.length != _categoryNames.length) {
      _generalTabController.dispose();
      _generalTabController = TabController(
        length: _categoryNames.length,
        vsync: this,
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _generalTabController,
          isScrollable: true,
          tabs: _categoryNames.map((category) => Tab(text: category)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _generalTabController,
            children: _categoryNames.map((category) {
              return _buildCategoryList(
                  _categoryLists[category]!, _dailyShoppingList);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
      List<String> categoryList, List<String> targetList) {
    final bottomPadding = _isBannerAdReady
        ? _bannerAd.size.height.toDouble() +
            MediaQuery.of(context).padding.bottom +
            _getNavigationBarHeight(context)
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final String item = categoryList.removeAt(oldIndex);
            categoryList.insert(newIndex, item);
            _saveData();
          });
        },
        children: List.generate(categoryList.length, (index) {
          final item = categoryList[index];
          return ListTile(
            key: Key('$item$index'), // 一意のキーを設定
            title: Text(item),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  categoryList.removeAt(index);
                  _categoryNames.remove(item);
                  _categoryLists.remove(item);
                  _saveData();
                });
              },
            ),
            onTap: () {
              setState(() {
                if (!targetList.contains(item)) {
                  targetList.add(item);
                  _saveData();
                }
              });
            },
          );
        }),
      ),
    );
  }

  void _showRemoveCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.removeCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _categoryNames.map((category) {
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmationDialog(category, () {
                      _deleteCategory(category);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String category, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteConfirmation),
          content: Text(AppLocalizations.of(context)!.deleteWarning(category)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(String category) {
    setState(() {
      _categoryNames.remove(category);
      _categoryLists.remove(category);
    });

    // UIの更新を確実に行うため、遅延実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _generalTabController.dispose();
        _generalTabController = TabController(
          length: _categoryNames.length,
          vsync: this,
          initialIndex: math.min(_categoryNames.length - 1, 0),
        );
      });

      _saveData();
    });
  }

  void _showReorderCategoriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.reorderCategories),
          content: Container(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final String item = _categoryNames.removeAt(oldIndex);
                      _categoryNames.insert(newIndex, item);

                      // カテゴリーリストの順序も更新
                      final List<String> categoryItems =
                          _categoryLists.remove(item)!;
                      _categoryLists[item] = categoryItems;
                      _saveData();

                      // 親ウィジェットの状態を更新して即時反映
                      this.setState(() {});
                    });
                  },
                  children: List.generate(_categoryNames.length, (index) {
                    final category = _categoryNames[index];
                    return ListTile(
                      key: Key('$category$index'), // 一意のキーを設定
                      title: Text(category),
                    );
                  }),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.addNewCategory),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddCategoryDialog();
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.addItemToCategory),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddItemToCategoryDialog();
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.removeCategory),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRemoveCategoryDialog();
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!
                      .reorderCategories), // 新しいオプションを追加
                  onTap: () {
                    Navigator.of(context).pop();
                    _showReorderCategoriesDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategory = '';
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewCategory),
          content: TextField(
            onChanged: (value) {
              newCategory = value;
            },
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.addNewCategory),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (newCategory.isNotEmpty) {
                  _addCategory(newCategory);
                  // "いつものリスト"タブに切り替え
                  _mainTabController.index = 1;
                  // 新しいカテゴリーに遷移
                  _navigateToCategory(newCategory);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToCategory(String category) {
    // 新しいカテゴリーのインデックスを取得
    int categoryIndex = _categoryNames.indexOf(category);
    if (categoryIndex != -1 && categoryIndex < _generalTabController.length) {
      // タブを切り替え
      _generalTabController.index = categoryIndex;
      setState(() {}); // UIを更新
    }
  }

  void _addCategory(String newCategory) {
    if (!_categoryNames.contains(newCategory)) {
      // カテゴリーを追加
      setState(() {
        _categoryNames.add(newCategory);
        _categoryLists[newCategory] = [];
        _saveData();

        // 新しいTabControllerを作成
        _generalTabController.dispose(); // 既存のTabControllerを破棄
        _generalTabController = TabController(
          length: _categoryNames.length,
          vsync: this,
          initialIndex: _categoryNames.length - 1, // 新しいカテゴリーに遷移
        );

        // タブを切り替え
        _mainTabController.index = 1; // "いつものリスト"タブに切り替え
        print(
            'Switching to "Usual List" tab and navigating to category: $newCategory'); // デバッグ用出力
        // 新しいカテゴリーに遷移
        _navigateToCategory(newCategory);
      });
    } else {
      // カテゴリーが既に存在する場合の処理
      Future.delayed(Duration.zero, () {
        _showCategoryExistsDialog(newCategory);
      });
    }
  }

  void _showCategoryExistsDialog(String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // ローカライズされたメッセージを取得
        String message = AppLocalizations.of(context)!
            .categoryExistsMessage(category); // 関数を呼び出す

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!
              .categoryExistsTitle), // ローカライズされたタイトル
          content: Text(message), // ローカライズされたメッセージ
          actions: <Widget>[
            TextButton(
              child: Text(
                  AppLocalizations.of(context)!.cancel), // ローカライズされたキャンセルボタン
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddItemToCategoryDialog() {
    TextEditingController itemController = TextEditingController();
    // 現在選択されているカテゴリーを取得
    String selectedCategory = _categoryNames[_generalTabController.index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(AppLocalizations.of(context)!.addItemToCategory), // ローカライズ
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (String? value) {
                      setState(() {
                        selectedCategory = value!; // 選択されたカテゴリーを更新
                      });
                    },
                    items: _categoryNames
                        .map<DropdownMenuItem<String>>((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!
                            .addItemToCategory), // ローカライズ
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel), // ローカライズ
            ),
            TextButton(
              onPressed: () {
                if (itemController.text.isNotEmpty) {
                  setState(() {
                    _categoryLists[selectedCategory]!.add(itemController.text);
                    _saveData(); // データを保存
                    _navigateToCategory(selectedCategory); // カテゴリーに遷移
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.add), // ローカライズ
            ),
          ],
        );
      },
    );
  }
}
