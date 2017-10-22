import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DiveSegment extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;

  DiveSegment({Key key, this.appBar, this.dive}): super(key: key);

  @override
  _DiveSegmentState createState() => new _DiveSegmentState(appBar, dive);
}

class _DiveSegmentState extends State<DiveSegment> {
  final Dive _dive;
  final AppBar _appBar;
  final TextEditingController _depthcontroller;
  final TextEditingController _timecontroller;

  static int _getDepth(Dive dive) {
    int ret = 30;
    for (final Segment s in dive.segments) {
      if (!s.calculated) ret = s.depth;
    }
    return dive.mbarToDepthM(ret);
  }

  static int _getTime(Dive dive) {
    int ret = 10;
    Segment prev;
    for (final Segment s in dive.segments) {
      if (!s.calculated) ret = s.time+(prev!=null?prev.time:0);
      prev = s;
    }
    return ret;
  }

  _DiveSegmentState(this._appBar, this._dive):
        _depthcontroller = new TextEditingController(text: "${_getDepth(_dive)}"),
        _timecontroller = new TextEditingController(text: "${_getTime(_dive)}");

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          new TextField(controller: _depthcontroller, decoration: new InputDecoration(labelText:  "Depth:"), keyboardType: TextInputType.number),
          new TextField(controller: _timecontroller, decoration: new InputDecoration(labelText:  "Time:"), keyboardType: TextInputType.number),
          new FlatButton(
            child: const Text('Save'),
            onPressed: () {
              int depth = int.parse(_depthcontroller.text);
              int time = int.parse(_timecontroller.text);
              _dive.clearSegments();
              _dive.descend(0, depth);
              _dive.addBottom(depth, time - _dive.segments.last.time);
              Navigator.of(context).pop();
            },
          ),
        ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
    );
  }
}
