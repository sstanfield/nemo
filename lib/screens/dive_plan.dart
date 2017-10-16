import 'package:flutter/material.dart';
import '../deco/plan.dart';

class DivePlan extends StatelessWidget {
  final AppBar _appBar;
  final BottomNavigationBar _botNavBar;
  final Dive _dive;

  DivePlan(this._appBar, this._botNavBar, this._dive);

  @override
  Widget build(BuildContext context) {
    List<Widget> col1 = new List<Widget>();
    List<Widget> col2 = new List<Widget>();
    List<Widget> col3 = new List<Widget>();
    List<Widget> col4 = new List<Widget>();
    List<Widget> col5 = new List<Widget>();
    List<Widget> col6 = new List<Widget>();
    int runtime = 0;
    for (final e in _dive.segments) {
      if (e.type == SegmentType.DOWN) col1.add(new Text("DESC"));
      if (e.type == SegmentType.UP) col1.add(new Text("ASC"));
      if (e.type == SegmentType.LEVEL) col1.add(new Text("---"));
      col2.add(new Text("${e.depth}"));
      col3.add(new Text("${e.time}"));
      runtime += e.time;
      col4.add(new Text("$runtime"));
      col5.add(new Text("${e.gas}"));
      double ppo2 = e.gas.fO2*((e.depth/10.0)+1);
      if (ppo2 > e.gas.ppo2)
        col6.add(new Text("${ppo2.toStringAsFixed(2)}", style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.red)));
      else
        col6.add(new Text("${ppo2.toStringAsFixed(2)}"));
    }
    return new Scaffold(
      appBar: _appBar,
      body: new Row(children: [new Column(children: col1),
                               new Expanded(child: new Column(children: col2)),
                               new Expanded(child: new Column(children: col3)),
                               new Expanded(child: new Column(children: col4)),
                               new Expanded(child: new Column(children: col5)),
                               new Expanded(child: new Column(children: col6))]),
      bottomNavigationBar: _botNavBar,
    );
  }
}
