package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscSmpU8PCM extends MOscMod {
		public static const MAX_WAVE:int = 128;
		public static const MAX_LENGTH:int = 1024 * 1024 * 2;
		public static const MAX_TABLE_LEN:int = (MAX_LENGTH >> 2) + 4;
		protected static var s_init:int = 0;
		protected static var s_table:Vector.<Vector.<uint>>;
		protected static var s_sFreq:Vector.<Number>;	//サンプリング周波数
		protected static var s_loopPt:Vector.<int>;		//ループポイント
		protected static var s_length:Vector.<int>;		//再生レングス。１サンプル８ビットでサンプル数を持つ。
		protected var m_waveNo:int;
		protected var m_renderingMode:int;
		protected var m_getNextSample:Function;
		protected var m_interval:Number;
		protected var m_position:Number;
		protected var m_address:int = 0;		//読み込み中のアドレス位置
		protected var m_bit:int = 0;			//読み込み中のビット位置
		protected var m_wav:Number = 0.0;		//現在の変位
		protected var m_length:int = 0;			//残り読み込み長
		protected var m_NextWav:Number = 0.0;	//次回の変位
		protected var m_NextDiff:Number = 0.0;	//次回変位への差分
		
		public function MOscSmpU8PCM() {
			boot();
			m_modID = MOscillator.SMP_U8PCM;
			super();
			setWaveNo(0);
			setRenderFunc(1);
			setFrequency(440.0);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_table = new Vector.<Vector.<uint>>(MAX_WAVE);
			s_sFreq = new Vector.<Number>(MAX_WAVE);
			s_loopPt = new Vector.<int>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
			setWave(0, 11025.0, 57, -1, 0, "8080808080808080");
			s_init = 1;
		}
		public static function setWave(waveNo:int, sFreq:Number, sKey:int, loopPt:int, decMode:int, wave:String):void {
			var basefreq:Number = (MChannel.s_BaseFreq) * Math.pow(2.0, ( (Number(sKey) - (MChannel.s_BaseNote) ) / (12.0) ) );
			s_sFreq[waveNo]  = sFreq / basefreq;
			s_loopPt[waveNo] = loopPt;
			s_length[waveNo] = 0;
			
			if (decMode == 1) {
				decodeBase64(waveNo, wave);
			}
			else {
				decodePlaintext(waveNo, wave);
			}
			
			if ((s_loopPt[waveNo] >= 0) && (s_loopPt[waveNo] >= s_length[waveNo])) s_loopPt[waveNo] = s_length[waveNo] - 1;
		}
		private static function decodeBase64(waveNo:int, wave:String):void {
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			var maxLen:int;
			var code:int;
			var i:int;
			maxLen = (((wave.length * 3) >> 4) + 4);		//全体のbit数はlength*6、中身は8bit/sampleで、8bit/sampleを32bitのuint配列に。要素数は((文字数*6/8)*8/32)+保険(4)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (i = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}

			for(strCnt = 0; strCnt < wave.length; strCnt++) {
				code = wave.charCodeAt(strCnt);
				if ((0x41 <= code) && (code <= 0x5a)) { //A-Z
					code -= 0x41;
				}
				else if((0x61 <= code) && (code <= 0x7a)) { //a-z
					code -= 0x61-26;
				}
				else if((0x30 <= code) && (code <= 0x39)) { //0-9
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
				//抽出した6bitを1bitずつ積む。バイトオーダーはリトルエンディアン
				for(i = 5; i >=0 ; i--) {
					s_table[waveNo][intPos] += ((code >> i) & 1) << (intCnt*8 + 7-intCn2);
					intCn2++;
					if (intCn2 >= 8) {
						intCn2=0;
						intCnt++;
						s_length[waveNo]++;			// 8bitごとに１サンプル
					}
					if (intCnt >= 4) {
						intCnt = 0;
						intPos++;
						if(intPos >= maxLen){
							intPos = maxLen-1;
						}
					}
				}
			}
		}
		private static function decodePlaintext(waveNo:int, wave:String):void {
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			var maxLen:int;
			var code:int;
			var i:int;
			maxLen = (((wave.length * 2) >> 4) + 4);		//全体のbit数はlength*4、中身は8bit/sampleで、8bit/sampleを32bitのuint配列に。要素数は((文字数*4/8)*8/32)+保険(4)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (i = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}

			for(strCnt = 0; strCnt < wave.length; strCnt++) {
				code = wave.charCodeAt(strCnt);
				if ((0x41 <= code) && (code <= 0x46)) { //A-F
					code -= (0x41-10);
				}
				else if ((0x61 <= code) && (code <= 0x7a)) { //a-f
					code -= (0x61-10);
				}
				else if ((0x30 <= code) && (code <= 0x39)) { //0-9
					code -= 0x30;
				}
				else {
					code = 0;
				}
				//抽出した4bitを1bitずつ積む。バイトオーダーはリトルエンディアン
				for(i = 3; i >= 0 ; i--) {
					s_table[waveNo][intPos] += ((code >> i) & 1) << (intCnt*8 + 7-intCn2);
					intCn2++;
					if (intCn2 >= 8) {
						intCn2=0;
						intCnt++;
						s_length[waveNo]++;			// 8bitごとに１サンプル
					}
					if (intCnt >= 4) {
						intCnt = 0;
						intPos++;
						if(intPos >= maxLen){
							intPos = maxLen-1;
						}
					}
				}
			}
		}
		private function prepareNextValue():void {
			var val:int;
			if (m_length > 0) {
				val = (s_table[m_waveNo][m_address] >> m_bit) & 0x0ff;
				m_NextWav = (Number(val) / 127.5) - 1.0;
				m_NextDiff = m_NextWav - m_wav;
			}
		}
		private function getValue():Number {
			var val:int;
			if (m_length > 0) {
				m_wav = m_NextWav;
				m_length--;
				if (m_length > 0) {
					//残りがある場合はポインタを進める
					m_bit += 8;
					if (m_bit >= 32) {
						m_bit = 0;
						m_address++;
					}
				}
				else {
					//残りが無い場合はループ時の更新と線形補完用差分のクリア
					if (s_loopPt[m_waveNo] >= 0) {
						m_address = (s_loopPt[m_waveNo] >> 2);
						m_bit = (s_loopPt[m_waveNo] % 4) * 8;
						m_length = s_length[m_waveNo] - s_loopPt[m_waveNo];
					}
					else {
						m_wav = 0.0;
					}
					m_NextDiff = 0.0;
				}
				prepareNextValue();
			}
			return m_wav;
		}
		public override function resetPhase():void {
			m_position = 0;
			m_address = 0;
			m_bit = 0;
			m_wav = 0.0;
			m_length = s_length[m_waveNo];
			prepareNextValue();
		}
		private function getNextSample0():Number {
			var val:Number = m_wav;
			m_position = m_position + m_interval;
			while (m_position >= 1.0) {
				m_position -= 1.0;
				val = getValue();
			}
			return val;
		}
		private function getNextSample1():Number {
			var val:Number = m_wav;
			m_position += m_interval;
			if (m_interval < 1.0) {
				if (m_position >= 1.0) {
					m_position -= 1.0;
					val = getValue();
				}
				val = val + (m_position * m_NextDiff);		//線形補完
			}
			else {
				while (m_position >= 1.0) {
					m_position -= 1.0;
					val = getValue();
				}
			}
			return val;
		}
		public override function getNextSample():Number {
			return m_getNextSample();
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		public override function setFrequency(frequency:Number):void {
			m_frequency = frequency;
			m_freqShift = frequency / 44100.0;
			m_interval = (s_sFreq[m_waveNo] / 44100.0) * m_frequency;	// as interval
		}
		public function setRenderFunc(mode:int):void {
			var n:int = mode;
			switch(mode) {
				case 0:
					m_getNextSample = getNextSample0;	//０次補完モード
					break;
				default:
					n = 1;								//規定外指定は１番指定に矯正
				case 1:
					m_getNextSample = getNextSample1;	//１次補完モード
					break;
			}
			m_renderingMode = n;
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (n >= MAX_WAVE) n = MAX_WAVE-1;
			if (n < 0) n = 0;
			if (s_table[n] == null) n = 0;		//未定義波形番号へのリクエストは０番に矯正
			m_waveNo = n;
			resetPhase();
		}
		public override function setYControl(m:int, f:int, n:Number):void {
			if (m_modID != m) return;
			switch (f) {
				default:
				case 0:		//func.0: No Operation
					break;
				case 1:		//func.1: setWaveNo
					setWaveNo(int(n));
					break;
				case 2:		//func.2: setRenderFunc
					setRenderFunc(int(n));
					break;
				case 3:		//func.3: setDetune
					break;
				case 4:		//func.4: reserved
					break;
			}
		}
	}
}