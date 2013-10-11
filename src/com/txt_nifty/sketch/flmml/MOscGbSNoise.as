package com.txt_nifty.sketch.flmml {
    /**
       Special thanks to OffGao.
     */
    import __AS3__.vec.Vector;

    public class MOscGbSNoise extends MOscMod {
        public static const GB_NOISE_PHASE_SFT:int = 12;
        public static const GB_NOISE_PHASE_DLT:int = 1<<GB_NOISE_PHASE_SFT
        public static const GB_NOISE_TABLE_LEN:int = 127;
        public static const GB_NOISE_TABLE_MOD:int = (GB_NOISE_TABLE_LEN << GB_NOISE_PHASE_SFT)-1;
        protected static var s_init:int = 0;
        protected static var s_table:Vector.<Number> = new Vector.<Number>(GB_NOISE_TABLE_LEN);
        protected static var s_interval:Vector.<int> = Vector.<int>
            ([0x000002, 0x000004, 0x000008, 0x00000c, 0x000010, 0x000014, 0x000018, 0x00001c,
              0x000020, 0x000028, 0x000030, 0x000038, 0x000040, 0x000050, 0x000060, 0x000070,
              0x000080, 0x0000a0, 0x0000c0, 0x0000e0, 0x000100, 0x000140, 0x000180, 0x0001c0,
              0x000200, 0x000280, 0x000300, 0x000380, 0x000400, 0x000500, 0x000600, 0x000700,
              0x000800, 0x000a00, 0x000c00, 0x000e00, 0x001000, 0x001400, 0x001800, 0x001c00,
              0x002000, 0x002800, 0x003000, 0x003800, 0x004000, 0x005000, 0x006000, 0x007000,
              0x008000, 0x00a000, 0x00c000, 0x00e000, 0x010000, 0x014000, 0x018000, 0x01c000,
              0x020000, 0x028000, 0x030000, 0x038000, 0x040000, 0x050000, 0x060000, 0x070000]);

        protected var m_sum:int;
        protected var m_skip:int;

        public function MOscGbSNoise() {
            boot();
            super();
            m_sum = 0;
            m_skip = 0;
        }
        public static function boot():void {
            if (s_init) return;
            var gbr:uint = 0xffff;
            var output:uint = 1;
            for(var i:int = 0; i < GB_NOISE_TABLE_LEN; i++) {
                if (gbr == 0) gbr = 1;
                gbr += gbr + (((gbr >> 6) ^ (gbr >> 5)) & 1);
                output ^= gbr & 1;
                s_table[i] = output * 2 - 1;
            }
            s_init = 1;
        }
        public override function getNextSample():Number {
            var val:Number = s_table[m_phase >> GB_NOISE_PHASE_SFT];
            if (m_skip > 0) {
              val = (val + m_sum) / Number(m_skip+1);
            }
            m_sum = 0;
            m_skip = 0;
            var freqShift:int = m_freqShift;
            while (freqShift > GB_NOISE_PHASE_DLT) {
                m_phase = (m_phase + GB_NOISE_PHASE_DLT) % GB_NOISE_TABLE_MOD;
                freqShift -= GB_NOISE_PHASE_DLT;
                m_sum += s_table[m_phase >> GB_NOISE_PHASE_SFT];
                m_skip++;
            }
            m_phase = (m_phase + freqShift) % GB_NOISE_TABLE_MOD;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
        	var phase:int = (m_phase + ofs) % GB_NOISE_TABLE_MOD;
            var val:Number = s_table[(phase + ((phase >> 31) & GB_NOISE_TABLE_MOD)) >> GB_NOISE_PHASE_SFT];
            m_phase = (m_phase + m_freqShift) % GB_NOISE_TABLE_MOD;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            var val:Number;
            for(i = start; i < end; i++) {
                val = s_table[m_phase >> GB_NOISE_PHASE_SFT];
                if (m_skip > 0) {
                    val = (val + m_sum) / Number(m_skip+1);
                }
                samples[i] = val;
                m_sum = 0;
                m_skip = 0;
                var freqShift:int = m_freqShift;
                while (freqShift > GB_NOISE_PHASE_DLT) {
                    m_phase = (m_phase + GB_NOISE_PHASE_DLT) % GB_NOISE_TABLE_MOD;
                    freqShift -= GB_NOISE_PHASE_DLT;
                    m_sum += s_table[m_phase >> GB_NOISE_PHASE_SFT];
                    m_skip++;
                }
                m_phase = (m_phase + freqShift) % GB_NOISE_TABLE_MOD;
            }
        }
        public override function setFrequency(frequency:Number):void {
            m_frequency = frequency;
        }
        public function setNoiseFreq(no:int):void {
            if (no < 0) no = 0;
            if (no > 63) no = 63;
            m_freqShift = (1048576 << (GB_NOISE_PHASE_SFT-2)) / (s_interval[no] * 11025);
        }
        public override function setNoteNo(noteNo:int):void {
            setNoiseFreq(noteNo);
        }		
    }
}
