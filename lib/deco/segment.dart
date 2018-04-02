import 'dart:convert';

import 'segment_type.dart';
import 'gas.dart';

class Segment {
  final SegmentType type;
  final int depth; // in mbar
  final double rawTime;
  final int time;
  final Gas gas;
  final bool isCalculated;
  final int ceiling;
  final double otu;
  final double cns;
  final double setpoint;

  Segment(this.type, this.depth, this.rawTime, this.time, this.gas,
      this.isCalculated, this.ceiling, this.otu, this.cns, this.setpoint);

  static SegmentType segmentFromString(String str) {
    for (SegmentType e in SegmentType.values) {
      if (e.toString() == str) {
        return e;
      }
    }
    return null;
  }

  factory Segment.fromJson(String jsonStr) {
    Map<String, Object> map = json.decode(jsonStr);
    SegmentType type = segmentFromString(map["type"]);
    int depth = map["depth"];
    double rawTime = map["rawTime"];
    int time = map["time"];
    Gas gas = new Gas.fromJson(map["gas"]);
    List<Gas> _gasses;
    if (map.containsKey("_gasses")) {
      _gasses = new List<Gas>();
      for (String str in map["_gasses"]) {
        _gasses.add(new Gas.fromJson(str));
      }
    }
    bool isCalculated = map["isCalculated"];
    int ceiling = map["ceiling"];
    double otu = map["otu"];
    double cns = map["cns"];
    double setpoint = map["setpoint"];
    if (setpoint == null) setpoint = 1.1;
    return new Segment(type, depth, rawTime, time, gas, isCalculated,
        ceiling, otu, cns, setpoint);
  }

  String toJson() {
    var m = new Map<String, Object>();
    m["type"] = type.toString();
    m["depth"] = depth;
    m["rawTime"] = rawTime;
    m["time"] = time;
    m["gas"] = gas;
    m["isCalculated"] = isCalculated;
    m["ceiling"] = ceiling;
    m["otu"] = otu;
    m["cns"] = cns;
    m["setpoint"] = setpoint;
    return json.encode(m);
  }
}

