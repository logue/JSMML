package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscLBendNL extends MOscModL {
		protected static var s_init:int = 0;
		protected var m_val:Number;
		protected var m_preCulc:Number;
		protected var m_counter:Number;
		protected var m_refreshCycle:Number;
		protected var m_incParam:Number;

		public function MOscLBendNL() {
			boot();
			super();
			setWaveNo(64);
			setBendWidth(2.0);
			resetPhase();
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public override function resetPhase():void {
			m_counter = 1.0;
			m_val = 0.0;
			m_preCulc = (-1.0);
		}
		public override function getNextSample():Number {
			m_counter -= 1.0;
			if (m_counter < 0.0) {
				m_preCulc = m_preCulc - (m_preCulc * (m_incParam / 1024.0));
				m_val = m_preCulc + 1.0;
				m_counter += m_refreshCycle;
			}
			return m_val;
		}
		public function setBendWidth(width:Number):void {
			var n:Number = width;
			if (n < 1.0)     n = 1.0;
			if (n > 44100.0) n = 44100.0;
			m_refreshCycle = n;
		}
		public override function addPShift(sample:int):void {
			var i:int;
			if (sample <= 0) return;
			for (i=0; i<sample; i++) {
				getNextSample();
			}
		}
		public override function setWaveNo(waveNo:int):void {
			var n:Number = Number(waveNo);
			if (n <   1.0) n = 1.0;
			if (n > 512.0) n = 512.0;
			m_incParam = n;
		}
	}
}
