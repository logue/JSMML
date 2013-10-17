package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscSine extends MOscMod {
		protected static var s_init:int = 0;

		public function MOscSine() {
			boot();
			m_modID = MOscillator.SINE;
			super();
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public override function getNextSample():Number {
			var val:Number = Math.sin(2.0 * Math.PI * m_phase);
			m_phase = (m_phase + m_freqShift) % (1.0);
			return val;
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for (i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
	}
}
