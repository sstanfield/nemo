import 'dart:math';
import 'gas.dart';

/*
 ** Encapsulates OTU and CNS calculations.
 */
class OtuCns {
  static final int _cnsPPO2Segments = 7;
  static final List<double> _cnsPPO2Lo = [.5, .6, .7, .8, .9, 1.1, 1.5];
  static final List<double> _cnsPPO2Hi = [.6, .7, .8, .9, 1.1, 1.5, 100.0];
  static final List<double> _cnsLimitSlope = [
    -1800.0,
    -1500.0,
    -1200.0,
    -900.0,
    -600.0,
    -300.0,
    -750.0
  ];
  static final List<double> _cnsLimitIntercept = [
    1800.0,
    1620.0,
    1410.0,
    1170.0,
    900.0,
    570.0,
    1245.0
  ];

  /// Algorithm initially from paper:
  /// Oxygen Toxicity Calculations by Erik C. Baker, P.E.
  /// Link as of writing at: https://www.shearwater.com/wp-content/uploads/2012/08/Oxygen_Toxicity_Calculations.pdf
  /// Calculates otu and cns for a bottom segment.
  static List<double> bottom(int depth, double time, Gas gas) {
    double po2 = gas.fO2 * (depth / 1000.0);
    double otu =
        po2 <= .5 ? 0.0 : time * pow((0.5 / (po2 - 0.5)), (-5.0 / 6.0));
    double cns = 0.0;
    double tlim = 0.0;
    if (po2 > _cnsPPO2Lo[0]) {
      for (int x = 0; x < _cnsPPO2Segments; x++) {
        if (po2 > _cnsPPO2Lo[x] && po2 <= _cnsPPO2Hi[x])
          tlim = _cnsLimitSlope[x] * po2 + _cnsLimitIntercept[x];
      }
      cns = tlim > 0.0 ? time / tlim : 0.0;
    }
    //print("tlim: $tlim, time: $time, ppo2: ${gas.fO2}, depth: $depth, po2: $po2, otu: $otu, cns: $cns");
    return [otu, cns * 100.0];
  }

  /// Algorithm initially from paper:
  /// Oxygen Toxicity Calculations by Erik C. Baker, P.E.
  /// Link as of writing at: https://www.shearwater.com/wp-content/uploads/2012/08/Oxygen_Toxicity_Calculations.pdf
  /// Calculates otu and cns for an ascent/descent segment.
  static List<double> descent(
      int rateMbar, int fromDepth, int toDepth, Gas gas) {
    double time = (toDepth - fromDepth) / rateMbar;
    double maxata = max(toDepth, fromDepth) / 1000.0;
    double minata = min(toDepth, fromDepth) / 1000.0;
    double maxpo2 = gas.fO2 * maxata;
    double minpo2 = gas.fO2 * minata;
    double otu = 0.0;
    double cns = 0.0;
    if (maxpo2 > .5) {
      double lowpo2 = (minpo2 < .5) ? .5 : minpo2;
      time = time * (maxpo2 - lowpo2) / (maxpo2 - minpo2);
      otu = 3.0 /
              11.0 *
              time /
              (maxpo2 - lowpo2) *
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
            po2o[i] = up ? _cnsPPO2Hi[i] : _cnsPPO2Lo[i];
            po2f[i] = !up ? _cnsPPO2Hi[i] : _cnsPPO2Lo[i];
          } else if ((maxpo2 < _cnsPPO2Hi[i]) && (lowpo2 <= _cnsPPO2Lo[i])) {
            po2o[i] = up ? maxpo2 : _cnsPPO2Lo[i];
            po2f[i] = !up ? maxpo2 : _cnsPPO2Lo[i];
          } else if ((lowpo2 > _cnsPPO2Lo[i]) && (maxpo2 >= _cnsPPO2Hi[i])) {
            po2o[i] = up ? _cnsPPO2Hi[i] : lowpo2;
            po2f[i] = !up ? _cnsPPO2Hi[i] : lowpo2;
          } else {
            po2o[i] = up ? maxpo2 : lowpo2;
            po2f[i] = !up ? maxpo2 : lowpo2;
          }
          segpo2[i] = po2f[i] - po2o[i];
          otime[i] = time * (segpo2[i] / (maxpo2 - lowpo2)).abs();
          //print("XXXX from: $fromDepth, to: $toDepth, time: $time, otime: ${otime[i]}");
        } else {
          otime[i] = po2o[i] = po2f[i] = segpo2[i] = 0.0;
        }
      }
      for (int i = 0; i < _cnsPPO2Segments; i++) {
        if (otime[i] > 0.0) {
          double tlimi = _cnsLimitSlope[i] * po2o[i] + _cnsLimitIntercept[i];
          double mk = _cnsLimitSlope[i] * (segpo2[i] / otime[i]);
          cns += 1.0 /
              mk *
              (log((tlimi + mk * otime[i]).abs()) - log(tlimi.abs()));
        }
      }
    }

    return [otu, cns * 100.0];
  }
}
