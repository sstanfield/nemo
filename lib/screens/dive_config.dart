import 'package:flutter/material.dart';
import 'general_settings.dart';
import 'dive_segment.dart';
import 'gas_edit.dart';
import 'dive_plan.dart';
import '../deco/plan.dart';

class DiveConfig extends StatefulWidget {
  final AppBar _appBar;
  final Plan _plan;

  DiveConfig(this._appBar, this._plan);

  @override
  _DiveConfigState createState() => new _DiveConfigState(_appBar, _plan);
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
  final Plan _plan;
  final AppBar _appBar;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
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
        child: new Column(children: _diveSettings()));
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

  _DiveConfigState(this._appBar, this._plan) {
    _saveGas = (Dive dive, Gas oldGas, Gas newGas) => setState(() {
          if (oldGas != null) dive.removeGas(oldGas);
          dive.addGas(newGas);
          Navigator.of(context).pop();
        });
    _epanels.add(new _ExpansionItem(
      headerBuilder: (BuildContext context, bool isExpanded) =>
          _expansionTitle("Dive Settings"),
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

  Widget _diveSettingWidget(Dive dive, bool allowDelete, int idx) {
    Widget label = new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
      new Expanded(
          child: new Text("Dive $idx ${dive.gfLo.toString()}/${dive.gfHi.toString()}")),
      new IconButton(
        icon: new Icon(Icons.edit),
        tooltip: 'Edit Dive Settings',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new GeneralSettings(appBar: _appBar, dive: dive);
              }));
        },
      ),
    ]);
    Widget ret;
    if (allowDelete)
      ret = new Chip(
        label: label,
        onDeleted: () => setState(() => _removeDive(idx)),
      );
    else
      ret = new Chip(label: label);
    return ret;
  }

  Widget _gasWidget(Dive dive, Gas g, bool allowDelete) {
    Widget label = new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
      new Expanded(child: new Text("$g")),
      new IconButton(
        icon: new Icon(Icons.edit),
        tooltip: 'Edit Gas',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
            return new GasEdit(
                appBar: _appBar, gas: g, dive: dive, save: _saveGas);
          }));
        },
      ),
    ]);
    Widget ret;
    if (allowDelete)
      ret = new Chip(
        label: label,
        onDeleted: () => setState(() => dive.removeGas(g)),
      );
    else
      ret = new Chip(label: label);
    return ret;
  }

  void _removeDive(int index) {
    _plan.removeDive(index - 1);
  }

  void _removeSegment(Dive dive, int index) {
    List<Segment> segments = new List<Segment>();
    Segment lastSegment;
    int i = 0;
    for (final s in dive.segments.where((Segment s) => !s.isCalculated)) {
      if (s.type == SegmentType.LEVEL) {
        if (index != i) {
          int tmptime = s.time +
              (lastSegment != null && lastSegment.type != SegmentType.LEVEL
                  ? lastSegment.time
                  : 0);
          segments.add(new Segment(s.type, dive.mbarToDepth(s.depth), 0.0,
              tmptime, s.gas, false, s.ceiling));
        }
      }
      lastSegment = s;
      i++;
    }
    dive.clearSegments();
    lastSegment = null;
    for (Segment s in segments) {
      dive.move(lastSegment == null ? 0 : lastSegment.depth, s.depth, s.time);
      lastSegment = s;
    }
  }

  Widget _segmentWidget(Dive dive, int depth, int time, bool allowDelete, int idx,
      int ceiling) {
    Widget label = new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
      new Expanded(
          child: new Text("${depth}${dive.metric?"M":"ft"}, $time min")),
      new IconButton(
        icon: new Icon(Icons.edit),
        tooltip: 'Edit Segment',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
            return new DiveSegment(
                appBar: _appBar, dive: dive, index: idx, ceiling: ceiling);
          }));
        },
      ),
    ]);
    Widget ret;
    if (allowDelete)
      ret = new Chip(
        label: label,
        onDeleted: () => setState(() => _removeSegment(dive, idx)),
      );
    else
      ret = new Chip(label: label);
    return ret;
  }

  List<Widget> _diveSettings() {
    List<Widget> gchildren = new List<Widget>();
    int diveNum = 0;
    for (final dive in _plan.dives) {
      diveNum++;
      bool allowDelete = _plan.dives.length > 1;
          gchildren.add(new Padding(
              padding: const EdgeInsets.all(2.0),
              child: _diveSettingWidget(
                  dive,
                  allowDelete,
                  diveNum)));
      }
      gchildren.add(new Padding(
          padding: const EdgeInsets.all(2.0),
          child: new IconButton(
            icon: new Icon(Icons.add),
            tooltip: 'Add Dive',
            onPressed: () {
              setState(() {
                Dive d = new Dive();
                _plan.addDive(d);
              });
            },
          )));
    return gchildren;
  }

  List<Widget> _gasses() {
    List<Widget> gchildren = new List<Widget>();
    List<Dive> dives = _plan.dives;
    int idx = 1;
    for (final dive in dives) {
      Widget plusButton = new IconButton(
        icon: new Icon(Icons.add),
        tooltip: 'Add Gas',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new GasEdit(
                    appBar: _appBar,
                    gas: new Gas.bottom(.21, .0, 1.2),
                    dive: dive,
                    save: _saveGas);
              }));
        },
      );
      if (idx > 1) gchildren.add(new Divider());
      gchildren.add(new Padding(
          padding: const EdgeInsets.all(2.0), child: new Row(children: [new Text("Dive $idx"), plusButton])));
      bool allowDelete = dive.gasses.length > 1;
      for (final g in dive.gasses) {
        gchildren.add(new Padding(
            padding: const EdgeInsets.all(2.0),
            child: _gasWidget(dive, g, allowDelete)));
      }
      idx++;
    }
    return gchildren;
  }

  List<Widget> _segments() {
    List<Widget> gchildren = new List<Widget>();
    int diveNum = 0;
    for (final dive in _plan.dives) {
      diveNum++;
      List<Segment> segs = new List<Segment>();
      segs.addAll(dive.segments.where((Segment s) => !s.isCalculated));
      int ceiling = segs.length>0?dive.mbarToDepth(segs.last.ceiling):0;
      Widget plusButton = new IconButton(
        icon: new Icon(Icons.add),
        tooltip: 'Add Segment',
        onPressed: () {
          Navigator.of(context).push(
              new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new DiveSegment(
                    appBar: _appBar,
                    dive: dive,
                    index: -1,
                    ceiling: ceiling);
              }));
        },
      );
      gchildren.add(new Padding(
          padding: const EdgeInsets.all(2.0),
          child: new Row(children: [new Text("Dive $diveNum"), plusButton])));
      bool allowDelete = true;
      Segment prev;
      int idx = 0;
      ceiling = 0;
      for (final s in segs) {
        if (s.type == SegmentType.LEVEL) {
          int time = s.time;
          if (prev != null && prev.type != SegmentType.LEVEL) time += prev.time;
          gchildren.add(new Padding(
              padding: const EdgeInsets.all(2.0),
              child: _segmentWidget(
                  dive,
                  dive.mbarToDepth(s.depth),
                  time,
                  allowDelete,
                  idx,
                  ceiling)));
          ceiling = dive.mbarToDepth(s.ceiling);
        }
        prev = s;
        idx++;
      }
    }
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
      new Card(child: new DivePlan(_plan)),
    ]);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: _appBar,
      body: c3,
    );
  }
}
