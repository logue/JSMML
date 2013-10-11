package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscMod {
        public static const TABLE_LEN:int = 1 << 16;
        public static const PHASE_SFT:int = 14;
        public static const PHASE_LEN:int = TABLE_LEN << PHASE_SFT;
        public static const PHASE_HLF:int = TABLE_LEN << (PHASE_SFT-1);
        public static const PHASE_MSK:int = PHASE_LEN-1;

        protected var m_frequency:Number;
        protected var m_freqShift:int;
        protected var m_phase:int;

        public function MOscMod() {
            resetPhase();
            setFrequency(440.0);
        }
        public function resetPhase():void {
            m_phase = 0;
        }
        public function addPhase(time:int):void {
            m_phase = (m_phase + m_freqShift * time) & PHASE_MSK;
        }
        public function getNextSample():Number {
            return 0;
        }
        public function getNextSampleOfs(ofs:int):Number {
            return 0;
        }
        public function getSamples(samples:Vector.<Number>, start:int, end:int):void {
        }
        public function getSamplesWithSyncIn(samples:Vector.<Number>, syncin:Vector.<Boolean>, start:int, end:int):void {
        	getSamples(samples, start, end);
        }
        public function getSamplesWithSyncOut(samples:Vector.<Number>, syncout:Vector.<Boolean>, start:int, end:int):void {
        	getSamples(samples, start, end);
        }
        public function getFrequency():Number {
            return m_frequency;
        }
        public function setFrequency(frequency:Number):void {
            m_frequency = frequency;
            m_freqShift = frequency * (PHASE_LEN / MSequencer.RATE44100);
        }
		public function setWaveNo(waveNo:int):void {
		}
		public function setNoteNo(noteNo:int):void {
		}		
    }
}
