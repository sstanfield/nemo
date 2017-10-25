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
  _ExpansionItem({this.headerBuilder, this.bodyBuilder, this.isExpanded = false});
}

class _DiveConfigState extends State<DiveConfig> {
  final Dive _dive;
  final AppBar _appBar;
  List<_ExpansionItem> _epanels = new List<_ExpansionItem>();
  var _saveGas;

  Widget _expansionTitle(String text) {
    return new Container(
      child: new Text(text, style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      alignment:  Alignment.center,);
  }

  Widget _makeSettingsBody() {
    return new Padding(
          padding: const EdgeInsets.all(10.0),
          child: new Column(children: [
        new Row(children: [new Text("Gradient factors:  "), new Text("${(_dive.gfLo*100).round().toString()}/${(_dive.gfHi*100).round().toString()}")]),
        new Row(children: [new Text("ATM Pressure:  "), new Text("${_dive.atmPressure}")]),
        new Row(children: [new Text("Descent:  "), new Text("${(_dive.descentMM / 1000).round()} M/min")]),
        new Row(children: [new Text("Assent:  "), new Text("${(_dive.ascentMM / 1000).round()} M/min")]),
        new IconButton(
          icon: new Icon(Icons.edit),
          tooltip: 'Edit Dive Settings',
          onPressed: () {
                          Navigator.of(context).push(new MaterialPageRoute<Null>(
                              builder: (BuildContext context) {
                                return new GeneralSettings(appBar: _appBar, dive: _dive);
                              })
                          );},
        ),
          ])
    );
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
    _saveGas = (Gas oldGas, Gas newGas) => setState(() {
      if (oldGas != null) _dive.removeGas(oldGas);
      _dive.addGas(newGas);
      Navigator.of(context).pop();
    });
    _epanels.add(new _ExpansionItem(
      headerBuilder: (BuildContext context, bool isExpanded) => _expansionTitle("Settings"),
      bodyBuilder: _makeSettingsBody,
     ));
    _epanels.add(new _ExpansionItem(
      headerBuilder: (BuildContext context, bool isExpanded) => _expansionTitle("Gasses"),
      bodyBuilder: _makeGassesBody
    ));
    _epanels.add(new _ExpansionItem(
      headerBuilder: (BuildContext context, bool isExpanded) => _expansionTitle("Dive Segments"),
      bodyBuilder: _makeSegmentsBody));
  }

  Widget _gasWidget(Gas g, bool allowDelete) {
    Widget label = new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(child: new Text("$g")),
          new IconButton(
            icon: new Icon(Icons.edit),
            tooltip: 'Edit Gas',
            onPressed: () {
              Navigator.of(context).push(new MaterialPageRoute<Null>(
                  builder: (BuildContext context) {
                    return new GasEdit(appBar: _appBar, gas: g, save: _saveGas);
                  })
              );},
          ),
        ]
    );
    Widget ret;
    if (allowDelete) ret = new Chip(
      label: label,
      onDeleted: () => setState(() => _dive.removeGas(g)),
    );
    else ret = new Chip(label: label);
    return ret;
  }

  Widget _segmentWidget(int depth, int time, bool allowDelete) {
    Widget label = new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(child: new Text("${depth}M, $time min")),
          new IconButton(
            icon: new Icon(Icons.edit),
            tooltip: 'Edit Segment',
            onPressed: () {
              Navigator.of(context).push(new MaterialPageRoute<Null>(
                  builder: (BuildContext context) {
                    return new DiveSegment(appBar: _appBar, dive: _dive);
                  })
              );},
          ),
        ]
    );
    Widget ret;
    if (allowDelete) ret = new Chip(
      label: label,
      //onDeleted: () => setState(() => _dive.removeGas(g)),
    );
    else ret = new Chip(label: label);
    return ret;
  }

  List<Widget> _gasses() {
    List<Widget> gchildren = new List<Widget>();
    bool allowDelete = _dive.gasses.length > 1;
    for (final g in _dive.gasses) {
      gchildren.add(new Padding(padding: const EdgeInsets.all(2.0), child: _gasWidget(g, allowDelete)));
    }
    gchildren.add(new Padding(padding: const EdgeInsets.all(2.0), child: new IconButton(
            icon: new Icon(Icons.add),
            tooltip: 'Add Gas',
            onPressed: () {
              Navigator.of(context).push(new MaterialPageRoute<Null>(
                  builder: (BuildContext context) {
                    return new GasEdit(appBar: _appBar, gas: new Gas.bottom(.21, .0, 1.2), save: _saveGas);
                  })
              );},
          )));
    return gchildren;
  }

  List<Widget> _segments() {
    List<Widget> gchildren = new List<Widget>();
    bool allowDelete = _dive.segments.where((Segment s) => s.type == SegmentType.LEVEL && !s.calculated).length > 1;
    Segment prev;
    for (final s in _dive.segments.where((Segment s) => !s.calculated)) {
      if (s.type == SegmentType.LEVEL) {
        int time = s.time;
        if (prev != null && prev.type != SegmentType.LEVEL) time += prev.time;
        gchildren.add(new Padding(padding: const EdgeInsets.all(2.0),
            child: _segmentWidget(_dive.mbarToDepthM(s.depth), time, allowDelete)));
      }
      prev = s;
    }
    /*gchildren.add(*/new Padding(padding: const EdgeInsets.all(2.0), child: new IconButton(
      icon: new Icon(Icons.add),
      tooltip: 'Add Segment',
      onPressed: () {
        /*Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return new GasEdit(appBar: _appBar, gas: new Gas.bottom(.21, .0, 1.2), save: _saveGas);
            })
        );*/},
    ));//);
    return gchildren;
  }

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(
        padding: const EdgeInsets.all(10.0),
        children: [
      new Card(child:
      new ExpansionPanelList(children: _epanels.map((_ExpansionItem item) {
        return new ExpansionPanel(
            isExpanded: item.isExpanded,
            headerBuilder: item.headerBuilder,
            body: item.bodyBuilder()
        );
      }).toList(), expansionCallback: (int panelIndex, bool isExpanded) => setState(() => _epanels[panelIndex].isExpanded = !isExpanded))),
      new Card(child: new DivePlan(_dive)),
    ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
    );
  }
}
