import 'dart:math';
import 'dart:convert';

final List<double> n2AsA = const [
  1.2599,
  1.0000,
  0.8618,
  0.7562,
  0.6667,
  0.5933,
  0.5282,
  0.4701,
  0.4187,
  0.3798,
  0.3497,
  0.3223,
  0.2971,
  0.2737,
  0.2523,
  0.2327
];
final List<double> n2AsB = const [
  1.2599,
  1.0000,
  0.8618,
  0.7562,
  0.6667,
  0.5600,
  0.4947,
  0.4500,
  0.4187,
  0.3798,
  0.3497,
  0.3223,
  0.2850,
  0.2737,
  0.2523,
  0.2327
];
final List<double> n2AsC = const [
  1.2599,
  1.0000,
  0.8618,
  0.7562,
  0.6200,
  0.5043,
  0.4410,
  0.4000,
  0.3750,
  0.3500,
  0.3295,
  0.3065,
  0.2835,
  0.2610,
  0.2480,
  0.2327
];

enum SegmentType { UP, DOWN, LEVEL }

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
  Gas.deco(double fO2, double fHe) : this(fO2, fHe, 1.6, .21, true, false);
  Gas.bottom(double fO2, double fHe, double ppo2)
      : this(fO2, fHe, ppo2, .18, true, true);

  factory Gas.fromJson(String json) {
    Map<String, Object> m = JSON.decode(json);
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
    return JSON.encode(m);
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

class Segment {
  final SegmentType type;
  final int depth; // in mbar
  final double rawTime;
  final int time;
  final Gas gas;
  final bool isCalculated;
  final int ceiling;

  Segment(this.type, this.depth, this.rawTime, this.time, this.gas,
      this.isCalculated, this.ceiling);

  static SegmentType segmentFromString(String str) {
    for (SegmentType e in SegmentType.values) {
      if (e.toString() == str) {
        return e;
      }
    }
    return null;
  }

  factory Segment.fromJson(String json) {
    Map<String, Object> map = JSON.decode(json);
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
    return new Segment(type, depth, rawTime, time, gas, isCalculated,
        ceiling);
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
    return JSON.encode(m);
  }
}

/*

    Fresh Water = 1000kg/m³
    EN13319 = 1020 kg/m³
    Salt Water = 1030 kg/m³

 */
/*
Use mm for distance (10ft = 3048mm)
Use mbar for pressure.
 */
class Dive {
  static final int _compartments = 16;
  final List<double> _tN = new List<double>(_compartments);
  final List<double> _tH = new List<double>(_compartments);
  final List<double> _initialN = new List<double>(_compartments);
  final List<double> _initialH = new List<double>(_compartments);
  bool _clearInitial = true;
  double _gfLo = .5;
  double _gfHi = .8;
  double _gfSlope; // null
  int _ascentRate = 1000; // mbar/min
  int _descentRate = 1800; // mbar/min
  int _lastDepth = 0;
  int _atmPressure = 1013;
  int _lastStop;
  int _stopSize;
  bool _metric = true;
  //final double _partialWater = 056.7;
  final double _partialWater = 062.7;
  //final double _partialWater = 049.3;
  final List<double> _halfTimesN2 = const [
    4.00,
    8.00,
    12.50,
    18.50,
    27.00,
    38.30,
    54.30,
    77.00,
    109.00,
    146.00,
    187.00,
    239.00,
    305.00,
    390.00,
    498.00,
    635.00
  ]; // 1b 5.0
  final List<double> _halfTimesHe = const [
    1.51,
    3.02,
    4.72,
    6.99,
    10.21,
    14.48,
    20.53,
    29.11,
    41.20,
    55.19,
    70.69,
    90.34,
    115.29,
    147.42,
    188.24,
    240.03
  ]; // 1b 1.88
  final List<double> _heAs = const [
    1.7424,
    1.3830,
    1.1919,
    1.0458,
    0.9220,
    0.8205,
    0.7305,
    0.6502,
    0.5950,
    0.5545,
    0.5333,
    0.5189,
    0.5181,
    0.5176,
    0.5172,
    0.5119
  ];
  final List<double> _heBs = const [
    0.4245,
    0.5747,
    0.6527,
    0.7223,
    0.7582,
    0.7957,
    0.8279,
    0.8553,
    0.8757,
    0.8903,
    0.8997,
    0.9073,
    0.9122,
    0.9171,
    0.9217,
    0.9267
  ];
  final List<double> _n2As = n2AsC;
  final List<double> _n2Bs = const [
    0.5050,
    0.6514,
    0.7222,
    0.7825,
    0.8126,
    0.8434,
    0.8693,
    0.8910,
    0.9092,
    0.9222,
    0.9319,
    0.9403,
    0.9477,
    0.9544,
    0.9602,
    0.9653
  ];

  final List<Gas> _gasses = new List<Gas>();
  List<Segment> _segments = new List<Segment>();
  int _surfaceInterval = 0;

  Dive.fromJson(String json) {
    Map<String, Object> map = JSON.decode(json);
    _lastStop = map["_lastStop"];
    _stopSize = map["_stopSize"];
    _gfLo = map["_gfLo"];
    _gfHi = map["_gfHi"];
    _ascentRate = map["_ascentRate"];
    _descentRate = map["_descentRate"];
    _lastDepth = map["_lastDepth"];
    _atmPressure = map["_atmPressure"];
    metric = map["_metric"];
    if (map.containsKey("_gasses")) {
      _gasses.clear();
      for (String str in map["_gasses"]) {
        _gasses.add(new Gas.fromJson(str));
      }
    }
    if (map.containsKey("_segments")) {
      for (String str in map["_segments"]) {
        _segments.add(new Segment.fromJson(str));
      }
    }
    _reset();
  }

  void loadJson(String json) {
    Map<String, Object> map = JSON.decode(json);
    _lastStop = map["_lastStop"];
    _stopSize = map["_stopSize"];
    _gfLo = map["_gfLo"];
    _gfHi = map["_gfHi"];
    _ascentRate = map["_ascentRate"];
    _descentRate = map["_descentRate"];
    _lastDepth = map["_lastDepth"];
    _atmPressure = map["_atmPressure"];
    metric = map["_metric"];
    if (map.containsKey("_gasses")) {
      _gasses.clear();
      for (String str in map["_gasses"]) {
        _gasses.add(new Gas.fromJson(str));
      }
    }
    _segments.clear();
    if (map.containsKey("_segments")) {
      for (String str in map["_segments"]) {
        _segments.add(new Segment.fromJson(str));
      }
    }
    _reset();
  }

  String toJson() {
    var m = new Map<String, Object>();
    m["_gfLo"] = _gfLo;
    m["_gfHi"] = _gfHi;
    m["_ascentRate"] = _ascentRate;
    m["_descentRate"] = _descentRate;
    m["_lastDepth"] = _lastDepth;
    m["_atmPressure"] = _atmPressure;
    m["_lastStop"] = _lastStop;
    m["_stopSize"] = _stopSize;
    m["_metric"] = _metric;
    m["_segments"] = _segments;
    m["_gasses"] = _gasses;
    return JSON.encode(m);
  }

  int _rateMMToMbar(int rate) {
    return (rate / 10).round();
  }

  int _depthMMToMbar(int depth) {
    return (depth / 10).round() + _atmPressure;
  }

  int _mbarToDepthMM(int mbar) {
    return (mbar - _atmPressure) * 10;
  }

  int _mbarToRateMM(int mbar) {
    return mbar * 10;
  }

  static Gas _findGas(
      List<Gas> gasses, int atmPressure, int depth, SegmentType type) {
    if (gasses == null || gasses.length == 0) return Gas.air;
    Gas ret;
    gasses.forEach((Gas g) {
      if (g.use(depth - atmPressure, type) && (ret == null || g.fO2 > ret.fO2))
        ret = g;
    });
    if (ret == null) {
      // Failed to find a good fit, find something...
      gasses.forEach((Gas g) {
        if (ret == null || g.fO2 * depth < ret.fO2 * depth) ret = g;
      });
    }
    // Seem to have no gasses... Return good old air.
    if (ret == null) ret = Gas.air;
    return ret;
  }

  double _nextGf(int stop) {
    if ((stop - _stopSize - _atmPressure) < 0 || _gfSlope == null) return _gfHi;
    return (_gfSlope * (stop - _stopSize - _atmPressure)) + _gfHi;
  }

  void _clearInitialTissues() {
    double n2Partial = 0.79 * ((_atmPressure - _partialWater) / 1000.0);
    for (num i = 0; i < _compartments; i++) {
      _initialN[i] = n2Partial;
      _initialH[i] = 0.0;
    }
  }

  void _resetTissues() {
    if (_clearInitial) _clearInitialTissues();
    for (num i = 0; i < _compartments; i++) {
      _tN[i] = _initialN[i];
      _tH[i] = _initialH[i];
    }
  }

  void _reset({int atmDelta: 0}) {
    _resetTissues();
    _segments.removeWhere((Segment s) => s.isCalculated);
    _gfSlope = null;
    List<Segment> s = _segments;
    _segments = new List<Segment>();
    int tDepth = _atmPressure;
    if (_surfaceInterval > 0) _bottomInt(_atmPressure, _surfaceInterval.toDouble(), Gas.air);
    for (final Segment e in s) {
      if (e.type == SegmentType.DOWN) {
        _descend(_descentRate, tDepth, e.depth + atmDelta, false);
        tDepth = e.depth + atmDelta;
      }
      if (e.type == SegmentType.UP) {
        _ascend(_ascentRate, tDepth, e.depth + atmDelta, false);
        tDepth = e.depth + atmDelta;
      }
      if (e.type == SegmentType.LEVEL) {
        _bottom(e.depth + atmDelta, e.rawTime);
        tDepth = e.depth + atmDelta;
      }
    }
    if (_segments.length > 1) {
      int fs = _firstStop(_gfLo);
      _gfSlope = (_gfHi - _gfLo) / -(fs - _atmPressure);
      _calcDecoInt(_nextGf(fs));
    }
  }

  void _descend(int rateMbar, int fromDepth, int toDepth, bool calculated) {
    double t = (toDepth - fromDepth) / rateMbar;
    double bar = fromDepth / 1000.0;
    double brate = rateMbar / 1000.0; // rate of decent in bar
    Gas gas;
    if (rateMbar < 0 &&
        _segments.length > 0 &&
        _segments.last.type == SegmentType.UP) {
      gas = _segments.last.gas;
    } else {
      gas = _findGas(_gasses, _atmPressure, rateMbar > 0 ? toDepth : fromDepth,
          rateMbar > 0 ? SegmentType.DOWN : SegmentType.UP);
    }
    for (int i = 0; i < _compartments; i++) {
      double po = _tN[i];
      double pio = (bar - (_partialWater / 1000.0)) * gas.fN2;
      double R = brate * gas.fN2;
      double k = log(2) / _halfTimesN2[i];
      _tN[i] = pio + R * (t - (1 / k)) - (pio - po - (R / k)) * exp(-k * t);

      po = _tH[i];
      pio = (bar - (_partialWater / 1000.0)) * gas.fHe;
      R = brate * gas.fHe;
      k = log(2) / _halfTimesHe[i];
      _tH[i] = pio + R * (t - (1 / k)) - (pio - po - (R / k)) * exp(-k * t);
    }
    if (rateMbar > 0)
      _segments.add(new Segment(
          SegmentType.DOWN, toDepth, t, t.ceil(), gas, calculated, 0));
    if (rateMbar < 0) {
      if (_segments.length > 0) {
        Segment lastSeg = _segments.removeLast();
        if (lastSeg.type == SegmentType.UP) {
          t += lastSeg.rawTime;
        } else {
          _segments.add(lastSeg);
        }
      }
      _segments.add(new Segment(
          SegmentType.UP, toDepth, t, t.round(), gas, calculated, 0));
    }
  }

  void _ascend(int rateMbar, int fromDepth, int toDepth, bool calculated) {
    _descend(-rateMbar, fromDepth, toDepth, calculated);
  }

  void _bottomInt(int depth, double time, Gas gas) {
    if (time > 0) {
      double bar = depth / 1000.0;
      for (num i = 0; i < _compartments; i++) {
        double po = _tN[i];
        double pio = (bar - (_partialWater / 1000.0)) * gas.fN2;
        _tN[i] = po + (pio - po) * (1 - pow(2, -time / _halfTimesN2[i]));

        po = _tH[i];
        pio = (bar - (_partialWater / 1000.0)) * gas.fHe;
        _tH[i] = po + (pio - po) * (1 - pow(2, -time / _halfTimesHe[i]));
      }
    }
    _lastDepth = depth;
  }

  void _bottom(int depth, double time) {
    Gas gas = _findGas(_gasses, _atmPressure, depth, SegmentType.LEVEL);
    _bottomInt(depth, time, gas);
    _segments.add(new Segment(SegmentType.LEVEL, depth, time, time.ceil(), gas,
        false, _calcCeiling(_gfLo)));
  }

  int _calcCeiling(double gf) // Depth (in mbar) of current ceiling.
  {
    double ceiling = 0.0;
    for (int i = 0; i < _compartments; i++) {
      double a =
          ((_n2As[i] * _tN[i]) + (_heAs[i] * _tH[i])) / (_tN[i] + _tH[i]);
      double b =
          ((_n2Bs[i] * _tN[i]) + (_heBs[i] * _tH[i])) / (_tN[i] + _tH[i]);
      double ceil = ((_tN[i] + _tH[i]) - (gf * a)) / ((gf / b) - gf + 1);
      if (ceil > ceiling) ceiling = ceil;
    }
    int stop = (ceiling * 1000).round();
    return (stop < _atmPressure) ? _atmPressure : stop;
  }

  int _nextStop(double gf) // Depth (in mbar) of next stop.
  {
    int stop = _calcCeiling(gf);
    if (stop <= _atmPressure) return _atmPressure;
    if (stop <= _lastStop) return _lastStop;
    bool done = false;
    int ret = 0;
    for (int i = _lastStop + _stopSize; !done; i += _stopSize) {
      if (stop < i) {
        ret = i;
        done = true;
      }
    }
    return ret;
  }

  int _firstStop(double gf) // Depth (in mbar) of first stop.
  {
    int fs = _nextStop(gf);
    _ascend(_ascentRate, _lastDepth, fs, true);
    _lastDepth = fs;

    // Comment next two lines out to start gf slope at natural first stop even
    // if it has cleared in the ascent to it- leaving them in seems to match
    // Shearwater closer and not Subsurface...
    int nfs = _nextStop(gf);
    if (nfs < fs) return _firstStop(gf);

    return fs;
  }

  void _calcDecoInt(num gf) {
    int fs = _nextStop(gf);
    if (fs < _lastDepth) {
      _ascend(_ascentRate, _lastDepth, fs, true);
      _lastDepth = fs;
    }
    if (fs <= _atmPressure) return; // At surface, done...
    double ngf = _nextGf(fs);
    int nfs = _nextStop(ngf);
    if (nfs == fs) {
      double t = 0.0;
      bool done = false;
      Gas gas = _findGas(_gasses, _atmPressure, fs, SegmentType.UP);
      while (!done) {
        _bottomInt(fs, .3, gas);
        t += .3;
        nfs = _nextStop(ngf);
        if (nfs < fs) {
          done = true;
        }
      }
      Segment lastSeg = _segments.removeLast();
      if (lastSeg.type != SegmentType.LEVEL) {
        if (lastSeg.rawTime < 1.0) {
          t += lastSeg.rawTime;
        } else {
          if (lastSeg.time > lastSeg.rawTime)
            _bottomInt(
                lastSeg.depth, lastSeg.time - lastSeg.rawTime, lastSeg.gas);
          else
            t += lastSeg.rawTime - lastSeg.time;
          _segments.add(lastSeg);
        }
      }
      _bottomInt(fs, t.ceil() - t, gas);
      _segments
          .add(new Segment(SegmentType.LEVEL, fs, t, t.ceil(), gas, true, 0));
    }
    if (nfs > _atmPressure) _calcDecoInt(ngf);
  }

  Dive() {
    _clearInitial = true;
    _lastStop = _depthMMToMbar(3000);
    _stopSize = _rateMMToMbar(3000);
    _reset();
  }

  void setInitialLoadings(Dive dive) {
    if (dive == null) _clearInitial = true;
    else {
      _clearInitial = false;
      for (num i = 0; i < _compartments; i++) {
        _initialN[i] = dive._tN[i];
        _initialH[i] = dive._tH[i];
      }
    }
    _reset();
  }

  void resetAllData() {
    _gfLo = .5;
    _gfHi = .8;
    _ascentRate = 1000; // mbar/min
    _descentRate = 1800; // mbar/min
    _lastDepth = 0;
    _atmPressure = 1013;
    _lastStop = _depthMMToMbar(_metric?3000:3048);
    _stopSize = _rateMMToMbar(_metric?3000:3048);
    _gasses.clear();
    _segments.clear();
    _clearInitial = true;
    _reset();
  }

  int get gfLo => (_gfLo * 100).round();
  int get gfHi => (_gfHi * 100).round();
  set gfLo(int gf) => _gfLo = gf / 100.0;
  set gfHi(int gf) => _gfHi = gf / 100.0;

  int get ascentMM => _mbarToRateMM(_ascentRate);
  set ascentMM(int mm) => _ascentRate = _rateMMToMbar(mm);
  int get descentMM => _mbarToRateMM(_descentRate);
  set descentMM(int mm) => _descentRate = _rateMMToMbar(mm);

  bool get metric => _metric;
  set metric(bool metric) {
    if (metric == _metric) return;
    _metric = metric;
    _lastStop = _depthMMToMbar(_metric?3000:3048);
    _stopSize = _rateMMToMbar(_metric?3000:3048);
    _reset();
  }

  int get surfaceInterval => _surfaceInterval;
  set surfaceInterval(int i) {
    _surfaceInterval = i;
    _reset();
  }

  void clearSegments() {
    _segments.clear();
    _resetTissues();
  }

  set atmPressure(int atmPressure) {
    int oldAtm = _atmPressure;
    _atmPressure = atmPressure;
    _lastStop = _depthMMToMbar(_metric?3000:3048);
    _reset(atmDelta: atmPressure - oldAtm);
  }

  get atmPressure => _atmPressure;

  void descend(int fromDepth, int toDepth) {
    _descend(
        _descentRate, depthToMbar(fromDepth), depthToMbar(toDepth), false);
  }

  void ascend(int fromDepth, int toDepth) {
    _ascend(
        _ascentRate, depthToMbar(fromDepth), depthToMbar(toDepth), false);
  }

  void addBottom(int depth, int time) {
    _bottom(depthToMbar(depth), time.toDouble());
  }

  void move(int from, int to, int time) {
    if (from < to)
      descend(from, to);
    else
      ascend(from, to);
    int t = time - segments.last.time;
    addBottom(to, t > 0 ? t : 0);
  }

  void calcDeco() {
    _reset();
  }

  int depthToMbar(int depth) {
    return _depthMMToMbar(_metric?depth*1000:(depth*304.8).round());
  }

  int rateToMbar(int depth) {
    return _rateMMToMbar(_metric?depth*1000:(depth*304.8).round());
  }

  int mbarToDepth(int mbar) {
    return (_mbarToDepthMM(mbar) / (_metric?1000:304.8)).round();
  }

  int mbarToRate(int mbar) {
    return (_mbarToRateMM(mbar) / (_metric?1000:304.8)).round();
  }

  int get ascentRate => mbarToRate(_ascentRate);
  int get descentRate => mbarToRate(_descentRate);
  set ascentRate(int rate) => _ascentRate = rateToMbar(rate);
  set descentRate(int rate) => _descentRate = rateToMbar(rate);

  List<Segment> get segments =>
      new List.unmodifiable(_segments);

  List<Gas> get gasses => _gasses == null ? null : new List.unmodifiable(_gasses..sort());
  void addGas(Gas gas) {
    _gasses?.add(gas);
  }

  void removeGas(Gas gas) {
    _gasses?.remove(gas);
  }

  void addAllGasses(List<Gas> g) {
    _gasses?.addAll(g);
  }
}

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
}