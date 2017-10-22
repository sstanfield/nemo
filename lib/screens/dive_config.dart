import 'package:flutter/material.dart';
import 'general_settings.dart';
import 'dive_segment.dart';
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

  _DiveConfigState(this._appBar, this._botNavBar, this._dive);

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
      new Card(child: new Column(children: [
        new Text("Dive Settings", style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        new Row(children: [new Text("Gradient factors:  "), new Text("${(_dive.gfLo*100).round().toString()}/${(_dive.gfHi*100).round().toString()}")]),
        new Row(children: [new Text("ATM Pressure:  "), new Text("${_dive.atmPressure}")]),
        new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(context).push(new MaterialPageRoute<Null>(
                              builder: (BuildContext context) {
                                return new GeneralSettings(appBar: _appBar, dive: _dive);
                              })
                          );}),
                    ]),
      ])),
      new Card(child: new Column(children: [
        new Text("Dive Segment", style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        new Row(children: [new Text("Depth:  "), new Text("${_getDepth(_dive)}")]),
        new Row(children: [new Text("Time:  "), new Text("${_getTime(_dive)}")]),
        new ButtonBar(
            children: <Widget>[
              new FlatButton(
                  child: const Text('Edit'),
                  onPressed: () {
                    Navigator.of(context).push(new MaterialPageRoute<Null>(
                        builder: (BuildContext context) {
                          return new DiveSegment(appBar: _appBar, dive: _dive);
                        })
                    );}),
            ]),
      ])),
    ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
      bottomNavigationBar: _botNavBar,
      //floatingActionButton: _floatingActionButton,
    );
  }
}
