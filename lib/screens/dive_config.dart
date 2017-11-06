import 'package:flutter/material.dart';
import 'general_settings.dart';
import 'dive_segment.dart';
import 'gas_edit.dart';
import 'dive_plan.dart';
import '../deco/plan.dart';

class DiveConfig extends StatefulWidget {
  final AppBar _appBar;
  final Dive _dive;

  DiveConfig(this._appBar, this._dive);

  @override
  _DiveConfigState createState() => new _DiveConfigState(_appBar, _dive);
}

typedef Widget _ExpansionItemBodyBuilder();

class _ExpansionItem {
  final ExpansionPanelHeaderBuilder headerBuilder;
  final _ExpansionItemBodyBuilder bodyBuilder;
  bool isExpanded;
  _ExpansionItem(
      {this.headerBuilder, this.bodyBuilder, this.isExpanded = false});
}

class _DiveConfigState extends State<DiveConfig> {
  final Dive _dive;
  final AppBar _appBar;
  List<_ExpansionItem> _epanels = new List<_ExpansionItem>();
  var _saveGas;

  Widget _expansionTitle(String text) {
    return new Container(
      child: new Text(text,
          style:
              new TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      alignment: Alignment.center,
    );
  }

  Widget _makeSettingsBody() {
    return new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Column(children: [
          new Row(children: [
            new Text("Gradient factors:  "),
            new Text("${_dive.gfLo.toString()}/${_dive.gfHi.toString()}")
          ]),
          new Row(children: [
            new Text("ATM Pressure:  "),
            new Text("${_dive.atmPressure}")
          ]),
          new Row(children: [
            new Text("Descent:  "),
            new Text("${_dive.descentRate} ${_dive.metric?"M":"ft"}/min")
          ]),
          new Row(children: [
            new Text("Ascent:  "),
            new Text("${_dive.ascentRate} ${_dive.metric?"M":"ft"}/min")
          ]),
          new IconButton(
            icon: new Icon(Icons.edit),
            tooltip: 'Edit Dive Settings',
            onPressed: () {
              Navigator.of(context).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new GeneralSettings(appBar: _appBar, dive: _dive);
              }));
            },
          ),
        ]));
  }

  Widget _makeGassesBody() {
    return new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Column(children: _gasses()));
  }

  Widget _makeSegmentsBody() {
    return new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Column(children: _segments()));
  }

  _DiveConfigState(this._appBar, this._dive) {
    _saveGas = (Segment segment, Gas oldGas, Gas newGas) => setState(() {
          if (oldGas != null) segment.removeGas(oldGas);
          segment.addGas(newGas);
          Navigator.of(context).pop();
        });
    _epanels.add(new _ExpansionItem(
      headerBuilder: (BuildContext context, bool isExpanded) =>
          _expansionTitle("Settings"),
      bodyBuilder: _makeSettingsBody,
    ));
    _epanels.add(new _ExpansionItem(
        headerBuilder: (BuildContext context, bool isExpanded) =>
            _expansionTitle("Gasses"),
        bodyBuilder: _makeGassesBody));
    _epanels.add(new _ExpansionItem(
        headerBuilder: (BuildContext context, bool isExpanded) =>
            _expansionTitle("Dive Segments"),
        bodyBuilder: _makeSegmentsBody));
  }

  Widget _gasWidget(Segment segment, Gas g, bool allowDelete) {
    Widget label = new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
      new Expanded(child: new Text("$g")),
      new IconButton(
        icon: new Icon(Icons.edit),
        tooltip: 'Edit Gas',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
            return new GasEdit(
                appBar: _appBar, gas: g, segment: segment, save: _saveGas);
          }));
        },
      ),
    ]);
    Widget ret;
    if (allowDelete)
      ret = new Chip(
        label: label,
        onDeleted: () => setState(() => segment.removeGas(g)),
      );
    else
      ret = new Chip(label: label);
    return ret;
  }

  void _removeSegment(int index) {
    List<Segment> segments = new List<Segment>();
    Segment lastSegment;
    int i = 0;
    for (final s in _dive.segments.where((Segment s) => !s.isCalculated)) {
      if (s.type == SegmentType.LEVEL) {
        if (index != i) {
          if (s.isSurfaceInterval) {
            Segment ts = new Segment.surfaceInterval(s.time);
            ts.addAllGasses(s.gasses);
            segments.add(ts);
          } else {
            int tmptime = s.time +
                (lastSegment != null && lastSegment.type != SegmentType.LEVEL
                    ? lastSegment.time
                    : 0);
            segments.add(new Segment(s.type, _dive.mbarToDepth(s.depth), 0.0,
                tmptime, s.gas, false, s.ceiling));
          }
        }
      }
      lastSegment = s;
      i++;
    }
    _dive.clearSegments();
    lastSegment = null;
    for (Segment s in segments) {
      if (s.isSurfaceInterval)
        _dive.addSurfaceInterval(s.time).addAllGasses(_dive.dives.first.gasses);
      else
        _dive.move(
            lastSegment == null ? 0 : lastSegment.depth, s.depth, s.time);
      lastSegment = s;
    }
  }

  Widget _segmentWidget(int depth, int time, bool allowDelete, int idx,
      int ceiling, bool surfaceInterval) {
    Widget label = new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
      new Expanded(
          child: new Text(
              "${surfaceInterval?"Surface Interval":"${depth}M"}, $time min")),
      new IconButton(
        icon: new Icon(Icons.edit),
        tooltip: 'Edit Segment',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
            return new DiveSegment(
                appBar: _appBar, dive: _dive, index: idx, ceiling: ceiling);
          }));
        },
      ),
    ]);
    Widget ret;
    if (allowDelete)
      ret = new Chip(
        label: label,
        onDeleted: () => setState(() => _removeSegment(idx)),
      );
    else
      ret = new Chip(label: label);
    return ret;
  }

  List<Widget> _gasses() {
    List<Widget> gchildren = new List<Widget>();
    List<Segment> dives = _dive.dives;
    int idx = 1;
    for (Segment segment in dives) {
      if (idx > 1) gchildren.add(new Divider());
      gchildren.add(new Padding(
          padding: const EdgeInsets.all(2.0), child: new Text("Dive $idx")));
      bool allowDelete = segment.gasses.length > 1;
      for (final g in segment.gasses) {
        gchildren.add(new Padding(
            padding: const EdgeInsets.all(2.0),
            child: _gasWidget(segment, g, allowDelete)));
      }
      gchildren.add(new Padding(
          padding: const EdgeInsets.all(2.0),
          child: new IconButton(
            icon: new Icon(Icons.add),
            tooltip: 'Add Gas',
            onPressed: () {
              Navigator.of(context).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new GasEdit(
                    appBar: _appBar,
                    gas: new Gas.bottom(.21, .0, 1.2),
                    segment: segment,
                    save: _saveGas);
              }));
            },
          )));
      idx++;
    }
    return gchildren;
  }

  List<Widget> _segments() {
    List<Widget> gchildren = new List<Widget>();
    bool allowDelete = _dive.segments
            .where((Segment s) =>
                s.type == SegmentType.LEVEL &&
                !s.isCalculated &&
                !s.isSurfaceInterval)
            .length >
        1;
    Segment prev;
    int idx = 0;
    int ceiling = 0;
    for (final s in _dive.segments.where((Segment s) => !s.isCalculated)) {
      if (s.type == SegmentType.LEVEL) {
        int time = s.time;
        if (prev != null && prev.type != SegmentType.LEVEL) time += prev.time;
        gchildren.add(new Padding(
            padding: const EdgeInsets.all(2.0),
            child: _segmentWidget(
                _dive.mbarToDepth(s.depth),
                time,
                s.isSurfaceInterval ? true : allowDelete,
                idx,
                ceiling,
                s.isSurfaceInterval)));
        ceiling = s.isSurfaceInterval ? 0 : _dive.mbarToDepth(s.ceiling);
      }
      prev = s;
      idx++;
    }
    gchildren.add(new Padding(
        padding: const EdgeInsets.all(2.0),
        child: new IconButton(
          icon: new Icon(Icons.add),
          tooltip: 'Add Segment',
          onPressed: () {
            Navigator.of(context).push(
                new MaterialPageRoute<Null>(builder: (BuildContext context) {
              return new DiveSegment(
                  appBar: _appBar, dive: _dive, index: -1, ceiling: ceiling);
            }));
          },
        )));
    return gchildren;
  }

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(padding: const EdgeInsets.all(10.0), children: [
      new Card(
          child: new ExpansionPanelList(
              children: _epanels.map((_ExpansionItem item) {
                return new ExpansionPanel(
                    isExpanded: item.isExpanded,
                    headerBuilder: item.headerBuilder,
                    body: item.bodyBuilder());
              }).toList(),
              expansionCallback: (int panelIndex, bool isExpanded) => setState(
                  () => _epanels[panelIndex].isExpanded = !isExpanded))),
      new Card(child: new DivePlan(_dive)),
    ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
    );
  }
}
