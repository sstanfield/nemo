import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DiveConfig extends StatefulWidget {
  final AppBar _appBar;
  final BottomNavigationBar _botNavBar;
  final Dive _dive;

  DiveConfig(this._appBar, this._botNavBar, this._dive);

  @override
  _DiveConfigState createState() => new _DiveConfigState(_appBar, _botNavBar, _dive);
}

class _DiveConfigState extends State<DiveConfig> {
  final Dive _dive;
  final AppBar _appBar;
  final BottomNavigationBar _botNavBar;
  final TextEditingController _depthcontroller;
  final TextEditingController _timecontroller;
  final TextEditingController _gfLo;
  final TextEditingController _gfHi;

  static int _getDepth(Dive dive) {
    int ret = 30;
    for (final Segment s in dive.segments) {
      if (!s.calculated) ret = s.depth;
    }
    return dive.mbarToDepthM(ret);
  }

  static int _getTime(Dive dive) {
    int ret = 10;
    for (final Segment s in dive.segments) {
      if (!s.calculated) ret = s.time;
    }
    return ret;
  }

  _DiveConfigState(this._appBar, this._botNavBar, this._dive):
    _depthcontroller = new TextEditingController(text: "${_getDepth(_dive)}"),
    _timecontroller = new TextEditingController(text: "${_getTime(_dive)}"),
    _gfLo = new TextEditingController(text: "${(_dive.gfLo*100).round()}"),
    _gfHi = new TextEditingController(text: "${(_dive.gfHi*100).round()}");

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(children: [
      new TextField(controller: _gfLo, decoration: new InputDecoration(labelText:  "gfLo:"), keyboardType: TextInputType.number),
      new TextField(controller: _gfHi, decoration: new InputDecoration(labelText:  "gfHi:"), keyboardType: TextInputType.number),
      new TextField(controller: _depthcontroller, decoration: new InputDecoration(labelText:  "Depth:"), keyboardType: TextInputType.number),
      new TextField(controller: _timecontroller, decoration: new InputDecoration(labelText:  "Time:"), keyboardType: TextInputType.number),
      new FlatButton(
        child: const Text('Save'),
        onPressed: () {
          int depth = int.parse(_depthcontroller.text);
          double time = double.parse(_timecontroller.text);
          _dive.gfLo = double.parse(_gfLo.text) / 100.0;
          _dive.gfHi = double.parse(_gfHi.text) / 100.0;
          _dive.clearSegments();
          _dive.descendM(_dive.descentRate, 0, depth);
          _dive.bottomM(depth, time);
        },
      ),
    ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
      bottomNavigationBar: _botNavBar,
      //floatingActionButton: _floatingActionButton,
    );
  }
}
