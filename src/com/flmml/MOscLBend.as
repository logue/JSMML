package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscLBend extends MOscModL {
		public static const MAX_WAVE:int = 2;
		protected static var s_init:int = 0;
		protected var m_waveNo:int;
		protected var m_getValue:Function;
		protected var m_addPhase:Function;
		protected var m_val:Number;

		public function MOscLBend() {
			boot();
			super();
			setWaveNo(0);
			m_val = 0.0;
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		private function addPhaseW0(time:int):void {
			m_phase = (m_phase + (m_freqShift * Number(time)));
			if (m_phase >= 1.0) m_phase = 1.0;
		}
		private function addPhaseW1(time:int):void {
			m_phase = (m_phase + (m_freqShift * Number(time))) % (1.0);
		}
		public override function addPhase(time:int):void {
			m_addPhase(time);
		}
		private function getValueW0():void {
			if (m_phase < 1.0) m_val = m_phase;
			else               m_val = 1.0;
			m_phase = m_phase + m_freqShift;
			if (m_phase >= 1.0) m_phase = 1.0;
		}
		private function getValueW1():void {
			if (m_phase < 1.0) m_val = m_phase;
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
				m_addPhase = addPhaseW0;
				break;
			case 1:
				m_getValue = getValueW1;
				m_addPhase = addPhaseW1;
				break;
			}
		}
	}
}
