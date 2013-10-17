package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscillator {
		public static const SINE:int       = 0;
		public static const SAW:int        = 1;
		public static const TRIANGLE:int   = 2;
		public static const PULSE:int      = 3;
		public static const NOISE_W:int    = 4;
		public static const NOISE_FC:int   = 5;
		public static const NOISE_GB:int   = 6;
		public static const NOISE_PSG:int  = 7;
		public static const WAVEMEM:int    = 8;
		public static const OPMS:int       = 9;
		public static const SMP_DPCM:int   = 10;
		public static const SMP_U8PCM:int  = 11;
		public static const MAX:int        = 12;

		protected static var s_init:int = 0;
		protected var m_osc:Vector.<MOscMod>;
		protected var m_form:int;

		public function MOscillator() {
			boot();
			m_osc = new Vector.<MOscMod>(MAX);
			m_osc.fixed = true;
			m_osc[SINE]       = new MOscSine();
			m_osc[SAW]        = new MOscSaw();
			m_osc[TRIANGLE]   = new MOscTriangle();
			m_osc[PULSE]      = new MOscPulse();
			m_osc[NOISE_W]    = new MOscNoiseW();
			m_osc[NOISE_FC]   = new MOscNoiseFC();
			m_osc[NOISE_GB]   = new MOscNoiseGB();
			m_osc[NOISE_PSG]  = new MOscNoisePSG();
			m_osc[WAVEMEM]    = new MOscWaveMem();
			m_osc[OPMS]       = new MOscOPMS();
			m_osc[SMP_DPCM]   = new MOscSmpDPCM();
			m_osc[SMP_U8PCM]  = new MOscSmpU8PCM();
			setForm(PULSE);
			setNoiseModToPulseMod();
		}
		public static function boot():void {
			if (s_init) return;
			MOscSine.boot();
			MOscSaw.boot();
			MOscTriangle.boot();
			MOscPulse.boot();
			MOscNoiseW.boot();
			MOscNoiseFC.boot();
			MOscNoiseGB.boot();
			MOscNoisePSG.boot();
			MOscWaveMem.boot();
			MOscOPMS.boot();
			MOscSmpDPCM.boot();
			MOscSmpU8PCM.boot();
			s_init = 1;
		}
		public function setForm(form:int):MOscMod {
			if (form >= MAX) form = MAX-1;
			m_form = form;
			return getMod(form);
		}
		public function getForm():int {
			return m_form;
		}
		public function getCurrent():MOscMod {
			return getMod(m_form);
		}
		public function getMod(form:int):MOscMod {
			return m_osc[form];
		}
		private function setNoiseModToPulseMod():void {
			var modPulse:MOscPulse    = (MOscPulse)(getMod(PULSE));
			var modNoise:MOscNoisePSG = (MOscNoisePSG)(getMod(NOISE_PSG));
			modPulse.setNoiseModule(modNoise);
		}
	}
}
