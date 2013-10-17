package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscLSineA extends MOscModL {
		public static const MAX_WAVE:int = 1;
		protected static var s_init:int = 0;
		protected var m_waveNo:int;
		protected var m_getValue:Function;
		protected var m_val:Number;

		public function MOscLSineA() {
			boot();
			super();
			setWaveNo(0);
			m_val = 0.0;
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		private function getValueW0():void {
			m_val   = (Math.cos(2.0 * Math.PI * m_phase) * (0.5)) - 0.5;
			m_phase = (m_phase + m_freqShift) % (1.0);
		}
		public override function getNextSample():Number {
			m_getValue();
			return m_val;
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (n >= MAX_WAVE) n = MAX_WAVE-1;
			if (n < 0) n = 0;
			m_waveNo = n;
			switch(m_waveNo) {
			case 0:
			default:
				m_getValue = getValueW0;
				break;
			}
		}
	}
}
