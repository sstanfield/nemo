import 'dart:math';
//import 'dart:io';


final List<double> n2AsA = const [1.2599, 1.0000, 0.8618, 0.7562, 0.6667, 0.5933, 0.5282, 0.4701, 0.4187, 0.3798, 0.3497, 0.3223, 0.2971, 0.2737, 0.2523, 0.2327];
final List<double> n2AsB = const [1.2599, 1.0000, 0.8618, 0.7562, 0.6667, 0.5600, 0.4947, 0.4500, 0.4187, 0.3798, 0.3497, 0.3223, 0.2850, 0.2737, 0.2523, 0.2327];
final List<double> n2AsC = const [1.2599, 1.0000, 0.8618, 0.7562, 0.6200, 0.5043, 0.4410, 0.4000, 0.3750, 0.3500, 0.3295, 0.3065, 0.2835, 0.2610, 0.2480, 0.2327];

enum SegmentType {
	UP,
	DOWN,
	LEVEL
}

class Gas {
  final double fO2;
	final double fN2;
	final double fHe;
	final double ppo2;
	final int minDepth;
	final int maxDepth;
	final bool useAssent;
	final bool useDecent;

	Gas(this.fO2, this.fHe, this.ppo2, double minPPO2, this.useAssent, this.useDecent):
		fN2 = 1.0 - (fO2 + fHe), minDepth = (fO2>=.18?0:(((minPPO2/fO2)-1)*10).ceil()), maxDepth = (((ppo2/fO2)-1)*10).floor();
	Gas.deco(double fO2, double fHe): this(fO2, fHe, 1.6, .21, true, false);
	Gas.bottom(double fO2, double fHe, double ppo2): this(fO2, fHe, ppo2, .18, true, true);

	bool use(int depth, SegmentType type) {
		if (depth >= minDepth && depth <= maxDepth) {
			if (type == SegmentType.DOWN && useDecent) return true;
			if (type == SegmentType.UP && useAssent) return true;
			if (type == SegmentType.LEVEL) return true;
		}
		return false;
	}

	String toString() {
		if (fHe > 0) return "${(fO2*100.0).round()}/${(fHe*100.0).round()}";
		return "${(fO2*100.0).round()}%";
	}

	bool operator ==(o) => o is Gas && o.fO2 == fO2 && o.fHe == fHe;
	int get hashCode => (fO2*1000 + fHe*1000).ceil();
}


class Segment {
	final SegmentType type;
	final int depth;
	final double rawTime;
	final int time;
	final Gas gas;
	final bool calculated;

	Segment(this.type, this.depth, this.rawTime, this.time, this.gas, this.calculated);
}

class Dive {
	List<double> _tN;
	List<double> _tH;
	double gfLo;
	double gfHi;
	/*set gfLo(double gf) => _gfLo = gf;
	set gfHi(double gf) => _gfHi = gf;
	get gfLo => _gfLo;
	get gfHi => _gfHi;*/
	double _gfSlope; // null
	double assentRate = 1.0;
	//double assentRate = 0.9;
	double descentRate = 1.8;
	int _lastDepth = 0;
	set assentMeters(num rate) => assentRate = rate / 10.0;
	set decentMeters(num rate) => descentRate = rate / 10.0;
	var lastStop = 3;
	final int compartments = 16;
	final double atmPressure = 1.013;
	final double partialWater = .0567;
	final List<double> halfTimesN2 = const [4.00, 8.00, 12.50, 18.50, 27.00, 38.30, 54.30, 77.00, 109.00, 146.00, 187.00, 239.00, 305.00, 390.00, 498.00, 635.00]; // 1b 5.0
	final List<double> halfTimesHe = const [1.51, 3.02,  4.72,  6.99, 10.21, 14.48, 20.53, 29.11,  41.20,  55.19,  70.69,  90.34, 115.29, 147.42, 188.24, 240.03]; // 1b 1.88
	final List<double> heAs = const [1.7424, 1.3830, 1.1919, 1.0458, 0.9220, 0.8205, 0.7305, 0.6502, 0.5950, 0.5545, 0.5333, 0.5189, 0.5181, 0.5176, 0.5172, 0.5119];
	final List<double> heBs = const [0.4245, 0.5747, 0.6527, 0.7223, 0.7582, 0.7957, 0.8279, 0.8553, 0.8757, 0.8903, 0.8997, 0.9073, 0.9122, 0.9171, 0.9217, 0.9267];
	final List<double> n2As;
	final List<double> n2Bs = const [0.5050, 0.6514, 0.7222, 0.7825, 0.8126, 0.8434, 0.8693, 0.8910, 0.9092, 0.9222, 0.9319, 0.9403, 0.9477, 0.9544, 0.9602, 0.9653];

