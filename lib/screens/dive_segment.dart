import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DiveSegment extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;
  final int index;

  DiveSegment({Key key, this.appBar, this.dive, this.index}): super(key: key);

  @override
  _DiveSegmentState createState() => new _DiveSegmentState(appBar, dive, index);
}

class _DiveSegmentState extends State<DiveSegment> {
  final Dive _dive;
  final AppBar _appBar;
  final int index;
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

  _DiveSegmentState(this._appBar, this._dive, this.index):
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
              List<Segment> segments = new List<Segment>();
              Segment lastSegment;
              int i = 0;
              for (final s in _dive.segments.where((Segment s) => !s.calculated)) {
                if (s.type == SegmentType.LEVEL) {
                  if (index == i) segments.add(new Segment(s.type, depth, 0.0, time, s.gas, false));
                  else segments.add(new Segment(s.type, _dive.mbarToDepthM(s.depth), 0.0, s.time+(lastSegment==null?0:lastSegment.time), s.gas, false));
                }
                lastSegment = s;
                i++;
              }
              _dive.clearSegments();
              lastSegment = null;
              for (Segment s in segments) {
                _dive.move(lastSegment == null ? 0 : lastSegment.depth, s.depth, s.time);
                lastSegment = s;
              }
              if (index == -1) {
                _dive.move(lastSegment==null?0:lastSegment.depth, depth, time);
              }
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
