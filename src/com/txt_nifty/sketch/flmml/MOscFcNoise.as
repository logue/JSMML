package com.txt_nifty.sketch.flmml {
    /**
       Special thanks to OffGao.
     */
    import __AS3__.vec.Vector;

    public class MOscFcNoise extends MOscMod {
        public static const FC_NOISE_PHASE_SFT:int = 10;
        public static const FC_NOISE_PHASE_SEC:int = (1789773 << FC_NOISE_PHASE_SFT);
        public static const FC_NOISE_PHASE_DLT:int = FC_NOISE_PHASE_SEC / 44100;
        protected static var s_interval:Vector.<int> = Vector.<int>([0x004, 0x008, 0x010, 0x020, 0x040, 0x060, 0x080, 0x0a0,
                                                                     0x0ca, 0x0fe, 0x17c, 0x1fc, 0x2fa, 0x3f8, 0x7f2, 0xfe4]);
        protected var m_fcr:int;
        protected var m_snz:int;
        protected var m_val:Number;

        private function getValue():Number {
            m_fcr >>= 1;
            m_fcr |= ((m_fcr ^(m_fcr >> m_snz)) & 1) << 15;
            return (m_fcr & 1) ? 1.0 : -1.0;
        }
        public function setShortMode():void {
            m_snz = 6;
        }
        public function setLongMode():void {
            m_snz = 1;
        }
        public function MOscFcNoise() {
            boot();
            super();
            setLongMode();
            m_fcr = 0x8000;
            m_val = getValue();
            setNoiseFreq(0);
        }
        public override function resetPhase():void {
        }
        public override function addPhase(time:int):void {
            m_phase = m_phase + FC_NOISE_PHASE_DLT * time;
            while (m_phase >= m_freqShift) {
                m_phase -= m_freqShift;
                m_val = getValue();
            }
        }
        public static function boot():void {
        }
        public override function getNextSample():Number {
            var val:Number = m_val;
            var sum:Number = 0;
            var cnt:Number = 0;
            var delta:int = FC_NOISE_PHASE_DLT;
            while (delta >= m_freqShift) {
                delta -= m_freqShift;
                m_phase = 0;
                sum += getValue();
                cnt += 1.0;
            }
            if (cnt > 0) {
                m_val = sum / cnt;
            }
            m_phase += delta;
            if (m_phase >= m_freqShift) {
                m_phase -= m_freqShift;
                m_val = getValue();
            }
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var fcr:int = m_fcr;
            var phase:int = m_phase;
            var val:Number = m_val;
            var sum:Number = 0;
            var cnt:Number = 0;
            var delta:int = FC_NOISE_PHASE_DLT + ofs;
            while (delta >= m_freqShift) {
                delta -= m_freqShift;
                m_phase = 0;
                sum += getValue();
                cnt += 1.0;
            }
            if (cnt > 0) {
                m_val = sum / cnt;
            }
            m_phase += delta;
            if (m_phase >= m_freqShift) {
                m_phase = m_freqShift;
                m_val = getValue();
            }
            /* */
            m_fcr = fcr;
            m_phase = phase;
            getNextSample();
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            var val:Number;
            for(i = start; i < end; i++) {
                samples[i] = getNextSample();
            }
        }
        public override function setFrequency(frequency:Number):void {
            //m_frequency = frequency;
            m_freqShift = FC_NOISE_PHASE_SEC / frequency;
        }
        public function setNoiseFreq(no:int):void {
            if (no < 0) no = 0;
            if (no > 15) no = 15;
            m_freqShift = s_interval[no] << FC_NOISE_PHASE_SFT; // as interval
        }
        public override function setNoteNo(noteNo:int):void {
            setNoiseFreq(noteNo);
        }		
    }
}