	final List<Gas> gasses;
	List<Segment> segments = new List<Segment>();

	Gas _findGas(int depth, SegmentType type) {
		if (gasses == null) return new Gas.bottom(.21, .0, 1.2);
		Gas ret;
		gasses.forEach ((Gas g) {
			if (g.use(depth, type) && (ret == null || g.fO2 > ret.fO2)) ret = g;
		});
		if (ret == null) { // Failed to find a good fit, find something...
			gasses.forEach ((Gas g) {
				if (ret == null || g.fO2*depth < ret.fO2*depth) ret = g;
			});
		}
		// Seem to have no gasses... Return good old air.
		if (ret == null) ret = new Gas.bottom(.21, .0, 1.2);
		return ret;
	}

	double _nextGf(int stop) {
		if (stop < 3 || _gfSlope == null) return gfHi;
		return (_gfSlope * (stop - 3)) + gfHi;
	}

	void reset() {
		double n2Partial = 0.79 * (atmPressure - partialWater);
		for (num i = 0; i < compartments; i++) {
			_tN[i] = n2Partial;
			_tH[i] = 0.0;
		}
		segments.removeWhere((Segment s) => s.calculated);
		_gfSlope = null;
		List<Segment> s = segments;
		segments = new List<Segment>();
		int tDepth = 0;
		for (final Segment e in s) {
			if (e.type == SegmentType.DOWN) {
				descend(descentRate, tDepth, e.depth);
				tDepth = e.depth;
			}
			if (e.type == SegmentType.UP) {
				ascend(assentRate, tDepth, e.depth);
				tDepth = e.depth;
			}
			if (e.type == SegmentType.LEVEL) {
				bottom(e.depth, e.rawTime);
				tDepth = e.depth;
			}
		}
	}

	void clearSegments() {
		segments.clear();
	}

	Dive(this.gfLo, this.gfHi, this.gasses): n2As = n2AsC
	{
		_tN = new List<double>(compartments);
		_tH = new List<double>(compartments);
	  reset();
	}

	void descend(double rateBar, num fromDepth, num toDepth)
	{
		double t = ((toDepth - fromDepth) / 10.0) / rateBar;
		//var bar = 1.0 + (fromDepth / 10.0);
		double bar = atmPressure + (fromDepth / 10.0);
		double brate = rateBar;  // rate of decent in bar
		Gas gas = _findGas(rateBar>0?toDepth:fromDepth, rateBar>0?SegmentType.DOWN:SegmentType.UP);
		for (int i = 0; i < compartments; i++) {
			double po = _tN[i];
			double pio = (bar - partialWater) * gas.fN2;
			double R = brate * gas.fN2;
			double k = log(2) / halfTimesN2[i];
			_tN[i] = pio + R * (t - (1/k)) - (pio - po - (R / k)) * exp(-k * t);

			po = _tH[i];
			pio = (bar - partialWater) * gas.fHe;
			R = brate * gas.fHe;
			k = log(2) / halfTimesHe[i];
			_tH[i] = pio + R * (t - (1/k)) - (pio - po - (R / k)) * exp(-k * t);
		}
		if (rateBar > 0) segments.add(new Segment(SegmentType.DOWN, toDepth, t, t.ceil(), gas, false));
		if (rateBar < 0) {
		  if (segments.length > 0) {
				Segment lastSeg = segments.removeLast();
				if (lastSeg.type == SegmentType.UP)
					t += lastSeg.rawTime;
				else
					segments.add(lastSeg);
			}
			segments.add(new Segment(SegmentType.UP, toDepth, t, t.ceil(), gas, true));
		}
	}
	void ascend(double rateBar, num fromDepth, num toDepth)
	{
		descend(-rateBar, fromDepth, toDepth);
	}

