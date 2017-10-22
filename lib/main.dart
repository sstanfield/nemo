import 'package:flutter/material.dart';
import 'deco/plan.dart';
import 'screens/dive_config.dart';
import 'screens/dive_plan.dart';
import 'screens/gas_list.dart';

class NavigationIconView {
  NavigationIconView({
  Widget icon,
  Widget title,
  Color color,
  }) : _icon = icon,
        _color = color,
        item = new BottomNavigationBarItem(
          icon: icon,
          title: title,
          backgroundColor: color);

  final Widget _icon;
  final Color _color;
  final BottomNavigationBarItem item;
}

class CustomIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    return new Container(
      margin: const EdgeInsets.all(4.0),
      width: iconTheme.size - 8.0,
      height: iconTheme.size - 8.0,
      decoration: new BoxDecoration(
        color: iconTheme.color,
      ),
    );
  }
}

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Nemo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting
        // the app, try changing the primarySwatch below to Colors.green
        // and press "r" in the console where you ran "flutter run".
        // We call this a "hot reload". Notice that the counter didn't
        // reset back to zero -- the application is not restarted.
        primarySwatch: Colors.red,
      ),
      home: new MyHomePage(title: 'Nemo Dive Planner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful,
  // meaning that it has a State object (defined below) that contains
  // fields that affect how it looks.

  // This class is the configuration for the state. It holds the
  // values (in this case the title) provided by the parent (in this
  // case the App widget) and used by the build method of the State.
  // Fields in a Widget subclass are always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  List<NavigationIconView> _navigationViews;
  Dive _dive;

  _MyHomePageState() {
    //_gasses = [ new Gas.bottom(.21, .0, 1.2) ];
    List<Gas> gasses = [ new Gas.bottom(.18, .45, 1.4), new Gas.deco(.50, 0.0), new Gas.deco(0.99, 0.0) ];
    _dive = new Dive();
    for (Gas g in gasses) _dive.addGas(g);
    _dive.descend(0, 30);
    _dive.addBottom(30, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    _navigationViews = <NavigationIconView>[
      new NavigationIconView(
        icon: new Icon(Icons.access_alarm),
        title: new Text('Settings'),
        color: Colors.deepPurple[500],
      ),
      new NavigationIconView(
        icon: new CustomIcon(),
        title: new Text('Plan'),
        color: Colors.deepOrange[500],
      ),
      new NavigationIconView(
        icon: new Icon(Icons.cloud),
        title: new Text('Gasses'),
        color: Colors.teal[500],
      ),
    ];

    final AppBar appBar = new AppBar(
    // Here we take the value from the MyHomePage object that
    // was created by the App.build method, and use it to set
    // our appbar title.
      title: new Text(widget.title),
    );
    final BottomNavigationBar botNavBar = new BottomNavigationBar(
      items: _navigationViews
          .map((NavigationIconView navigationView) => navigationView.item)
          .toList(),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.shifting,//fixed,
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );

    // This method is rerun every time setState is called, for instance
    // as done by the _incrementCounter method above.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    if (_currentIndex == 2) return new GasList(appBar, botNavBar, _dive, (Gas gas) => setState(() {
          _dive.removeGas(gas);
        }), (Gas oldGas, Gas newGas) => setState(() {
          if (oldGas != null) _dive.removeGas(oldGas);
          _dive.addGas(newGas);
          Navigator.of(context).pop();
        }),
    );
    if (_currentIndex == 1) {
      _dive.atmPressure = 1013;
      _dive.calcDeco();
      return new DivePlan(appBar, botNavBar, _dive);
    }
    return new DiveConfig(appBar, botNavBar, _dive);
  }
}
