import 'dart:convert';

import 'segment_type.dart';

class Gas implements Comparable<Gas> {
  final double fO2;
  final double fN2;
  final double fHe;
  final double minPPO2;
  final double ppo2;
  final int _minDepth; // in mbar MINUS atm pressure
  final int _maxDepth; // in mbar MINUS atm pressure
  final bool useAscent;
  final bool useDescent;
  static final Gas air = new Gas.bottom(.21, 0.0, 1.4);

  int get minDepth => (_minDepth / 100).round();
  int get maxDepth => (_maxDepth / 100).round();

  Gas(this.fO2, this.fHe, this.ppo2, this.minPPO2, this.useAscent,
      this.useDescent)
      : fN2 = 1.0 - (fO2 + fHe),
        _minDepth = (fO2 >= .18 ? 0 : ((minPPO2 / fO2) * 1000).ceil() - 1000),
        _maxDepth = ((ppo2 / fO2) * 1000).floor() - 1000;
  Gas.deco(double fO2, double fHe) : this(fO2, fHe, 1.61, .21, true, false);
  Gas.bottom(double fO2, double fHe, double ppo2)
      : this(fO2, fHe, ppo2, .18, true, true);

  factory Gas.fromJson(String jsonStr) {
    Map<String, Object> m = json.decode(jsonStr);
    double fO2 = m["fO2"];
    double fHe = m["fHe"];
    double minPPO2 = m["minPPO2"];
    double ppo2 = m["ppo2"];
    bool useAscent = m["useAscent"];
    bool useDescent = m["useDescent"];
    return new Gas(fO2, fHe, ppo2, minPPO2, useAscent, useDescent);
  }

  String toJson() {
    var m = new Map<String, Object>();
    m["fO2"] = fO2;
    m["fHe"] = fHe;
    m["minPPO2"] = minPPO2;
    m["ppo2"] = ppo2;
    m["useAscent"] = useAscent;
    m["useDescent"] = useDescent;
    return json.encode(m);
  }

  bool use(int depth, SegmentType type) {
    if (depth >= _minDepth && depth <= _maxDepth) {
      if (type == SegmentType.DOWN && useDescent) return true;
      if (type == SegmentType.UP && useAscent) return true;
      if (type == SegmentType.LEVEL) return true;
    }
    return false;
  }

  String toString() {
    if (fHe > 0) return "${(fO2*100.0).round()}/${(fHe*100.0).round()}";
    return "${(fO2*100.0).round()}%";
  }

  bool operator ==(o) => o is Gas && o.fO2 == fO2 && o.fHe == fHe;
  int get hashCode => (fO2 * 1000 + fHe * 1000).ceil();

  @override
  int compareTo(Gas other) {
    if (this == other) return 0;
    if (fO2 < other.fO2) return -1;
    if (fO2 == other.fO2 && fHe < fHe) return -1;
    return 1;
  }
}

