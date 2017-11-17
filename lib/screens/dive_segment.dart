import 'package:flutter/material.dart';
import 'widgets/int_edit.dart';
import 'widgets/common_form_buttons.dart';
import '../deco/plan.dart';

class DiveSegment extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;
  final int index;
  final int ceiling;

  DiveSegment({Key key, this.appBar, this.dive, this.index, this.ceiling})
      : super(key: key);

  @override
  _DiveSegmentState createState() =>
      new _DiveSegmentState(appBar, dive, index, ceiling);
}

class _DiveSegmentState extends State<DiveSegment> {
  final Dive _dive;
  final AppBar _appBar;
  final int ceiling;
  final int index;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  int _depth;
  int _time;

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _handleSubmitted() {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      //_autovalidate = true;  // Start validating on every change.
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      List<Segment> segments = new List<Segment>();
      Segment lastSegment;
      int i = 0;
      for (final s in _dive.segments.where((Segment s) => !s.isCalculated)) {
        if (s.type == SegmentType.LEVEL) {
          int tmptime = s.time +
              (lastSegment != null && lastSegment.type != SegmentType.LEVEL
                  ? lastSegment.time
                  : 0);
          if (index == i) {
            segments.add(new Segment(s.type, _depth, 0.0, _time, s.gas, false, 0));
          } else {
            segments.add(new Segment(s.type, _dive.mbarToDepth(s.depth), 0.0, tmptime,
                    s.gas, false, s.ceiling));
          }
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
        if (_depth == 0 && _dive.segments.length == 0) {
          _dive.surfaceInterval = _time;
        } else {
          _dive.move(lastSegment == null ? 0 : lastSegment.depth, _depth, _time);
        }
      }
      Navigator.of(context).pop();
    }
  }

  static int _getDepth(Dive dive, int index) {
    int i = 0;
    for (final s in dive.segments.where((Segment s) => !s.isCalculated)) {
      if (index == i)
        return dive.mbarToDepth(s.depth);
      i++;
    }
    return 30;
  }

  static int _getTime(Dive dive, int index) {
    Segment prev;
    int i = 0;
    for (final s in dive.segments.where((Segment s) => !s.isCalculated)) {
      if (index == i)
        return s.time +
            (prev != null && prev.type != SegmentType.LEVEL ? prev.time : 0);
      prev = s;
      i++;
    }
    return 10;
  }

  _DiveSegmentState(this._appBar, this._dive, this.index, this.ceiling);

  @override
  Widget build(BuildContext context) {
    ListView c3 =
        new ListView(padding: const EdgeInsets.all(20.0), children: <Widget>[
      new Text("Ceiling: $ceiling"),
      new IntEdit(initialValue: _getDepth(_dive, index),
          onSaved: (int v) => _depth = v,
          validator: (int v) => (v < 0 || v > 1000)?"Enter Depth 0-1000":null,
          label: "Depth"),
      new IntEdit(initialValue: _getTime(_dive, index),
          onSaved: (int v) => _time = v,
          validator: (int v) => (v < 0 || v > 1000)?"Enter Time 0-1000":null,
          label: "Time"),
      new CommonButtons(formKey: _formKey, submit: _handleSubmitted),
    ]);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: _appBar,
      body: new Form(key: _formKey, child: c3),
    );
  }
}
