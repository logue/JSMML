package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscGbWave extends MOscMod {
        public static const MAX_WAVE:int = 32;
        public static const GB_WAVE_TABLE_LEN:int = (1 << 5);
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Vector.<Number>>;
        protected var m_waveNo:int;

        public function MOscGbWave() {
            boot();
            super();
            setWaveNo(0);
        }
        public static function boot():void {
            if (s_init) return;
            s_table = new Vector.<Vector.<Number>>(MAX_WAVE);
            setWave(0, "0123456789abcdeffedcba9876543210");
            s_init = 1;
        }
        public static function setWave(waveNo:int, wave:String):void {
            //trace("["+waveNo+"]"+wave);
            s_table[waveNo] = new Vector.<Number>(GB_WAVE_TABLE_LEN);
            for(var i:int = 0; i < 32; i++) {
                var code:int = wave.charCodeAt(i);
                if (48 <= code && code < 58) {
                    code -= 48;
                }
                else if (97 <= code && code < 103) {
                    code -= 97-10;
                }
                else {
                    code = 0;
                }
                s_table[waveNo][i] = (Number(code) - 7.5) / 7.5;
            }
        }
        public override function setWaveNo(waveNo:int):void {
            if (waveNo >= MAX_WAVE) waveNo = MAX_WAVE-1;
            if (!s_table[waveNo]) waveNo = 0;
            m_waveNo = waveNo;
        }
        public override function getNextSample():Number {
            var val:Number = s_table[m_waveNo][m_phase >> (PHASE_SFT+11)];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = s_table[m_waveNo][((m_phase + ofs) & PHASE_MSK) >> (PHASE_SFT+11)];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            for(i = start; i < end; i++) {
                samples[i] = s_table[m_waveNo][m_phase >> (PHASE_SFT+11)];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            }
        }
        public override function getSamplesWithSyncIn(samples:Vector.<Number>, syncin:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				if(syncin[i]){
					resetPhase();
				}
                samples[i] = s_table[m_waveNo][m_phase >> (PHASE_SFT+11)];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
			}        	
        }
        public override function getSamplesWithSyncOut(samples:Vector.<Number>, syncout:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
                samples[i] = s_table[m_waveNo][m_phase >> (PHASE_SFT+11)];
                m_phase += m_freqShift;
                syncout[i] = (m_phase > PHASE_MSK);
                m_phase &= PHASE_MSK;
			}        	
        }
    }
}
