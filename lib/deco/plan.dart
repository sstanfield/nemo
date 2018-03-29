import 'dart:convert';

import 'dive.dart';

class Plan {
  final List<Dive> _dives = new List<Dive>();
  bool _metric = true;

  Plan() {
    _dives.add(new Dive());
  }

  Plan.fromJson(String json) {
    Map<String, Object> map = JSON.decode(json);
    metric = map["_metric"];
    if (map.containsKey("_dives")) {
      for (String str in map["_dives"]) {
        _dives.add(new Dive.fromJson(str));
      }
    }
    calcDeco();
  }

  void loadJson(String json) {
    Map<String, Object> map = JSON.decode(json);
    metric = map["_metric"];
    if (map.containsKey("_dives")) {
      _dives.clear();
      for (String str in map["_dives"]) {
        _dives.add(new Dive.fromJson(str));
      }
    }
    calcDeco();
  }

  String toJson() {
    var m = new Map<String, Object>();
    m["_metric"] = _metric;
    m["_dives"] = _dives;
    return JSON.encode(m);
  }

  bool get metric => _metric;
  set metric(bool metric) {
    _metric = metric;
    for (Dive d in _dives) {
      d.metric = metric;
    }
  }

  void addDive(Dive dive) {
    _dives.add(dive);
    calcDeco();
  }

  void calcDeco() {
    Dive prevDive;
    for (Dive d in _dives) {
      d.setInitialLoadings(prevDive);
      d.calcDeco();
      prevDive = d;
    }
  }

  void reset() {
    _dives.clear();
    _dives.add(new Dive());
  }

  List<Dive> get dives => new List.unmodifiable(_dives);

  void removeDive(int idx) {
    if (_dives.length > 1) _dives.removeAt(idx);
  }
}
