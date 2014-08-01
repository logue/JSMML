package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscLNoiseWA extends MOscModL {
		public static const MAX_WAVE:int = 1;
		protected static var s_init:int = 0;
		protected var m_waveNo:int;
		protected var m_getValue:Function;
		protected var m_counter:Number;
		protected var m_refreshCycle:Number;
		protected var m_val:Number;

		public function MOscLNoiseWA() {
			boot();
			super();
			setWaveNo(0);
			setNoiseFreq(1.0);
			resetPhase();
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public override function resetPhase():void {
			m_counter = 1.0;
			m_val = 0.0;
		}
		private function getValueW0():void {
			m_counter -= 1.0;
			if (m_counter <= 0.0) {
				m_val = (Math.random()) * (-1.0);					// -1.0 ～ 0.0
				m_counter += m_refreshCycle;
			}
		}
		public override function getNextSample():Number {
			m_getValue();
			return m_val;
		}
		public override function setNoiseFreq(cycle:Number):void {
			if (cycle < 1.0) {
				m_refreshCycle = 1.0;
			} else if (cycle > 44100.0) {
				m_refreshCycle = 44100.0;
			} else {
				m_refreshCycle = cycle;
			}
			m_counter = 1.0;
			m_val = 0.0;
		}
		public override function addPShift(sample:int):void {
			var i:int;
			if (sample <= 0) return;
			for (i=0; i<sample; i++) {
				getNextSample();
			}
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
