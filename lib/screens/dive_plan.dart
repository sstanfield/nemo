import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DivePlan extends StatelessWidget {
  final Dive _dive;

  DivePlan(this._dive);

  @override
  Widget build(BuildContext context) {
    _dive.calcDeco();
    List<Widget> col1 = new List<Widget>();
    List<Widget> col2 = new List<Widget>();
    List<Widget> col3 = new List<Widget>();
    List<Widget> col4 = new List<Widget>();
    List<Widget> col5 = new List<Widget>();
    List<Widget> col6 = new List<Widget>();
    List<Widget> rows = new List<Widget>();
    int runtime = 0;
    for (final e in _dive.segments) {
      if (e.isSurfaceInterval) {
        runtime = 0;
        rows.add(new Row(children: [
          new Column(children: col1),
          new Expanded(child: new Column(children: col2)),
          new Expanded(child: new Column(children: col3)),
          new Expanded(child: new Column(children: col4)),
          new Expanded(child: new Column(children: col5)),
          new Expanded(child: new Column(children: col6))
        ]));
        col1 = new List<Widget>();
        col2 = new List<Widget>();
        col3 = new List<Widget>();
        col4 = new List<Widget>();
        col5 = new List<Widget>();
        col6 = new List<Widget>();
        rows.add(new Text("Surface Interval ${e.time} minutes"));
      } else {
        if (e.type == SegmentType.DOWN) col1.add(new Text("DESC"));
        if (e.type == SegmentType.UP) col1.add(new Text("ASC"));
        if (e.type == SegmentType.LEVEL) col1.add(new Text("---"));
        col2.add(new Text("${_dive.mbarToDepthM(e.depth)}"));
        col3.add(new Text("${e.time}"));
        runtime += e.time;
        col4.add(new Text("$runtime"));
        col5.add(new Text("${e.gas}"));
        double ppo2 = e.gas.fO2 * ((e.depth / 1000));
        if (ppo2 > e.gas.ppo2)
          col6.add(new Text("${ppo2.toStringAsFixed(2)}",
              style: new TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red)));
        else
          col6.add(new Text("${ppo2.toStringAsFixed(2)}"));
      }
    }
    rows.add(new Row(children: [
      new Column(children: col1),
      new Expanded(child: new Column(children: col2)),
      new Expanded(child: new Column(children: col3)),
      new Expanded(child: new Column(children: col4)),
      new Expanded(child: new Column(children: col5)),
      new Expanded(child: new Column(children: col6))
    ]));
    return new Column(children: rows);
  }
}
