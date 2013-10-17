package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscTriangle extends MOscMod {
		protected static var s_init:int = 0;

		public function MOscTriangle() {
			boot();
			m_modID = MOscillator.TRIANGLE;
			super();
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public override function getNextSample():Number {
			var val:Number;
			if      (m_phase < 0.25) val = (4.0 * m_phase);
			else if (m_phase < 0.75) val = 2.0 - (4.0 * m_phase);
			else                     val = (4.0 * m_phase) - 4.0;
			m_phase = (m_phase + m_freqShift) % (1.0);
			return val;
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
	}
}
