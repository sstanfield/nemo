import 'dart:math';
import 'dart:convert';

import 'dive_consts.dart';
import 'gas.dart';
import 'segment_type.dart';
import 'segment.dart';

enum DiveType {OC, CCR, SCR}

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
  static final int _cnsPPO2Segments = 7;
  final List<double> _cnsPPO2Lo = [.5, .6, .7, .8, .9, 1.1, 1.5];
  final List<double> _cnsPPO2Hi = [.6, .7, .8, .9, 1.1, 1.5, 100.0];
  final List<double> _cnsLimitSlope = [-1800.0, -1500.0, -1200.0, -900.0, -600.0, -300.0, -750.0];
  final List<double> _cnsLimitIntercept = [1800.0, 1620.0, 1410.0, 1170.0, 900.0, 570.0, 1245.0];
  bool _clearInitial = true;
  double _gfLo = .5;
  double _gfHi = .8;
  DiveType _type = DiveType.OC;
  double _descentSetpoint = 1.0;
  double _bottomSetpoint = 1.0;
  double _decoSetpoint = 1.3;
  double _gfSlope; // null
  int _ascentRate = 1000; // mbar/min
  int _descentRate = 1800; // mbar/min
  int _lastDepth = 0;
  int _atmPressure = 1013;
  int _lastStop;
  int _stopSize;
  bool _metric = true;
  final double _partialWater = partialWater;
  final List<double> _halfTimesN2 = halfTimesN2;
  final List<double> _halfTimesHe = halfTimesHe;
  final List<double> _heAs = heAs;
  final List<double> _heBs = heBs;
  final List<double> _n2As = n2AsC;
  final List<double> _n2Bs = n2Bs;

  final List<Gas> _gasses = new List<Gas>();
  Gas _dil = Gas.air;
  List<Segment> _segments = new List<Segment>();
  int _surfaceInterval = 0;

  static DiveType typeFromString(String str) {
    for (DiveType e in DiveType.values) {
      if (e.toString() == str) {
        return e;
      }
    }
    return null;
  }

  Dive.fromJson(String json) {
    Map<String, Object> map = JSON.decode(json);
    _lastStop = map.containsKey("_lastStop")?map["_lastStop"]:_depthMMToMbar(3000);
    _stopSize = map.containsKey("_stopSize")?map["_stopSize"]:_rateMMToMbar(3000);
    _gfLo = map["_gfLo"];
    _gfHi = map["_gfHi"];
    if (map.containsKey("_descentSetpoint")) _descentSetpoint = map["_descentSetpoint"];
    if (map.containsKey("_bottomSetpoint")) _bottomSetpoint = map["_bottomSetpoint"];
    if (map.containsKey("_decoSetpoint")) _decoSetpoint = map["_decoSetpoint"];
    _ascentRate = map["_ascentRate"];
    _descentRate = map["_descentRate"];
    _lastDepth = map["_lastDepth"];
    _atmPressure = map["_atmPressure"];
    metric = map["_metric"];
    _surfaceInterval = map.containsKey("_surfaceInterval")?map["_surfaceInterval"]:0;
    _type = typeFromString(map["_type"]);
    if (_type == null) _type = DiveType.OC;
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
    _lastStop = map.containsKey("_lastStop")?map["_lastStop"]:_depthMMToMbar(3000);
    _stopSize = map.containsKey("_stopSize")?map["_stopSize"]:_rateMMToMbar(3000);
    _gfLo = map["_gfLo"];
    _gfHi = map["_gfHi"];
    if (map.containsKey("_descentSetpoint")) _descentSetpoint = map["_descentSetpoint"];
    if (map.containsKey("_bottomSetpoint")) _bottomSetpoint = map["_bottomSetpoint"];
    if (map.containsKey("_decoSetpoint")) _decoSetpoint = map["_decoSetpoint"];
    _ascentRate = map["_ascentRate"];
    _descentRate = map["_descentRate"];
    _lastDepth = map["_lastDepth"];
    _atmPressure = map["_atmPressure"];
    metric = map["_metric"];
    _surfaceInterval = map.containsKey("_surfaceInterval")?map["_surfaceInterval"]:0;
    _type = typeFromString(map["_type"]);
    if (_type == null) _type = DiveType.OC;
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
    m["_descentSetpoint"] = _descentSetpoint;
    m["_bottomSetpoint"] = _bottomSetpoint;
    m["_decoSetpoint"] = _decoSetpoint;
    m["_ascentRate"] = _ascentRate;
    m["_descentRate"] = _descentRate;
    m["_lastDepth"] = _lastDepth;
    m["_atmPressure"] = _atmPressure;
    m["_lastStop"] = _lastStop;
    m["_stopSize"] = _stopSize;
    m["_metric"] = _metric;
    m["_surfaceInterval"] = _surfaceInterval;
    m["_segments"] = _segments;
    m["_gasses"] = _gasses;
    m["_type"] = _type.toString();
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

  static Gas _findGasForSetpoint(Gas dil, double setpoint, double atm) {
    double o2percent = setpoint / atm;
    if (o2percent < dil.fO2) return dil;
    //double n2percent = (dil.fN2 / (dil.fN2 + dil.fHe)) * (1.0 - o2percent);
    double hePercent = (dil.fHe / (dil.fN2 + dil.fHe)) * (1.0 - o2percent);
    return new Gas.bottom(o2percent, hePercent, setpoint);
  }

  static Gas _findOCGas(List<Gas> gasses, int atmPressure, int depth, SegmentType type) {
    //return _findGasForSetpoint(gasses[0], 1.2, depth / 1000.0);
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

  Gas _findGas(List<Gas> gasses, int depth, SegmentType type, double setpoint) {
    if (_type == DiveType.CCR) return _findGasForSetpoint(_dil, setpoint, depth / 1000.0);
    return _findOCGas(gasses, _atmPressure, depth, type);
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
        _descend(_descentRate, tDepth, e.depth + atmDelta, false, e.setpoint);
        tDepth = e.depth + atmDelta;
      }
      if (e.type == SegmentType.UP) {
        _ascend(_ascentRate, tDepth, e.depth + atmDelta, false, e.setpoint);
        tDepth = e.depth + atmDelta;
      }
      if (e.type == SegmentType.LEVEL) {
        _bottom(e.depth + atmDelta, e.rawTime, e.setpoint);
        tDepth = e.depth + atmDelta;
      }
    }
    if (_segments.length > 1) {
      int fs = _firstStop(_gfLo);
      _gfSlope = (_gfHi - _gfLo) / -(fs - _atmPressure);
      _calcDecoInt(_nextGf(fs));
    }
  }

  /// Algorithm initially from paper:
  /// Oxygen Toxicity Calculations by Erik C. Baker, P.E.
  /// Link as of writing at: https://www.shearwater.com/wp-content/uploads/2012/08/Oxygen_Toxicity_Calculations.pdf
  /// Calculates otu and cns for a bottom segment.
  List<double> _bottomOtuCns(int depth, double time, Gas gas) {
    double po2 = gas.fO2 * (depth / 1000.0);
    double otu = po2<=.5? 0.0:time*pow((0.5/(po2 - 0.5)), ( - 5.0/6.0));
    double cns = 0.0;
    double tlim = 0.0;
    if (po2 > _cnsPPO2Lo[0]) {
      for (int x = 0; x < _cnsPPO2Segments; x++) {
        if (po2 > _cnsPPO2Lo[x] && po2 <= _cnsPPO2Hi[x])
          tlim = _cnsLimitSlope[x] * po2 + _cnsLimitIntercept[x];
      }
      cns = tlim>0.0?time/tlim:0.0;
    }
    //print("tlim: $tlim, time: $time, ppo2: ${gas.fO2}, depth: $depth, po2: $po2, otu: $otu, cns: $cns");
    return [otu, cns*100.0];
  }

  /// Algorithm initially from paper:
  /// Oxygen Toxicity Calculations by Erik C. Baker, P.E.
  /// Link as of writing at: https://www.shearwater.com/wp-content/uploads/2012/08/Oxygen_Toxicity_Calculations.pdf
  /// Calculates otu and cns for an ascent/descent segment.
  List<double> _descentOtuCns(int rateMbar, int fromDepth, int toDepth, Gas gas) {
    double time = (toDepth - fromDepth) / rateMbar;
    double maxata = max(toDepth, fromDepth) / 1000.0;
    double minata = min(toDepth, fromDepth) / 1000.0;
    double maxpo2 = gas.fO2 * maxata;
    double minpo2 = gas.fO2 * minata;
    double otu = 0.0;
    double cns = 0.0;
    if (maxpo2 > .5) {
      double lowpo2 = (minpo2 < .5)? .5:minpo2;
      time = time * (maxpo2 - lowpo2)/(maxpo2 - minpo2);
      otu = 3.0 / 11.0 * time / (maxpo2 - lowpo2) *
          pow(((maxpo2 - 0.5) / 0.5), (11.0 / 6.0)) -
          pow(((lowpo2 - 0.5) / 0.5), (11.0 / 6.0));
      List<double> otime = new List<double>(_cnsPPO2Segments);
      List<double> po2o = new List<double>(_cnsPPO2Segments);
      List<double> po2f = new List<double>(_cnsPPO2Segments);
      List<double> segpo2 = new List<double>(_cnsPPO2Segments);
      bool up = fromDepth > toDepth;
      for (int i = 0; i < _cnsPPO2Segments; i++) {
        if (maxpo2 > _cnsPPO2Lo[i] && lowpo2 <= _cnsPPO2Hi[i]) {
          if ((maxpo2 >= _cnsPPO2Hi[i]) && (lowpo2 < _cnsPPO2Lo[i])) {
            po2o[i] = up?_cnsPPO2Hi[i]:_cnsPPO2Lo[i];
            po2f[i] = !up?_cnsPPO2Hi[i]:_cnsPPO2Lo[i];
          } else if ((maxpo2 < _cnsPPO2Hi[i]) && (lowpo2 <= _cnsPPO2Lo[i])) {
            po2o[i] = up?maxpo2:_cnsPPO2Lo[i];
            po2f[i] = !up?maxpo2:_cnsPPO2Lo[i];
          } else if ((lowpo2 > _cnsPPO2Lo[i]) && (maxpo2 >= _cnsPPO2Hi[i])) {
            po2o[i] = up?_cnsPPO2Hi[i]:lowpo2;
            po2f[i] = !up?_cnsPPO2Hi[i]:lowpo2;
          } else {
            po2o[i] = up?maxpo2:lowpo2;
            po2f[i] = !up?maxpo2:lowpo2;
          }
          segpo2[i] = po2f[i] - po2o[i];
          otime[i] = time*(segpo2[i]/(maxpo2 - lowpo2)).abs();
          //print("XXXX from: $fromDepth, to: $toDepth, time: $time, otime: ${otime[i]}");
        } else {
          otime[i] = po2o[i] = po2f[i] = segpo2[i] = 0.0;
        }
      }
      for (int i = 0; i < _cnsPPO2Segments; i++) {
        if (otime[i] > 0.0) {
          double tlimi = _cnsLimitSlope[i] * po2o[i] + _cnsLimitIntercept[i];
          double mk = _cnsLimitSlope[i] * (segpo2[i] / otime[i]);
          cns += 1.0 / mk * (log((tlimi + mk * otime[i]).abs()) - log(tlimi.abs()));
        }
      }
    }

    return [otu, cns*100.0];
  }

  void _descend(int rateMbar, int fromDepth, int toDepth, bool calculated, double setpoint) {
    double t = (toDepth - fromDepth) / rateMbar;
    double bar = fromDepth / 1000.0;
    double brate = rateMbar / 1000.0; // rate of decent in bar
    Gas gas;
    if (rateMbar < 0 &&
        _segments.length > 0 &&
        _segments.last.type == SegmentType.UP) {
      gas = _segments.last.gas;
    } else {
      gas = _findGas(_gasses, rateMbar > 0 ? toDepth : fromDepth,
      //gas = _findGas(_gasses, _atmPressure, rateMbar > 0 ? toDepth : ((toDepth + fromDepth)/2).round(),
          rateMbar > 0 ? SegmentType.DOWN : SegmentType.UP, setpoint);
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

    List<double> otuCns = _descentOtuCns(rateMbar, fromDepth, toDepth, gas);

    if (rateMbar > 0) {
      _segments.add(new Segment(
          SegmentType.DOWN,
          toDepth,
          t,
          t.ceil(),
          gas,
          calculated,
          0, otuCns[0], otuCns[1], setpoint));
    } else {
      if (_segments.length > 0) {
        Segment lastSeg = _segments.removeLast();
        if (lastSeg.type == SegmentType.UP) {
          t += lastSeg.rawTime;
          otuCns[0] += lastSeg.otu;
          otuCns[1] += lastSeg.cns;
        } else {
          _segments.add(lastSeg);
        }
      }
      _segments.add(new Segment(
          SegmentType.UP, toDepth, t, t.round(), gas, calculated, 0, otuCns[0], otuCns[1], setpoint));
    }

  }

  void _ascend(int rateMbar, int fromDepth, int toDepth, bool calculated, setpoint) {
    _descend(-rateMbar, fromDepth, toDepth, calculated, setpoint);
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

  void _bottom(int depth, double time, setpoint) {
    Gas gas = _findGas(_gasses, depth, SegmentType.LEVEL, setpoint);
    _bottomInt(depth, time, gas);
    List<double> otuCns = _bottomOtuCns(depth, time, gas);
    _segments.add(new Segment(SegmentType.LEVEL, depth, time, time.ceil(), gas,
        false, _calcCeiling(_gfLo), otuCns[0], otuCns[1], setpoint));
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
    _ascend(_ascentRate, _lastDepth, fs, true, decoSetpoint);
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
      _ascend(_ascentRate, _lastDepth, fs, true, decoSetpoint);
      _lastDepth = fs;
    }
    if (fs <= _atmPressure) return; // At surface, done...
    double ngf = _nextGf(fs);
    int nfs = _nextStop(ngf);
    if (nfs == fs) {
      double t = 0.0;
      bool done = false;
      Gas gas = _findGas(_gasses, fs, SegmentType.UP, decoSetpoint);
      while (!done) {
        _bottomInt(fs, .3, gas);
        t += .3;
        nfs = _nextStop(ngf);
        if (nfs < fs) {
          done = true;
        }
      }
      List<double> otuCns = _bottomOtuCns(fs, t, gas);
      Segment lastSeg = _segments.removeLast();
      if (lastSeg.type != SegmentType.LEVEL) {
        if (lastSeg.rawTime < 1.0) {
          t += lastSeg.rawTime;
          otuCns[0] += lastSeg.otu;
          otuCns[1] += lastSeg.cns;
        } else {
          if (lastSeg.time > lastSeg.rawTime) {
            _bottomInt(
                lastSeg.depth, lastSeg.time - lastSeg.rawTime, lastSeg.gas);
            List<double> otuCns2 = _bottomOtuCns(lastSeg.depth, lastSeg.time - lastSeg.rawTime, lastSeg.gas);
            lastSeg = new Segment(lastSeg.type, lastSeg.depth, lastSeg.rawTime,
                lastSeg.time, lastSeg.gas, lastSeg.isCalculated, lastSeg.ceiling,
                lastSeg.otu + otuCns2[0], lastSeg.cns + otuCns2[1], lastSeg.setpoint);
          } else {
            List<double> otuCns2 = _bottomOtuCns(fs, lastSeg.rawTime - lastSeg.time, lastSeg.gas);
            otuCns[0] += otuCns2[0];
            otuCns[1] += otuCns2[1];
            t += lastSeg.rawTime - lastSeg.time;
          }
          _segments.add(lastSeg);
        }
      }
      _bottomInt(fs, t.ceil() - t, gas);
      _segments
          .add(new Segment(SegmentType.LEVEL, fs, t, t.ceil(), gas, true, 0, otuCns[0], otuCns[1], decoSetpoint));
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
    _type = DiveType.OC;
    _descentSetpoint = 1.0;
    _bottomSetpoint = 1.0;
    _decoSetpoint = 1.3;
    _ascentRate = 1000; // mbar/min
    _descentRate = 1800; // mbar/min
    _lastDepth = 0;
    _atmPressure = 1013;
    _lastStop = _depthMMToMbar(_metric?3000:3048);
    _stopSize = _rateMMToMbar(_metric?3000:3048);
    _gasses.clear();
    _dil = Gas.air;
    _segments.clear();
    _clearInitial = true;
    _reset();
  }

  int get gfLo => (_gfLo * 100).round();
  int get gfHi => (_gfHi * 100).round();
  set gfLo(int gf) => _gfLo = gf / 100.0;
  set gfHi(int gf) => _gfHi = gf / 100.0;

  setOC() => _type = DiveType.OC;
  setCCR() => _type = DiveType.CCR;
  bool isOC() => _type == DiveType.OC;
  bool isCCR() => _type == DiveType.CCR;

  double get descentSetpoint => _descentSetpoint;
  set descentSetpoint(double setpoint) => _descentSetpoint = setpoint;
  double get bottomSetpoint => _bottomSetpoint;
  set bottomSetpoint(double setpoint) => _bottomSetpoint = setpoint;
  double get decoSetpoint => _decoSetpoint;
  set decoSetpoint(double setpoint) => _decoSetpoint = setpoint;

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

  void descend(int fromDepth, int toDepth, double setpoint) {
    _descend(
        _descentRate, depthToMbar(fromDepth), depthToMbar(toDepth), false, setpoint);
  }

  void ascend(int fromDepth, int toDepth, double setpoint) {
    _ascend(
        _ascentRate, depthToMbar(fromDepth), depthToMbar(toDepth), false, setpoint);
  }

  void addBottom(int depth, int time, double setpoint) {
    _bottom(depthToMbar(depth), time.toDouble(), setpoint);
  }

  void move(int from, int to, int time, double setpoint) {
    if (from < to)
      descend(from, to, setpoint);
    else
      ascend(from, to, setpoint);
    int t = time - segments.last.time;
    addBottom(to, t > 0 ? t : 0, setpoint);
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
    _dil = _gasses[0];
  }

  void removeGas(Gas gas) {
    _gasses?.remove(gas);
    if (_gasses.length == 0) {
      _dil = Gas.air;
    } else {
      _dil = _gasses[0];
    }
  }

  void addAllGasses(List<Gas> g) {
    _gasses?.addAll(g);
    _dil = _gasses[0];
  }
}

