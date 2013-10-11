package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscSine extends MOscMod {
        public static const MAX_WAVE:int = 3;
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Vector.<Number>>;
        protected var m_waveNo:int;

        public function MOscSine() {
            boot();
            super();
            setWaveNo(0);
        }
        public static function boot():void {
            if (s_init) return;
            var d0:Number = 2.0 * Math.PI / TABLE_LEN;
            var p0:Number;
            var i:int;
            s_table = new Vector.<Vector.<Number>>(MAX_WAVE);
            for (i = 0; i < MAX_WAVE; i++) {
                s_table[i] = new Vector.<Number>(TABLE_LEN, true);
            }
            for(i = 0, p0 = 0.0; i < TABLE_LEN; i++) {
                s_table[0][i] = Math.sin(p0);
                s_table[1][i] = Math.max(0.0, s_table[0][i]);
                s_table[2][i] = (s_table[0][i] >= 0.0) ? s_table[0][i] : s_table[0][i] * -1.0;
                p0 += d0;
            }
            s_init = 1;
        }
        public override function getNextSample():Number {
            var val:Number = s_table[m_waveNo][m_phase >> PHASE_SFT];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = s_table[m_waveNo][((m_phase + ofs) & PHASE_MSK) >> PHASE_SFT];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            var tbl:Vector.<Number> = s_table[m_waveNo];
            for(i = start; i < end; i++) {
                samples[i] = tbl[m_phase >> PHASE_SFT];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            }
        }
        public override function getSamplesWithSyncIn(samples:Vector.<Number>, syncin:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
            var tbl:Vector.<Number> = s_table[m_waveNo];
			for(i = start; i < end; i++) {
				if(syncin[i]){
					resetPhase();
				}
                samples[i] = tbl[m_phase >> PHASE_SFT];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
			}        	
        }
        public override function getSamplesWithSyncOut(samples:Vector.<Number>, syncout:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
            var tbl:Vector.<Number> = s_table[m_waveNo];
			for(i = start; i < end; i++) {
                samples[i] = tbl[m_phase >> PHASE_SFT];
                m_phase += m_freqShift;
                syncout[i] = (m_phase > PHASE_MSK);
                m_phase &= PHASE_MSK;
			}        	
        }
        public override function setWaveNo(waveNo:int):void {
            if (waveNo >= MAX_WAVE) waveNo = MAX_WAVE-1;
            if (!s_table[waveNo]) waveNo = 0;
            m_waveNo = waveNo;
        }
    }
}
