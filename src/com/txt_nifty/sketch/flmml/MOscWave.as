package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscWave extends MOscMod {
        public static const MAX_WAVE:int = 32;
        public static const MAX_LENGTH:int = 2048;
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Vector.<Number>>;
        protected static var s_length:Vector.<Number>;
        protected var m_waveNo:int;

        public function MOscWave() {
            boot();
            super();
            setWaveNo(0);
        }
        public static function boot():void {
            if (s_init) return;
            s_table = new Vector.<Vector.<Number>>(MAX_WAVE);
            s_length = new Vector.<Number>(MAX_WAVE);
            setWave(0, "00112233445566778899AABBCCDDEEFFFFEEDDCCBBAA99887766554433221100");
            s_init = 1;
        }
        public static function setWave(waveNo:int, wave:String):void {
            //trace("["+waveNo+"]"+wave);
            s_length[waveNo] = 0;
            s_table[waveNo] = new Vector.<Number>(wave.length/2);
 	        s_table[waveNo][0] = 0;
            for(var i:int = 0, j:int = 0, val:int = 0; i < MAX_LENGTH && i < wave.length; i++, j++) {
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
                if(j&1){
                	val += code;
	                s_table[waveNo][s_length[waveNo]] = (Number(val) - 127.5) / 127.5;
	                s_length[waveNo]++;
	            }else{
	                val = code<<4;
	            }
            }
            if(s_length[waveNo]==0)s_length[waveNo]=1;
            s_length[waveNo] =(PHASE_MSK+1) / s_length[waveNo];
        }
        public override function setWaveNo(waveNo:int):void {
            if (waveNo >= MAX_WAVE) waveNo = MAX_WAVE-1;
            if (!s_table[waveNo]) waveNo = 0;
            m_waveNo = waveNo;
        }
        public override function getNextSample():Number {
            var val:Number = s_table[m_waveNo][int(m_phase / s_length[m_waveNo])];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = s_table[m_waveNo][int(((m_phase + ofs) & PHASE_MSK) / s_length[m_waveNo])];
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            for(i = start; i < end; i++) {
                samples[i] = s_table[m_waveNo][int(m_phase / s_length[m_waveNo])];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            }
        }
        public override function getSamplesWithSyncIn(samples:Vector.<Number>, syncin:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				if(syncin[i]){
					resetPhase();
				}
                samples[i] = s_table[m_waveNo][int(m_phase / s_length[m_waveNo])];
                m_phase = (m_phase + m_freqShift) & PHASE_MSK;
			}        	
        }
        public override function getSamplesWithSyncOut(samples:Vector.<Number>, syncout:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
                samples[i] = s_table[m_waveNo][int(m_phase / s_length[m_waveNo])];
                m_phase += m_freqShift;
                syncout[i] = (m_phase > PHASE_MSK);
                m_phase &= PHASE_MSK;
			}        	
        }
    }
}