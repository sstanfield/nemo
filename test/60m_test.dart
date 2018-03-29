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
    print("len: ${segs.length}");
    expect(segs.length, 12);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(SegmentType.DOWN, 7013, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 7013, 0.0, 26, Gas.air, false, 0, 0.0, 0.0, 1.2));

    // This segment is 4 instead if 3 on the Shearwater, all other segments are the same.
    // Probably a rounding issue, 33 meters ascent at 10 m/min...
    expectedSegs.add(new Segment(SegmentType.UP, 3713, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3713, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3413, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3113, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2813, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2513, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2213, 0.0, 5, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1913, 0.0, 8, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1613, 0.0, 10, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1313, 0.0, 19, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
    for (var s in segs) {
      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time}");
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
    print("len: ${segs.length}");
    expect(segs.length, 13);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(SegmentType.DOWN, 7013, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 7013, 0.0, 32, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.UP, 4013, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 4013, 0.0, 1, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3713, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3413, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 3113, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2813, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2513, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 2213, 0.0, 7, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1913, 0.0, 10, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1613, 0.0, 13, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(SegmentType.LEVEL, 1313, 0.0, 23, Gas.air, false, 0, 0.0, 0.0, 1.2));
    int i = 0;
    for (var s in segs) {
      print("${s.type} ${s.depth} ${dive.mbarToDepth(s.depth)} ${s.time}");
      expect(s.type, expectedSegs[i].type);
      expect(s.depth, expectedSegs[i].depth);
      expect(s.time, expectedSegs[i].time);
      i++;
    }
  });
}