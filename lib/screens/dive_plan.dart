import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DivePlan extends StatelessWidget {
  final Plan _plan;
  static final headerStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.black,);
  static final diveNameStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.black,);
  static final highPPO2Style = new TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

  DivePlan(this._plan);

  @override
  Widget build(BuildContext context) {
    _plan.calcDeco();
    List<Widget> col1 = new List<Widget>();
    List<Widget> col2 = new List<Widget>();
    List<Widget> col3 = new List<Widget>();
    List<Widget> col4 = new List<Widget>();
    List<Widget> col5 = new List<Widget>();
    List<Widget> col6 = new List<Widget>();
    List<Widget> rows = new List<Widget>();
    int runtime = 0;
    int diveNum = 0;
    for (final dive in _plan.dives) {
      diveNum++;
      runtime = 0;
      rows.add(new Row(children: [
        new Expanded(child: new Column(children: col1)),
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
      col1.add(new Text("Type", style: headerStyle));
      col2.add(new Text("Depth", style: headerStyle));
      col3.add(new Text("Stop", style: headerStyle));
      col4.add(new Text("Runtime", style: headerStyle));
      col5.add(new Text("Gas", style: headerStyle));
      col6.add(new Text("PPO2", style: headerStyle));
      if (diveNum > 1) rows.add(new Divider(height: 24.0,));
      rows.add(new Text(
          "Dive #$diveNum ${dive.surfaceInterval>0?" Surface Interval ${dive.surfaceInterval} minutes":""}",
          style: diveNameStyle
      ));
      for (final e in dive.segments) {
        if (e.type == SegmentType.DOWN) col1.add(new Text("DESC"));
        if (e.type == SegmentType.UP) col1.add(new Text("ASC"));
        if (e.type == SegmentType.LEVEL) {
          if (e.isCalculated) col1.add(new Text("DECO"));
          else col1.add(new Text("BTM"));
        }
        col2.add(new Text("${dive.mbarToDepth(e.depth)}${dive.metric?"M":"ft"}"));
        col3.add(new Text("${e.time}"));
        runtime += e.time;
        col4.add(new Text("$runtime"));
        col5.add(new Text("${e.gas}"));
        double ppo2 = e.gas.fO2 * ((e.depth / 1000));
        if (ppo2 > e.gas.ppo2)
          col6.add(new Text("${ppo2.toStringAsFixed(2)}", style: highPPO2Style));
        else
          col6.add(new Text("${ppo2.toStringAsFixed(2)}"));
      }
    }
    rows.add(new Row(children: [
      new Expanded(child: new Column(children: col1)),
      new Expanded(child: new Column(children: col2)),
      new Expanded(child: new Column(children: col3)),
      new Expanded(child: new Column(children: col4)),
      new Expanded(child: new Column(children: col5)),
      new Expanded(child: new Column(children: col6))
    ]));
    return new Column(children: rows);
  }
}
