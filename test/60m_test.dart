import 'package:test/test.dart';
import '../lib/deco/plan.dart';
import '../lib/deco/dive.dart';
import '../lib/deco/gas.dart';
import '../lib/deco/segment.dart';
import '../lib/deco/segment_type.dart';

void main() {
  test('60 meter for 30 test', () {
    // This plan is one minute off from Shearwater, it has a 4 minute ascent to 3713 instead of 3.
    Plan plan = new Plan();
    Dive dive = plan.dives[0];
    dive.addGas(new Gas.bottom(.18, .45, 1.3));
    dive.addGas(new Gas.deco(.5, 0.0));
    dive.addGas(new Gas.deco(.99, 0.0));
    dive.ascentRate = 10;
    dive.descentRate = 18;
    dive.move(0, 60, 30, 1.2);
    dive.calcDeco();
    List<Segment> segs = dive.segments;
    expect(segs.length, 12);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(
        SegmentType.DOWN, 7013, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 7013, 0.0, 26, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // This segment is 4 instead if 3 on the Shearwater, all other segments are the same.
    // Probably a rounding issue, 33 meters ascent at 10 m/min...
    expectedSegs.add(new Segment(
        SegmentType.UP, 3713, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3713, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3413, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3113, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2813, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2513, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2213, 0.0, 5, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1913, 0.0, 8, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater is 11
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1613, 0.0, 10, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1313, 0.0, 19, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
//    int runtime = 0;
    for (var s in segs) {
//      runtime += s.time;
//      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time} $runtime");
      expect(s.type, expectedSegs[i].type);
      expect(s.depth, expectedSegs[i].depth);
      expect(s.time, expectedSegs[i].time);
      i++;
    }
  });

  test('60 meter for 36 test', () {
    // This plan matches Shearwater
    Plan plan = new Plan();
    Dive dive = plan.dives[0];
    dive.addGas(new Gas.bottom(.18, .45, 1.3));
    dive.addGas(new Gas.deco(.5, 0.0));
    dive.addGas(new Gas.deco(.99, 0.0));
    dive.ascentRate = 10;
    dive.descentRate = 18;
    dive.move(0, 60, 36, 1.2);
    dive.calcDeco();
    List<Segment> segs = dive.segments;
    expect(segs.length, 13);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(
        SegmentType.DOWN, 7013, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 7013, 0.0, 32, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.UP, 4013, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4013, 0.0, 1, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3713, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3413, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3113, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2813, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2513, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2213, 0.0, 7, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 11
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1913, 0.0, 10, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 12
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1613, 0.0, 13, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 25
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1313, 0.0, 23, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
//    int runtime = 0;
    for (var s in segs) {
//      runtime += s.time;
//      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time} $runtime");
      expect(s.type, expectedSegs[i].type);
      expect(s.depth, expectedSegs[i].depth);
      expect(s.time, expectedSegs[i].time);
      i++;
    }
  });

  test('60 meter for 60 test', () {
    // This plan matches Shearwater
    Plan plan = new Plan();
    Dive dive = plan.dives[0];
    dive.addGas(new Gas.bottom(.18, .45, 1.3));
    dive.addGas(new Gas.deco(.5, 0.0));
    dive.addGas(new Gas.deco(.99, 0.0));
    dive.atmPressure = 1001;
    dive.ascentRate = 10;
    dive.descentRate = 18;
    dive.gfLo = 50;
    dive.gfHi = 80;
    dive.move(0, 60, 60, 1.2);
    dive.calcDeco();
    List<Segment> segs = dive.segments;
    expect(segs.length, 14);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(
        SegmentType.DOWN, 7001, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 7001, 0.0, 56, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.UP, 4301, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4301, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4001, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3701, 0.0, 6, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 8min
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3401, 0.0, 7, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3101, 0.0, 5, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2801, 0.0, 6, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2501, 0.0, 9, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 12min
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2201, 0.0, 13, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 20min
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1901, 0.0, 19, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1601, 0.0, 24, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // Shearwater 46min
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1301, 0.0, 45, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
//    int runtime = 0;
//    double cns = 0.0;
//    double otu = 0.0;
    for (var s in segs) {
//      runtime += s.time;
//      cns += s.cns;
//      otu += s.otu;
//      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time} $runtime");
      expect(s.type, expectedSegs[i].type);
      expect(s.depth, expectedSegs[i].depth);
      expect(s.time, expectedSegs[i].time);
      i++;
    }
//    print("otu: $otu, cns: $cns");
  });

  test('200 feet for 60 test', () {
    // This plan matches Shearwater
    Plan plan = new Plan();
    Dive dive = plan.dives[0];
    dive.addGas(new Gas.bottom(.18, .45, 1.3));
    dive.addGas(new Gas.deco(.5, 0.0));
    dive.addGas(new Gas.deco(.99, 0.0));
    dive.metric = false;
    dive.ascentRate = 33;
    dive.descentRate = 60;
    dive.gfLo = 50;
    dive.gfHi = 80;
    dive.move(0, 200, 60, 1.2);
    dive.calcDeco();
    List<Segment> segs = dive.segments;
    expect(segs.length, 14);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(
        SegmentType.DOWN, 7109, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 7109, 0.0, 56, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.UP, 4368, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4368, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4063, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3758, 0.0, 6, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3453, 0.0, 7, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3148, 0.0, 5, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2843, 0.0, 6, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2538, 0.0, 9, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2233, 0.0, 13, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1928, 0.0, 20, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1623, 0.0, 24, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1318, 0.0, 46, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
//    int runtime = 0;
    for (var s in segs) {
//      runtime += s.time;
//      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time} $runtime");
      expect(s.type, expectedSegs[i].type);
      expect(s.depth, expectedSegs[i].depth);
      expect(s.time, expectedSegs[i].time);
      i++;
    }
  });
}
