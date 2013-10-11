package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscFcTri extends MOscMod {
        public static const FC_TRI_TABLE_LEN:int = (1 << 5);
        public static const MAX_WAVE:int = 2;
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Vector.<Number>>;
        protected var m_waveNo:int;

        public function MOscFcTri() {
            boot();
            super();
            setWaveNo(0);
        }
        public static function boot():void {
            if (s_init) return;
            s_table = new Vector.<Vector.<Number>>(MAX_WAVE);
			s_table[0] = new Vector.<Number>(FC_TRI_TABLE_LEN);	// @6-0
			s_table[1] = new Vector.<Number>(FC_TRI_TABLE_LEN);	// @6-1
			var i:int;
            for(i = 0; i < 16; i++) {
                s_table[0][i] = s_table[0][31 - i] = Number(i) * 2.0 / 15.0 - 1.0;
            }
            for(i = 0; i < 32; i++) {
				s_table[1][i] = (i < 8) ? Number(i)*2.0/14.0 : ((i < 24) ? Number(8-i)*2.0/15.0+1.0: Number(i-24)*2.0/15.0-1.0);
			}
            s_init = 1;
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
        public override function setWaveNo(waveNo:int):void {
            m_waveNo = Math.min(waveNo, MAX_WAVE-1);
        }			
    }
}
