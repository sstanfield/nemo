import 'package:test/test.dart';
import '../lib/deco/plan.dart';
import '../lib/deco/dive.dart';
import '../lib/deco/gas.dart';
import '../lib/deco/segment.dart';
import '../lib/deco/segment_type.dart';

void main() {
  test('75 meter for 30 test', () {
    Plan plan = new Plan();
    Dive dive = plan.dives[0];
    dive.addGas(new Gas.bottom(.15, .55, 1.3));
    dive.addGas(new Gas.deco(.35, .25));
    dive.addGas(new Gas.deco(.5, 0.0));
    dive.addGas(new Gas.deco(.99, 0.0));
    dive.ascentRate = 10;
    dive.descentRate = 18;
    dive.move(0, 75, 30, 1.2);
    dive.calcDeco();
    List<Segment> segs = dive.segments;
    expect(segs.length, 16);
    List<Segment> expectedSegs = new List<Segment>();
    expectedSegs.add(new Segment(
        SegmentType.DOWN, 8513, 0.0, 5, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 8513, 0.0, 25, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.UP, 4913, 0.0, 4, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4913, 0.0, 1, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4613, 0.0, 1, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4313, 0.0, 1, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 4013, 0.0, 2, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3713, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3413, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 3113, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2813, 0.0, 3, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2513, 0.0, 6, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 2213, 0.0, 8, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1913, 0.0, 11, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1613, 0.0, 15, Gas.air, false, 0, 0.0, 0.0, 1.2));
    expectedSegs.add(new Segment(
        SegmentType.LEVEL, 1313, 0.0, 28, Gas.air, false, 0, 0.0, 0.0, 1.2));
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
