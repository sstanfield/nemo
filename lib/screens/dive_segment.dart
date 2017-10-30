import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DiveSegment extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;
  final int index;
  final int ceiling;

  DiveSegment({Key key, this.appBar, this.dive, this.index, this.ceiling}): super(key: key);

  @override
  _DiveSegmentState createState() => new _DiveSegmentState(appBar, dive, index, ceiling);
}

class _DiveSegmentState extends State<DiveSegment> {
  final Dive _dive;
  final AppBar _appBar;
  final int ceiling;
  final int index;
  final TextEditingController _depthcontroller;
  final TextEditingController _timecontroller;

  static int _getDepth(Dive dive, int index) {
    int i = 0;
    for (final s in dive.segments.where((Segment s) => !s.calculated)) {
      if (index == i) return dive.mbarToDepthM(s.depth);
      i++;
    }
    return 30;
  }

  static int _getTime(Dive dive, int index) {
    Segment prev;
    int i = 0;
    for (final s in dive.segments.where((Segment s) => !s.calculated)) {
      if (index == i) return s.time+(prev!=null&&prev.type!=SegmentType.LEVEL?prev.time:0);
      prev = s;
      i++;
    }
    return 10;
  }

  _DiveSegmentState(this._appBar, this._dive, this.index, this.ceiling):
        _depthcontroller = new TextEditingController(text: "${_getDepth(_dive, index)}"),
        _timecontroller = new TextEditingController(text: "${_getTime(_dive, index)}");

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          new Text("Ceiling: $ceiling"),
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
                  int tmptime = s.time+(lastSegment!=null&&lastSegment.type!=SegmentType.LEVEL?lastSegment.time:0);
                  if (index == i) segments.add(new Segment(s.type, depth, 0.0, time, s.gas, false, 0));
                  else segments.add(new Segment(s.type, _dive.mbarToDepthM(s.depth), 0.0, tmptime, s.gas, false, s.ceiling));
                }
                lastSegment = s;
                i++;
              }
              _dive.clearSegments();
              lastSegment = null;
              for (Segment s in segments) {
                if (s.depth > 0) _dive.move(lastSegment == null ? 0 : lastSegment.depth, s.depth, s.time);
                else _dive.addBottom(0, s.time);
                lastSegment = s;
              }
              if (index == -1) {
                if (depth > 0) _dive.move(lastSegment==null?0:lastSegment.depth, depth, time);
                else _dive.addBottom(0, time);
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