	void _bottom(int depth, double time, Gas gas)
	{
	  if (time <= 0) return;
		double bar = 1.0 + (depth / 10.0);
		for (num i = 0; i < compartments; i++) {
			double po = _tN[i];
			double pio = (bar - partialWater) * gas.fN2;
			_tN[i] = po + (pio - po) * (1 - pow(2, -time / halfTimesN2[i]));

			po = _tH[i];
			pio = (bar - partialWater) * gas.fHe;
			_tH[i] = po + (pio - po) * (1 - pow(2, -time / halfTimesHe[i]));
		}
		_lastDepth = depth;
	}

	void bottom(int depth, double time)
	{
		Gas gas = _findGas(depth, SegmentType.LEVEL);
		_bottom(depth, time, gas);
		segments.add(new Segment(SegmentType.LEVEL, depth, time, time.ceil(), gas, false));
	}

	int nextStop(double gf) // Depth (in meters) of first stop.
	{
		double ceiling = 0.0;
		for (int i = 0; i < compartments; i++) {
			double a = ((n2As[i] * _tN[i]) + (heAs[i] * _tH[i])) / (_tN[i] + _tH[i]);
			double b = ((n2Bs[i] * _tN[i]) + (heBs[i] * _tH[i])) / (_tN[i] + _tH[i]);
			double ceil = ((_tN[i] + _tH[i]) - (gf * a)) / ((gf/b) - gf + 1);
			if (ceil > ceiling) ceiling = ceil;
		}
		if (ceiling < 1.0) return 0;
		double stop = (ceiling - 1.0) * 10.0;
		if (stop <= lastStop) return lastStop;
		bool done = false;
		int ret = 0;
		for (int i = lastStop+3; !done; i+=3) {
			if (stop < i) {
				ret = i;
				done = true;
			}
		}
		return ret;
	}

	int firstStop(double gf) // Depth (in meters) of first stop.
	{
		int fs = nextStop(gf);
		ascend(assentRate, _lastDepth, fs);
		_lastDepth = fs;

		// Comment next two line out to start gf slope at natural first stop even
		// if it has cleared in the ascent to it- leaving them in seems to match
		// Shearwater closer and not Subsurface...
		int nfs = nextStop(gf);
		if (nfs < fs) return firstStop(gf);

		return fs;
	}

	void _calcDecoInt(num gf)
	{
		int fs = nextStop(gf);
		if (fs < _lastDepth) {
			ascend(assentRate, _lastDepth, fs);
			_lastDepth = fs;
		}
		double ngf = _nextGf(fs);
		int nfs = nextStop(ngf);
		if (nfs == fs) {
			double t = 0.0;
			bool done = false;
			Gas gas = _findGas(fs, SegmentType.UP);
			while (!done) {
				_bottom(fs, .1, gas);
				t += .1;
				nfs = nextStop(ngf);
				if (nfs < fs) {
					done = true;
				}
			}
			Segment lastSeg = segments.removeLast();
			if (lastSeg.type != SegmentType.LEVEL && lastSeg.rawTime < 1.0) t += lastSeg.rawTime;
			else {
				_bottom(lastSeg.depth, lastSeg.time.ceil()-lastSeg.rawTime, gas);
				segments.add(lastSeg);
			}
			_bottom(fs, t.ceil()-t, gas);
			segments.add(new Segment(SegmentType.LEVEL, fs, t, t.ceil(), gas, true));
		}
		if (nfs != 0) _calcDecoInt(ngf);
	}
	void calcDeco()
	{
	  reset();
		int fs = firstStop(gfLo);
		_gfSlope = (gfHi - gfLo) / -fs;
		_calcDecoInt(_nextGf(fs));
	}

/*	void printDive()
	{
		double runtime = 0.0;
		for (final e in segments) {
			runtime += e.time;
			if (e.type == SegmentType.DOWN) stdout.write("| ");
			if (e.type == SegmentType.UP) stdout.write("^ ");
			if (e.type == SegmentType.LEVEL) stdout.write("- ");
			print("${e.depth} : ${e.time.toStringAsFixed(2)} : ${runtime.toStringAsFixed(2)}      ${((1.0-(e.gas.fN2+e.gas.fHe))*100).round()}/${(e.gas.fHe*100).round()}");
		}
		//segments.forEach(f(e) => print("$e.depth : $e.time"));
	}*/
}
