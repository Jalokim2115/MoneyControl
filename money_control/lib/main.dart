import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Umożliwia korzystanie z async w main
  final appState = MyAppState();
  await appState.loadState(); // Wczytanie zapisanego stanu
  runApp(
    ChangeNotifierProvider(
      create: (context) => appState,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namer App',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          dividerColor: Colors.transparent),
      home: MyHomePage(),
    );
  }
}

class MyAppState extends ChangeNotifier {
  double spent = 0;

  var categories = <Category>[];

  void addCategory(name, color) {
    categories.add(Category(name, 0, [], color));
    saveState();
    notifyListeners();
  }

  void addProductToCategory(
      Category category, String productName, double value) {
    category.products.add(Product(productName, value));
    category.setValue();
    spentSetValue();
    saveState();
    notifyListeners();
  }

  void removeProduct(Category category, Product product) {
    category.products.remove(product);
    category.setValue();
    spentSetValue();
    saveState();
    notifyListeners();
  }

  void resetProduct(Category category, Product product) {
    product.resetValue();
    category.setValue();
    spentSetValue();
    saveState();
    notifyListeners();
  }

  void spentSetValue() {
    spent = 0;
    for (Category category in categories) {
      spent += category.value;
    }
  }

  void removeCategory(Category category) {
    categories.remove(category);
    spentSetValue();
    saveState();
    notifyListeners();
  }

  void resetCategory(Category category) {
    for (Product product in category.products) {
      product.value = 0;
    }
    category.value = 0;
    spentSetValue();
    saveState();
    notifyListeners();
  }

  void addProductValue(category, product, value) {
    product.setValue(value);
    category.setValue();
    spentSetValue();
    saveState();
    notifyListeners();
  }

  Future<void> saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'categories': categories.map((category) {
          return {
            'label': category.label,
            'value': category.value,
            'products': category.products.map((product) {
              return {
                'name': product.name,
                'value': product.value,
              };
            }).toList(),
            'color': category.color.value,
          };
        }).toList(),
        'spent': spent,
      };

      String stateJson = jsonEncode(state);
      print("Saving state: $stateJson");
      await prefs.setString('appState', stateJson);
    } catch (e) {
      print("Error saving state: $e");
    }
  }

  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getString('appState');
      if (savedState != null) {
        print("Loaded state: $savedState");
        final state = jsonDecode(savedState);

        categories = (state['categories'] as List).map((categoryData) {
          return Category(
            categoryData['label'],
            categoryData['value'].toDouble(),
            (categoryData['products'] as List).map((productData) {
              return Product(
                productData['name'],
                productData['value'].toDouble(),
              );
            }).toList(),
            Color(categoryData['color']),
          );
        }).toList();

        spent = state['spent'].toDouble();
        notifyListeners();
      }
    } catch (e) {
      print("Error loading state: $e");
    }
  }

  Future<void> clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appState');
  }
}

class Category {
  String label;
  List<Product> products;
  double value;
  Color color;

  Category(this.label, this.value, this.products, this.color);

  void setValue() {
    value = 0;
    for (var product in products) {
      value += product.value;
    }
  }
}

class Product {
  String name;
  double value;

  Product(this.name, this.value);

  void setValue(int cena) {
    value += cena;
  }

  void resetValue() {
    value = 0;
  }
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
      case 2:
        page = Settings();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // Pusta etykieta
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '', // Pusta etykieta
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '', // Pusta etykieta
          ),
        ],
      ),
    );
  }
}

class SpentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    double screenWidth = MediaQuery.of(context).size.width;

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
                    "W tym miesiącu wydałeś:",
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      "${appState.spent.toString()} zł",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontFamily: 'Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
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
                    onPressed: () {},
                    label: Text('placeholder'),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      for (Category category in appState.categories) {
                        for (Product product in category.products) {
                          appState.resetProduct(category, product);
                        }
                      }
                    },
                    child: Text('Zresetuj koszta'),
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
    void showAddProductDialog(Category category) async {
      final TextEditingController nameController = TextEditingController();
      final TextEditingController valueController = TextEditingController();

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Dodaj produkt do kategorii "${category.label}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nazwa produktu'),
                ),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Wartość produktu'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Anuluj'),
              ),
              TextButton(
                onPressed: () {
                  final productName = nameController.text.trim();
                  final productValue =
                      double.tryParse(valueController.text) ?? 0;

                  if (productName.isNotEmpty && productValue > 0) {
                    context.read<MyAppState>().addProductToCategory(
                        category, productName, productValue);
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Dodaj'),
              ),
            ],
          );
        },
      );
    }

    return ListView(
      children: [
        for (var category in appState.categories)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: ExpansionTile(
                maintainState: true,
                textColor: Theme.of(context).colorScheme.onSecondary,
                collapsedTextColor: Theme.of(context).colorScheme.onSecondary,
                collapsedBackgroundColor: category.color,
                backgroundColor: category.color,
                showTrailingIcon: false,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: screenWidth * 0.5,
                      child: Text(
                        category.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        showAddProductDialog(category);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.replay,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        appState.resetCategory(category);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        appState.removeCategory(category);
                      },
                    ),
                  ],
                ),
                subtitle: Text('Wartość: ${category.value} zł'),
                children: [
                  for (var product in category.products)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: ListTile(
                        onTap: () async {
                          final value = await showDialog<int>(
                            context: context,
                            builder: (BuildContext context) {
                              int? enteredValue;
                              return AlertDialog(
                                title: Text('Wpisz wartość'),
                                content: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      InputDecoration(hintText: 'Wartość'),
                                  onChanged: (val) {
                                    enteredValue = int.tryParse(val);
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, null);
                                    },
                                    child: Text('Anuluj'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, enteredValue);
                                    },
                                    child: Text('Dodaj'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (value != null) {
                            appState.addProductValue(category, product, value);
                          }
                        },
                        textColor: Theme.of(context).colorScheme.onSecondary,
                        title: Row(
                          children: [
                            Expanded(
                              child: Container(
                                width: screenWidth * 0.5,
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                            Text(
                              '${product.value} zł',
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                Icons.replay,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                              onPressed: () {
                                appState.resetProduct(category, product);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                              onPressed: () {
                                appState.removeProduct(category, product);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ListTile(
          title: ElevatedButton(
            onPressed: () {
              final TextEditingController controller = TextEditingController();
              Color selectedColor =
                  Theme.of(context).colorScheme.secondary; // Domyślny kolor

              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return StatefulBuilder(
                    // StatefulBuilder pozwala na dynamiczną aktualizację stanu w dialogu
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text('Dodaj kategorię'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: controller,
                              decoration:
                                  InputDecoration(hintText: 'Nazwa kategorii'),
                            ),
                            SizedBox(height: 20),
                            Text('Wybierz kolor:'),
                            SizedBox(height: 10),
                            ColorPicker(
                              pickerColor: selectedColor,
                              onColorChanged: (color) {
                                setState(() {
                                  selectedColor =
                                      color; // Zaktualizowanie wybranego koloru
                                });
                              },
                              enableAlpha:
                                  true, // Pozwala wybrać przezroczystość
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text('Anuluj'),
                          ),
                          TextButton(
                            onPressed: () {
                              final categoryName = controller.text.trim();
                              if (categoryName.isNotEmpty) {
                                appState.addCategory(
                                    categoryName, selectedColor);
                              }
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text('Dodaj'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: Text('Dodaj kategorię'),
          ),
        ),
      ],
    );
  }
}

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Tu będą ustawienia"),
    );
  }
}
