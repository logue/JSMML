package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscNoise extends MOscMod {
        public static const TABLE_MSK:int = TABLE_LEN-1;
        public static const NOISE_PHASE_SFT:int = 30;
        public static const NOISE_PHASE_MSK:int = (1<<NOISE_PHASE_SFT)-1;
        protected var m_noiseFreq:Number;
        protected var m_counter:uint;
        protected var m_resetPhase:Boolean;
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Number> = new Vector.<Number>(TABLE_LEN, true);

        public function MOscNoise() {
            boot();
            super();
            setNoiseFreq(1.0);
            m_phase = 0;
            m_counter = 0;
            m_resetPhase = true;
        }
        public function disableResetPhase():void {
            m_resetPhase = false;
        }
        public static function boot():void {
            if (s_init) return;
            for(var i:int = 0; i < TABLE_LEN; i++) {
                s_table[i] = Math.random() * 2.0 - 1.0;
            }
            s_init = 1;
        }
        public override function resetPhase():void {
            if (m_resetPhase) m_phase = 0;
            //m_counter = 0;
        }
        public override function addPhase(time:int):void {
            m_counter = (m_counter + m_freqShift * time);
            m_phase = (m_phase + (m_counter >> NOISE_PHASE_SFT)) & TABLE_MSK;
            m_counter &= NOISE_PHASE_MSK;
        }
        public override function getNextSample():Number {
            var val:Number = s_table[m_phase];
            m_counter = (m_counter + m_freqShift);
            m_phase = (m_phase + (m_counter >> NOISE_PHASE_SFT)) & TABLE_MSK;
            m_counter &= NOISE_PHASE_MSK;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = s_table[(m_phase + (ofs << PHASE_SFT)) & TABLE_MSK];
            m_counter = (m_counter + m_freqShift);
            m_phase = (m_phase + (m_counter >> NOISE_PHASE_SFT)) & TABLE_MSK;
            m_counter &= NOISE_PHASE_MSK;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            for(i = start; i < end; i++) {
                samples[i] = s_table[m_phase];
                m_counter = (m_counter + m_freqShift);
                m_phase = (m_phase + (m_counter >> NOISE_PHASE_SFT)) & TABLE_MSK;
                m_counter &= NOISE_PHASE_MSK;
            }
        }
        public override function setFrequency(frequency:Number):void {
            m_frequency = frequency;
        }
        public function setNoiseFreq(frequency:Number):void {
            m_noiseFreq = frequency * (1<<NOISE_PHASE_SFT);
            m_freqShift = m_noiseFreq;
        }
        public function restoreFreq():void {
            m_freqShift = m_noiseFreq;
        }
    }
}
