import 'package:flutter/material.dart';
import '../deco/plan.dart';
import '../deco/segment_type.dart';

class DivePlan extends StatelessWidget {
  final Plan _plan;
  static final headerStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  static final diveNameStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  static final diveFooterStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  static final highPPO2Style =
      new TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

  DivePlan(this._plan);

  void _makeRows(List<Widget> rows, List<List<Widget>> cols, List<bool> showCol,
      double otu, double cns) {
    List<Widget> children = new List<Widget>();
    int i = 0;
    for (final col in cols) {
      if (showCol == null || showCol[i])
        children.add(new Expanded(child: new Column(children: col)));
      i++;
    }
    rows.add(new Row(children: children));
    rows.add(new Text(
        "OTUs: ${otu.toStringAsFixed(2)} CNS: ${cns.toStringAsFixed(2)}%",
        style: diveFooterStyle));
  }

  @override
  Widget build(BuildContext context) {
    _plan.calcDeco();
    List<Widget> col1 = new List<Widget>();
    List<Widget> col2 = new List<Widget>();
    List<Widget> col3 = new List<Widget>();
    List<Widget> col4 = new List<Widget>();
    List<Widget> col5 = new List<Widget>();
    List<Widget> col6 = new List<Widget>();
    List<Widget> colOtu = new List<Widget>();
    List<Widget> colCns = new List<Widget>();
    List<Widget> rows = new List<Widget>();
    int runtime = 0;
    int diveNum = 0;
    double otu = 0.0;
    double cns = 0.0;
    for (final dive in _plan.dives) {
      diveNum++;
      runtime = 0;
      if (diveNum > 1) {
        _makeRows(rows, [col1, col2, col3, col4, col5, col6, colOtu, colCns],
            null, otu, cns);
        otu = 0.0;
        cns = 0.0;
        col1 = new List<Widget>();
        col2 = new List<Widget>();
        col3 = new List<Widget>();
        col4 = new List<Widget>();
        col5 = new List<Widget>();
        col6 = new List<Widget>();
        colOtu = new List<Widget>();
        colCns = new List<Widget>();
      }
      col1.add(new Text("Type", style: headerStyle));
      col2.add(new Text("Depth", style: headerStyle));
      col3.add(new Text("Stop", style: headerStyle));
      col4.add(new Text("Time", style: headerStyle));
      col5.add(new Text("Gas", style: headerStyle));
      col6.add(new Text("PPO2", style: headerStyle));
      colOtu.add(new Text("OTU", style: headerStyle));
      colCns.add(new Text("CNS", style: headerStyle));
      if (diveNum > 1)
        rows.add(new Divider(
          height: 24.0,
        ));
      rows.add(new Text(
          "Dive #$diveNum ${dive.surfaceInterval > 0 ? " Surface Interval ${dive.surfaceInterval} minutes" : ""}",
          style: diveNameStyle));
      for (final e in dive.segments) {
        if (e.type == SegmentType.DOWN) col1.add(new Text("DESC"));
        if (e.type == SegmentType.UP) col1.add(new Text("ASC"));
        if (e.type == SegmentType.LEVEL) {
          if (e.isCalculated)
            col1.add(new Text("DECO"));
          else
            col1.add(new Text("BTM"));
        }
        col2.add(new Text(
            "${dive.mbarToDepth(e.depth)}${dive.metric ? "M" : "ft"}"));
        col3.add(new Text("${e.time}"));
        runtime += e.time;
        col4.add(new Text("$runtime"));
        col5.add(new Text("${e.gas}"));
        double ppo2 = e.gas.fO2 * ((e.depth / 1000));
        if (ppo2 > e.gas.ppo2)
          col6.add(
              new Text("${ppo2.toStringAsFixed(2)}", style: highPPO2Style));
        else
          col6.add(new Text("${ppo2.toStringAsFixed(2)}"));
        colOtu.add(new Text("${e.otu.toStringAsFixed(2)}"));
        colCns.add(new Text("${e.cns.toStringAsFixed(2)}"));
        otu += e.otu;
        cns += e.cns;
      }
    }
    _makeRows(rows, [col1, col2, col3, col4, col5, col6, colOtu, colCns], null,
        otu, cns);
    return new Column(children: rows);
  }
}
