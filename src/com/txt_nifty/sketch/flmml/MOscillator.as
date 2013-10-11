package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscillator {
        public static const SINE:int       = 0;
        public static const SAW:int        = 1;
        public static const TRIANGLE:int   = 2;
        public static const PULSE:int      = 3;
        public static const NOISE:int      = 4;
        public static const FC_PULSE:int   = 5;
        public static const FC_TRI:int     = 6;
        public static const FC_NOISE:int   = 7;
        public static const FC_S_NOISE:int = 8;
        public static const FC_DPCM:int    = 9;
        public static const GB_WAVE:int    = 10;
        public static const GB_NOISE:int   = 11;
        public static const GB_S_NOISE:int = 12;
        public static const WAVE:int       = 13;
        public static const OPM:int        = 14;
        public static const MAX:int        = 15;
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
            m_osc[NOISE]      = new MOscNoise();
            m_osc[FC_PULSE]   = new MOscPulse();
            m_osc[FC_TRI]     = new MOscFcTri();
            m_osc[FC_NOISE]   = new MOscFcNoise();
            m_osc[FC_S_NOISE] = null;
			//2009.05.10 OffGao MOD 1L addDPCM
            //m_osc[FC_DPCM]    = new MOscMod();
            m_osc[FC_DPCM]    = new MOscFcDpcm();
            m_osc[GB_WAVE]    = new MOscGbWave();
            m_osc[GB_NOISE]   = new MOscGbLNoise();
            m_osc[GB_S_NOISE] = new MOscGbSNoise();
            m_osc[WAVE]       = new MOscWave();
            m_osc[OPM]        = new MOscOPM();
            setForm(PULSE);
			setNoiseToPulse();
        }
        public function asLFO():void {
            if (m_osc[NOISE]) ((MOscNoise)(m_osc[NOISE])).disableResetPhase();
        }
        public static function boot():void {
            if (s_init) return;
            MOscSine.boot();
            MOscSaw.boot();
            MOscTriangle.boot();
            MOscPulse.boot();
            MOscNoise.boot();
            MOscFcTri.boot();
            MOscFcNoise.boot();
			//2009.05.10 OffGao ADD 1L addDPCM
            MOscFcDpcm.boot();
            MOscGbWave.boot();
            MOscGbLNoise.boot();
            MOscGbSNoise.boot();
            MOscWave.boot();
			MOscOPM.boot();
            s_init = 1;
        }
        public function setForm(form:int):MOscMod {
            var modNoise:MOscNoise;
            var modFcNoise:MOscFcNoise;
            if (form >= MAX) form = MAX-1;
            m_form = form;
            switch(form) {
            case NOISE:
                modNoise = (MOscNoise)(m_osc[NOISE]);
                modNoise.restoreFreq();
                break;
            case FC_NOISE:
                modFcNoise = (MOscFcNoise)(getMod(FC_NOISE));
                modFcNoise.setLongMode();
                break;
            case FC_S_NOISE:
                modFcNoise = (MOscFcNoise)(getMod(FC_S_NOISE));
                modFcNoise.setShortMode();
                break;
            }
            return getMod(form);
        }
        public function getForm():int {
            return m_form;
        }
        public function getCurrent():MOscMod {
            return getMod(m_form);
        }
        public function getMod(form:int):MOscMod {
            return (form != FC_S_NOISE) ? m_osc[form] : m_osc[FC_NOISE];
        }
		private function  setNoiseToPulse():void {
			var modPulse:MOscPulse = (MOscPulse)(getMod(PULSE));
			var modNoise:MOscNoise = (MOscNoise)(getMod(NOISE));
			modPulse.setNoise(modNoise);
		}
    }
}
