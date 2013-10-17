package com.flmml {
	/**
	 * This class was created based on "Paul Kellett" that programmed by Paul Kellett
	   and "Moog VCF, variation 1" that programmed by paul.kellett@maxim.abel.co.uk
	   See following URL; http://www.musicdsp.org/showArchiveComment.php?ArchiveID=29
						  http://www.musicdsp.org/showArchiveComment.php?ArchiveID=25
	   Thanks to their great works!
	*/
	import __AS3__.vec.Vector;

	public class MFilter {
		private var m_t1:Number;
		private var m_t2:Number;
		private var m_b0:Number;
		private var m_b1:Number;
		private var m_b2:Number;
		private var m_b3:Number;
		private var m_b4:Number;
		private var sw:Number;

		public function MFilter() {
			setSwitch(0);
		}
		public function reset():void {
			m_t1 = m_t2 = m_b0 = m_b1 = m_b2 = m_b3 = m_b4 = 0.0;
		}
		public function setSwitch(s:int):void {
			reset();
			sw = s;
		}
		public function checkToSilence():Boolean {
			switch(sw){
				case 0:
					return false;
				case 1:
				case -1:
					return (-0.000001 <= m_b0 && m_b0 <= 0.000001 && -0.000001 <= m_b1 && m_b1 <= 0.000001);
				case 2:
				case -2:
					return (
						-0.000001 <= m_t1 && m_t1 <= 0.000001 &&
						-0.000001 <= m_t2 && m_t2 <= 0.000001 &&
						-0.000001 <= m_b0 && m_b0 <= 0.000001 &&
						-0.000001 <= m_b1 && m_b1 <= 0.000001 &&
						-0.000001 <= m_b2 && m_b2 <= 0.000001 &&
						-0.000001 <= m_b3 && m_b3 <= 0.000001 &&
						-0.000001 <= m_b4 && m_b4 <= 0.000001
					); 
			}
			return false;
		}
		public function run(samples:Vector.<Number>, start:int, end:int, envelope:MEnvelope, frq:Number, amt:Number, res:Number, key:Number):void {
			switch(sw) {
			case -2: hpf2(samples, start, end, envelope, frq, amt, res, key); break;
			case -1: hpf1(samples, start, end, envelope, frq, amt, res, key); break;
			case 0: return;
			case 1: lpf1(samples, start, end, envelope, frq, amt, res, key); break;
			case 2: lpf2(samples, start, end, envelope, frq, amt, res, key); break;
			}
		}

		public function lpf1(samples:Vector.<Number>, start:int, end:int, envelope:MEnvelope, frq:Number, amt:Number, res:Number, key:Number):void {
			var b0:Number = m_b0, b1:Number = m_b1;
			var i:int;
			var fb:Number;
			var cut:Number;
			//var k:Number = key * (2.0 * Math.PI / (MSequencer.RATE44100 * 440.0));
			if (amt > 0.0001 || amt < -0.0001) {
				for(i = start; i < end; i++) {
					//cut = MChannel.getFrequency(frq + amt * envelope.getNextAmplitudeLinear()) * k;
					cut = frq + (amt * (Math.pow(1000.0, envelope.getNextAmplitudeLinear()) / 1000.0));
					if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
					if (cut > (1.0-0.0001))   cut = 1.0-0.0001;
					fb = res + res / (1.0 - cut);
					// for each sample...
					b0 = b0 + cut * (samples[i] - b0 + fb * (b0 - b1));
					samples[i] = b1 = b1 + cut * (b0 - b1);
				}
			}
			else {
				//cut = MChannel.getFrequency(frq) * k;
				cut = frq;
				if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
				if (cut > (1.0-0.0001)) cut = 1.0-0.0001;
				fb = res + res / (1.0 - cut);
				for(i = start; i < end; i++) {
					// for each sample...
					b0 = b0 + cut * (samples[i] - b0 + fb * (b0 - b1));
					samples[i] = b1 = b1 + cut * (b0 - b1);
				}
			}
			m_b0 = b0;
			m_b1 = b1;
		}
		public function lpf2(samples:Vector.<Number>, start:int, end:int, envelope:MEnvelope, frq:Number, amt:Number, res:Number, key:Number):void {
			var t1:Number = m_t1, t2:Number = m_t2, b0:Number = m_b0, b1:Number = m_b1, b2:Number = m_b2, b3:Number = m_b3, b4:Number = m_b4;
			//var k:Number = key * (2.0 * Math.PI / (MSequencer.RATE44100 * 440.0));
			for(var i:int = start; i < end; i++) {
				//var cut:Number = MChannel.getFrequency(frq + amt * envelope.getNextAmplitudeLinear()) * k;
				var cut:Number = frq + (amt * (Math.pow(1000.0, envelope.getNextAmplitudeLinear()) / 1000.0));
				if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
				if (cut > 1.0) cut = 1.0;
				// Set coefficients given frequency & resonance [0.0...1.0]
				var q:Number = 1.0 - cut;
				var p:Number = cut + 0.8 * cut * q;
				var f:Number = p + p - 1.0;
				q = res * (1.0 + 0.5 * q * (1.0 - q + 5.6 * q * q));
				// Filter (input [-1.0...+1.0])
				var input:Number = samples[i];
				input -= q * b4;                      //feedback
				t1 = b1;  b1 = (input + b0) * p - b1 * f;
				t2 = b2;  b2 = (b1 + t1) * p - b2 * f;
				t1 = b3;  b3 = (b2 + t2) * p - b3 * f;
				b4 = (b3 + t1) * p - b4 * f;
				b4 = b4 - b4 * b4 * b4 * 0.166667;    //clipping
				b0 = input;
				samples[i] = b4;
			}
			m_t1 = t1;
			m_t2 = t2;
			m_b0 = b0;
			m_b1 = b1;
			m_b2 = b2;
			m_b3 = b3;
			m_b4 = b4;
		}
		public function hpf1(samples:Vector.<Number>, start:int, end:int, envelope:MEnvelope, frq:Number, amt:Number, res:Number, key:Number):void {
			var b0:Number = m_b0, b1:Number = m_b1;
			var i:int;
			var fb:Number;
			var cut:Number;
			//var k:Number = key * (2.0 * Math.PI / (MSequencer.RATE44100 * 440.0));
			var input:Number;
			if (amt > 0.0001 || amt < -0.0001) {
				for(i = start; i < end; i++) {
					//cut = MChannel.getFrequency(frq + amt * envelope.getNextAmplitudeLinear()) * k;
					cut = frq + (amt * (Math.pow(1000.0, envelope.getNextAmplitudeLinear()) / 1000.0));
					if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
					if (cut > (1.0-0.0001))   cut = 1.0-0.0001;
					fb = res + res / (1.0 - cut);
					// for each sample...
					input = samples[i];
					b0 = b0 + cut * (input - b0 + fb * (b0 - b1));
					b1 = b1 + cut * (b0 - b1);
					samples[i] = input - b0;
				}
			}
			else {
				//cut = MChannel.getFrequency(frq) * k;
				cut = frq;
				if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
				if (cut > (1.0-0.0001))   cut = 1.0-0.0001;
				fb = res + res / (1.0 - cut);
				for(i = start; i < end; i++) {
					// for each sample...
					input = samples[i];
					b0 = b0 + cut * (input - b0 + fb * (b0 - b1));
					b1 = b1 + cut * (b0 - b1);
					samples[i] = input - b0;
				}
			}
			m_b0 = b0;
			m_b1 = b1;
		}
		public function hpf2(samples:Vector.<Number>, start:int, end:int, envelope:MEnvelope, frq:Number, amt:Number, res:Number, key:Number):void {
			var t1:Number = m_t1, t2:Number = m_t2, b0:Number = m_b0, b1:Number = m_b1, b2:Number = m_b2, b3:Number = m_b3, b4:Number = m_b4;
			//var k:Number = key * (2.0 * Math.PI / (MSequencer.RATE44100 * 440.0));
			for(var i:int = start; i < end; i++) {
				//var cut:Number = MChannel.getFrequency(frq + amt * envelope.getNextAmplitudeLinear()) * k;
				var cut:Number = frq + (amt * (Math.pow(1000.0, envelope.getNextAmplitudeLinear()) / 1000.0));
				if (cut < (40.0/44100.0)) cut = 40.0/44100.0;
				if (cut > 1.0) cut = 1.0;
				// Set coefficients given frequency & resonance [0.0...1.0]
				var q:Number = 1.0 - cut;
				var p:Number = cut + 0.8 * cut * q;
				var f:Number = p + p - 1.0;
				q = res * (1.0 + 0.5 * q * (1.0 - q + 5.6 * q * q));
				// Filter (input [-1.0...+1.0])
				var input:Number = samples[i];
				input -= q * b4;                      //feedback
				t1 = b1;  b1 = (input + b0) * p - b1 * f;
				t2 = b2;  b2 = (b1 + t1) * p - b2 * f;
				t1 = b3;  b3 = (b2 + t2) * p - b3 * f;
				b4 = (b3 + t1) * p - b4 * f;
				b4 = b4 - b4 * b4 * b4 * 0.166667;    //clipping
				b0 = input;
				samples[i] = input - b4;
			}
			m_t1 = t1;
			m_t2 = t2;
			m_b0 = b0;
			m_b1 = b1;
			m_b2 = b2;
			m_b3 = b3;
			m_b4 = b4;
		}

	}
}
