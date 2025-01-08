import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var spent = 1250.10;
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorites() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void removeFavorites(favorite) {
    favorites.remove(favorite);
    notifyListeners();
  }

  var categories = <Category>[];

  void addCategory(name) {
    categories.add(Category(name, 0, []));
    notifyListeners();
  }
}

class Category {
  String label;
  List<Product> products;
  int value;

  Category(this.label, this.value, this.products);

  // Metoda
  void setValue() {
    value = 0;
    for (var product in products) {
      value += product.value;
    }
  }
}

class Product {
  String name;
  int value;

  Product(this.name, this.value);
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = SpentPage();
      case 1:
        page = SpendingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Podsumowanie'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.list),
                    label: Text('Kategorie'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class SpentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    double screenWidth = MediaQuery.of(context).size.width;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Builder(builder: (context) {
                  double fontSize = screenWidth * 0.05;
                  return Text(
                    "W tym miesiacu wydales:",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontFamily: 'Sans',
                      fontSize: fontSize,
                    ),
                  );
                }),
                Builder(builder: (context) {
                  double fontSize = screenWidth * 0.08;
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(appState.spent.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontFamily: 'Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        )),
                  );
                }),
              ],
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.toggleFavorites();
                    },
                    icon: Icon(icon),
                    label: Text('Like'),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      appState.getNext();
                    },
                    child: Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    double screenWidth = MediaQuery.of(context).size.width;

    Future<void> showAddCategoryDialog(BuildContext context) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focusNode = FocusNode(); // Dodaj FocusNode

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Dodaj kategorię'),
            content: TextField(
              controller: controller,
              focusNode: focusNode, // Użyj FocusNode
              decoration: const InputDecoration(
                hintText: 'Wprowadź nazwę kategorii',
              ),
              autofocus: true, // Ustaw autofocus, aby od razu aktywować pole
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () {
                  final categoryName = controller.text.trim();
                  if (categoryName.isEmpty) {
                    // Wyświetl błąd w dialogu lub konsoli
                    print('Nazwa kategorii nie może być pusta');
                    return;
                  }

                  try {
                    // Dodanie kategorii
                    context.read<MyAppState>().addCategory(categoryName);
                    Navigator.of(dialogContext).pop();
                  } catch (e, stackTrace) {
                    // Logowanie błędu
                    print('Błąd: $e');
                    print('Stack trace: $stackTrace');
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      );
    }

    if (appState.categories.isEmpty) {
      return Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Text('Nie masz jeszcze żadnych kategorii.'),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                showAddCategoryDialog(context); // Przekaż kontekst
              },
              child: Icon(Icons.add, size: screenWidth * 0.08),
            )
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Masz ${appState.categories.length} kategorii:'),
        ),
        for (var category in appState.categories)
          ListTile(
            title: Text(category.products.isNotEmpty
                ? category.products[0].name
                : 'Kategoria bez produktów'),
            subtitle: Text('Wartość: ${category.value}'),
          ),
      ],
    );
  }
}
