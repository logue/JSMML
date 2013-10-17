package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscModL {
		protected var m_frequency:Number;
		protected var m_freqShift:Number;
		protected var m_phase:Number;

		public function MOscModL() {
			setFrequency(440.0);
			resetPhase();
		}

		public function resetPhase():void {
			m_phase = 0.0;
		}

		public function addPhase(time:int):void {
			m_phase = (m_phase + (m_freqShift * Number(time))) % (1.0);
		}

		public function getNextSample():Number {
			return (0.0);
		}

		public function getFrequency():Number {
			return m_frequency;
		}

		public function setFrequency(frequency:Number):void {
			m_frequency = frequency;
			m_freqShift = frequency / 44100.0;
		}

		public function setNoiseFreq(index:Number):void {
		}

		public function setWaveNo(waveNo:int):void {
		}

		public function setWaveNoForSwitchCtrl(w1:int, w2:int):void {
		}
	}
}
