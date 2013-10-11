package com.txt_nifty.sketch.flmml {
    /**
       DPCM Oscillator by OffGao
       09/05/11：作成
       09/11/05：波形データ格納処理で、データが32bitごとに1bit抜けていたのを修正
     */
    import __AS3__.vec.Vector;

    public class MOscFcDpcm extends MOscMod {
        public static const MAX_WAVE:int = 16;
        public static const FC_CPU_CYCLE:int = 1789773;
        public static const FC_DPCM_PHASE_SFT:int = 2;
        public static const FC_DPCM_MAX_LEN:int = 0xff1;//(0xff * 0x10) + 1 ファミコン準拠の最大レングス
        public static const FC_DPCM_TABLE_MAX_LEN:int = (FC_DPCM_MAX_LEN >> 2) + 2;
        public static const FC_DPCM_NEXT:int = 44100 << FC_DPCM_PHASE_SFT;
        protected static var s_init:int = 0;
        protected var m_readCount:int = 0;	//次の波形生成までのカウント値
        protected var m_address:int = 0;		//読み込み中のアドレス位置
        protected var m_bit:int = 0;		//読み込み中のビット位置
        protected var m_wav:int = 0;		//現在のボリューム
        protected var m_length:int = 0;		//残り読み込み長
        protected var m_ofs:int = 0;		//前回のオフセット
        protected static var s_table:Vector.<Vector.<uint>>;
        protected static var s_intVol:Vector.<int>;	//波形初期位置
        protected static var s_loopFg:Vector.<int>;	//ループフラグ
        protected static var s_length:Vector.<int>;	//再生レングス
        protected var m_waveNo:int;
        protected static var s_interval:Vector.<int> = Vector.<int>([ //音程
			428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106,  85,  72,  54,
		]);

        public function MOscFcDpcm() {
            boot();
            super();
            setWaveNo(0);
        }
        public static function boot():void {
            if (s_init) return;
            s_table = new Vector.<Vector.<uint>>(MAX_WAVE);
			s_intVol = new Vector.<int>(MAX_WAVE);
			s_loopFg = new Vector.<int>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
            setWave(0, 127, 0,"");
            s_init = 1;
        }
        public static function setWave(waveNo:int, intVol:int, loopFg:int, wave:String):void {
			s_intVol[waveNo] = intVol;
			s_loopFg[waveNo] = loopFg;
			s_length[waveNo] = 0;
			
            s_table[waveNo] = new Vector.<uint>(FC_DPCM_TABLE_MAX_LEN);
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			for (var i:int = 0; i < FC_DPCM_TABLE_MAX_LEN; i++) {
				s_table[waveNo][i] = 0;
			}

            for(strCnt = 0; strCnt < wave.length; strCnt++) {
                var code:int = wave.charCodeAt(strCnt);
                if (0x41 <= code && code <= 0x5a) { //A-Z
                    code -= 0x41;
                }
                else if(0x61 <= code && code <= 0x7a) { //a-z
                    code -= 0x61-26;
                }
                else if(0x30 <= code && code <= 0x39) { //0-9
                    code -= 0x30-26-26;
                }
                else if(0x2b == code) { //+
                    code = 26+26+10;
                }
                else if(0x2f == code) { // /
                    code = 26+26+10+1;
                }
                else if(0x3d == code) { // =
                    code = 0;
                }
                else {
                    code = 0;
                }
				for(i = 5; i >=0 ; i--) {
					s_table[waveNo][intPos] += ((code >> i) & 1) << (intCnt*8 + 7-intCn2);
					intCn2++;
					if (intCn2 >= 8) {
						intCn2=0;
						intCnt++;
					}
					s_length[waveNo]++;
					if (intCnt >= 4) {
						intCnt = 0;
						intPos++;
						if(intPos >= FC_DPCM_TABLE_MAX_LEN){
							intPos = FC_DPCM_TABLE_MAX_LEN-1;
						}
					}
				}
            }
			//レングス中途半端な場合、削る
			s_length[waveNo] -= ((s_length[waveNo] - 8) % 0x80);
			//最大・最小サイズ調整
			if (s_length[waveNo] > FC_DPCM_MAX_LEN * 8) {
				s_length[waveNo] = FC_DPCM_MAX_LEN * 8;
			}
			if (s_length[waveNo] == 0) {
				s_length[waveNo] = 8;
			}
			//長さが指定されていれば、それを格納
			//if (length >= 0) s_length[waveNo] = (length * 0x10 + 1) * 8;

        }
        public override function setWaveNo(waveNo:int):void {
            if (waveNo >= MAX_WAVE) waveNo = MAX_WAVE-1;
            if (!s_table[waveNo]) waveNo = 0;
            m_waveNo = waveNo;
        }
        private function getValue():Number {
			if (m_length > 0) {
				if ((s_table[m_waveNo][m_address] >> m_bit) & 1) {
					if (m_wav < 126) m_wav += 2;
				}else {
					if (m_wav > 1)   m_wav-=2;
				}
				m_bit++;
				if (m_bit >= 32) {
					m_bit = 0;
					m_address++;
				}
				m_length--;
				if (m_length == 0) {
					if (s_loopFg[m_waveNo]) {
						m_address = 0;
						m_bit = 0;
						m_length = s_length[m_waveNo];
					}
				}
				return (m_wav-64)/64.0;
			}else {
				return (m_wav-64)/64.0;
			}
        }
        public override function resetPhase():void {
            m_phase = 0;
			m_address = 0;
			m_bit = 0;
			m_ofs = 0;
			m_wav = s_intVol[m_waveNo];
			m_length = s_length[m_waveNo];
			
        }
        public override function getNextSample():Number {
            var val:Number = (m_wav-64)/64.0;
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
			while (FC_DPCM_NEXT <= m_phase) {
				m_phase -= FC_DPCM_NEXT;
				//CPU負荷軽減のため
				//val = getValue();
				{
					if (m_length > 0) {
						if ((s_table[m_waveNo][m_address] >> m_bit) & 1) {
							if (m_wav < 126) m_wav += 2;
						}else {
							if (m_wav > 1)   m_wav-=2;
						}
						m_bit++;
						if (m_bit >= 32) {
							m_bit = 0;
							m_address++;
						}
						m_length--;
						if (m_length == 0) {
							if (s_loopFg[m_waveNo]) {
								m_address = 0;
								m_bit = 0;
								m_length = s_length[m_waveNo];
							}
						}
						val = (m_wav-64)/64.0;
					}else {
						val = (m_wav-64)/64.0;
					}
				}
			}
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = (m_wav-64)/64.0;
            m_phase = (m_phase + m_freqShift + ((ofs - m_ofs) >> (PHASE_SFT - 7))) & PHASE_MSK;
			while (FC_DPCM_NEXT <= m_phase) {
				m_phase -= FC_DPCM_NEXT;
				//CPU負荷軽減のため
				//val = getValue();
				{
					if (m_length > 0) {
						if ((s_table[m_waveNo][m_address] >> m_bit) & 1) {
							if (m_wav < 126) m_wav += 2;
						}else {
							if (m_wav > 1)   m_wav-=2;
						}
						m_bit++;
						if (m_bit >= 32) {
							m_bit = 0;
							m_address++;
						}
						m_length--;
						if (m_length == 0) {
							if (s_loopFg[m_waveNo]) {
								m_address = 0;
								m_bit = 0;
								m_length = s_length[m_waveNo];
							}
						}
						val = (m_wav-64)/64.0;
					}else {
						val = (m_wav-64)/64.0;
					}
				}
			}
			m_ofs = ofs;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
            var val:Number = (m_wav-64)/64.0;
            for(i = start; i < end; i++) {
				m_phase = (m_phase + m_freqShift) & PHASE_MSK;
				while (FC_DPCM_NEXT <= m_phase) {
					m_phase -= FC_DPCM_NEXT;
					//CPU負荷軽減のため
					//val = getValue();
					{
						if (m_length > 0) {
							if ((s_table[m_waveNo][m_address] >> m_bit) & 1) {
								if (m_wav < 126) m_wav += 2;
							}else {
								if (m_wav > 1)   m_wav-=2;
							}
							m_bit++;
							if (m_bit >= 32) {
								m_bit = 0;
								m_address++;
							}
							m_length--;
							if (m_length == 0) {
								if (s_loopFg[m_waveNo]) {
									m_address = 0;
									m_bit = 0;
									m_length = s_length[m_waveNo];
								}
							}
							val = (m_wav-64)/64.0;
						}else {
							val = (m_wav-64)/64.0;
						}
					}
				}
                samples[i] = val;
            }
        }
        public override function setFrequency(frequency:Number):void {
            //m_frequency = frequency;
            m_freqShift = frequency * (1 << (FC_DPCM_PHASE_SFT+4)); // as interval
        }
        public function setDpcmFreq(no:int):void {
            if (no < 0) no = 0;
            if (no > 15) no = 15;
            m_freqShift = (FC_CPU_CYCLE << FC_DPCM_PHASE_SFT) / s_interval[no]; // as interval
        }
        public override function setNoteNo(noteNo:int):void {
            setDpcmFreq(noteNo);
        }		
    }
}