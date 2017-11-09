import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'deco/plan.dart';
import 'screens/dive_config.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Nemo',
      theme: new ThemeData.light(), /*new ThemeData(
        primarySwatch: Colors.red,
      ),*/
      home: new MyHomePage(title: 'Nemo Dive Planner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

enum MenuOptions { metric, imperial, reset }

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Plan _plan = new Plan();

  Future<File> _getLocalFile() async {
    // get the path to the document directory.
    String dir = (await getApplicationDocumentsDirectory()).path;
    return new File('$dir/default_dive.json');
  }

  Future<String> _readState() async {
    try {
      File file = await _getLocalFile();
      // read the variable as a string from the file.
      String contents = await file.readAsString();
      return contents;
    } on FileSystemException {
      return "";
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      var json = _plan.toJson();
      _getLocalFile().then((File f) => f.writeAsString(json));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readState().then((String value) {
      setState(() {
        if (value.length > 0) {
          _plan.loadJson(value);
        }
      });
    });
  }

  _MyHomePageState();

  void _menuSelected(MenuOptions opt) {
    switch (opt) {
      case MenuOptions.metric:
        setState(() => _plan.metric = true);
        break;
      case MenuOptions.imperial:
        setState(() => _plan.metric = false);
        break;
      case MenuOptions.reset:
        setState(() => _plan.reset());
        break;
    }

  }

  @override
  Widget build(BuildContext context) {
    PopupMenuButton<MenuOptions> menu = new PopupMenuButton<MenuOptions>(
      onSelected: _menuSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOptions>>[
        new CheckedPopupMenuItem<MenuOptions>(
          checked: _plan.metric,
          value: MenuOptions.metric,
          child: const Text('Metric'),
        ),
        new CheckedPopupMenuItem<MenuOptions>(
          checked: !_plan.metric,
          value: MenuOptions.imperial,
          child: const Text('Imperial'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.reset,
          child: const Text('Reset'),
        ),
      ],
    );
    final AppBar appBar = new AppBar(
      title: new Text(widget.title),
      actions: [menu],
    );

    return new DiveConfig(appBar, _plan);
  }
}
