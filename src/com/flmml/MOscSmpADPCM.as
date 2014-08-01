package com.flmml {
	import __AS3__.vec.Vector;
	
	public class MOscSmpADPCM extends MOscMod {
		public static const MAX_WAVE:int = 128;
		public static const MAX_LENGTH:int = 1024 * 1024 * 2;
		public static const MAX_TABLE_LEN:int = (MAX_LENGTH >> 2) + 4;
		public static const ADPTYPE_YM:int = 0;
		public static const ADPTYPE_MSM:int = 1;
		protected static var s_init:int = 0;
		protected static var s_table:Vector.<Vector.<uint>>;
		protected static var s_sFreq:Vector.<Number>;	//サンプリング周波数
		protected static var s_loopPt:Vector.<int>;		//ループポイント
		protected static var s_length:Vector.<int>;		//再生レングス。１サンプル８ビットでサンプル数を持つ。
		protected static var s_adpType:Vector.<int>;	//ADPCM Type。0:YM mode, 1:MSM mode
		protected static var s_ReleaseMode:int = 3;		//終端リリース処理モード。0:変位維持, 1以上:変位０までのステップ数
		
		protected static var s_YM_tbl1:Vector.<int> = Vector.<int>([
			1,   3,   5,   7,   9,  11,  13,  15,
			-1,  -3,  -5,  -7,  -9, -11, -13, -15,
		]);
		protected static var s_YM_tbl2:Vector.<int> = Vector.<int>([
			57,  57,  57,  57,  77, 102, 128, 153,
			57,  57,  57,  57,  77, 102, 128, 153,
		]);
		protected static var s_YM_adpcmX:int;
		protected static var s_YM_adpcmD:int;
		
		protected static var s_MSM_IndexShift:Vector.<int> = Vector.<int>([
			-1, -1, -1, -1, 2, 4, 6, 8,
		]);
		protected static var s_MSM_DiffLookup:Vector.<int>;
		protected static var s_MSM_signal:int;
		protected static var s_MSM_step:int;
		
		protected var m_waveNo:int;
		protected var m_renderingMode:int;
		protected var m_getNextSample:Function;
		protected var m_interval:Number;
		protected var m_position:Number;
		protected var m_amp:Number;
		protected var m_address:int = 0;			//読み込み中のアドレス位置
		protected var m_bit:int = 0;				//読み込み中のビット位置
		protected var m_wav:Number = 0.0;			//現在の変位
		protected var m_length:int = 0;				//残りサンプル数
		protected var m_NextWav:Number = 0.0;		//次回の変位
		protected var m_NextDiff:Number = 0.0;		//次回変位への差分
		protected var m_ReleaseMode:int = 0;		//終端リリース処理モード
		protected var m_ReleaseLeft:int = 0;		//終端リリースシーケンス残り回数
		protected var m_ReleaseDiff:Number = 0.0;	//終端リリースの変位差分
		
		public function MOscSmpADPCM() {
			boot();
			m_modID = MOscillator.SMP_ADPCM;
			super();
			setWaveNo(0);
			setRenderFunc(1);
			setFrequency(440.0);
			setReleaseModeValue(s_ReleaseMode);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_table = new Vector.<Vector.<uint>>(MAX_WAVE);
			s_sFreq = new Vector.<Number>(MAX_WAVE);
			s_loopPt = new Vector.<int>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
			s_adpType = new Vector.<int>(MAX_WAVE);
			s_MSM_DiffLookup = new Vector.<int>(49*16);
			initMSMtable();
			setWave(0, 11025.0, 48, -1, ADPTYPE_YM, "8080808080808080");
			s_init = 1;
		}
		private static function initMSMtable():void {
			var step:int, stepval:int, nib:int;
			for (step = 0; step <= 48; step++) {
				stepval = Math.floor(16.0 * Math.pow(1.1, Number(step)));
				for (nib = 0; nib < 16; nib++) {
					s_MSM_DiffLookup[(step*16) + nib] = 
						getNP(nib & 0x08) *
						(
							( stepval    * getZP(nib & 0x04)) +
							((stepval/2) * getZP(nib & 0x02)) +
							((stepval/4) * getZP(nib & 0x01)) +
							( stepval/8 )
						);
				}
			}
		}
		private static function getNP(n:int):int {
			return (n == 0) ? 1 : (-1);
		}
		private static function getZP(n:int):int {
			return (n == 0) ? 0 : (1);
		}
		private static function limitNumI(l1:int, l2:int, num:int):int {
			var n:int = num;
			if (n < l1) n = l1;
			if (n > l2) n = l2;
			return n;
		}
		public static function setWave(waveNo:int, sFreq:Number, sKey:int, loopPt:int, decMode:int, wave:String):void {
			var basefreq:Number = (MChannel.s_BaseFreq) * Math.pow(2.0, ( (Number(sKey) - (MChannel.s_BaseNote) ) / (12.0) ) );
			s_sFreq[waveNo]  = sFreq / basefreq;
			s_loopPt[waveNo] = loopPt;
			s_length[waveNo] = 0;
			switch (decMode) {
			case 0:
				s_adpType[waveNo] = ADPTYPE_YM;
				decodePlaintext(waveNo, ADPTYPE_YM, wave);
				break;
			case 1:
				s_adpType[waveNo] = ADPTYPE_YM;
				decodeBase64(waveNo, ADPTYPE_YM, wave);
				break;
			case 10:
				s_adpType[waveNo] = ADPTYPE_MSM;
				decodePlaintext(waveNo, ADPTYPE_MSM, wave);
				break;
			case 11:
				s_adpType[waveNo] = ADPTYPE_MSM;
				decodeBase64(waveNo, ADPTYPE_MSM, wave);
				break;
			default:
				s_adpType[waveNo] = ADPTYPE_YM;
				break;
			}
			if ((s_loopPt[waveNo] >= 0) && (s_loopPt[waveNo] >= s_length[waveNo])) s_loopPt[waveNo] = s_length[waveNo] - 1;
		}
		private static function initAdpcmDecodeVar():void {
			s_YM_adpcmX = 0;
			s_YM_adpcmD = 127;
			s_MSM_signal = 0;
			s_MSM_step = 0;
		}
		private static function decodeAdpcm(adp:int, mode:int):int {
			var pcm:int;
			var adpcm:int = (adp & 15);
			if (mode == ADPTYPE_YM) {
				//正数の切り捨ては０に近い方、負数の切り捨ても０に近い方。
				s_YM_adpcmX = limitNumI(-32768, 32767, (s_YM_adpcmX + ((s_YM_tbl1[adpcm] * s_YM_adpcmD) / 8)) );
				s_YM_adpcmD = limitNumI(   127, 24576, ((s_YM_adpcmD * s_YM_tbl2[adpcm]) / 64) );
				pcm = s_YM_adpcmX & 0x0ffff;
			}
			else {
				s_MSM_signal = limitNumI(-2048, 2047, (s_MSM_signal + s_MSM_DiffLookup[(s_MSM_step * 16) + adpcm]) );
				s_MSM_step   = limitNumI(    0,   48, (s_MSM_step + s_MSM_IndexShift[(adpcm & 7)]) );
				pcm = s_MSM_signal & 0x0ffff;
			}
			return pcm;
		}
		private static function decodeBase64(waveNo:int, mode:int, wave:String):void {
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			var maxLen:int;
			var code:int;
			var adpcm:int = 0;
			var i:int;
			maxLen = (((wave.length * 6) / 8) + 8);		// 全体のbit数はlength*6、中身は4bit/sampleで、16bit/sampleを32bitのuint配列に。要素数は((文字数*6/4)*16/32)+保険(8)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (i = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}
			initAdpcmDecodeVar();
			
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
				//抽出した6bitを1bitずつ処理。
				for(i = 5; i >=0 ; i--) {
					adpcm += ((code >> i) & 1) << (3 - intCn2);
					intCn2++;
					if (intCn2 >= 4) {
						s_table[waveNo][intPos] += ( decodeAdpcm(adpcm, mode) << intCnt );
						adpcm = 0;
						intCn2 = 0;
						intCnt += 16;
						s_length[waveNo]++;			// 4bitごとに１サンプル
					}
					if (intCnt >= 32) {
						intCnt = 0;
						intPos++;
						if(intPos >= maxLen){
							intPos = maxLen-1;
						}
					}
				}
			}
		}
		private static function decodePlaintext(waveNo:int, mode:int, wave:String):void {
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			var maxLen:int;
			var code:int;
			var adpcm:int = 0;
			var i:int;
			maxLen = (((wave.length * 4) / 8) + 8);		// 全体のbit数はlength*4、中身は4bit/sampleで、16bit/sampleを32bitのuint配列に。要素数は((文字数*4/4)*16/32)+保険(8)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (i = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}
			initAdpcmDecodeVar();
			
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
				//抽出した4bitを1bitずつ処理。
				for(i = 3; i >=0 ; i--) {
					adpcm += ((code >> i) & 1) << (3 - intCn2);
					intCn2++;
					if (intCn2 >= 4) {
						s_table[waveNo][intPos] += ( decodeAdpcm(adpcm, mode) << intCnt );
						adpcm = 0;
						intCn2 = 0;
						intCnt += 16;
						s_length[waveNo]++;			// 4bitごとに１サンプル
					}
					if (intCnt >= 32) {
						intCnt = 0;
						intPos++;
						if(intPos >= maxLen){
							intPos = maxLen-1;
						}
					}
				}
			}
		}
		private function setReleaseModeValue(rmode:int):void {
			if (rmode < 1) {
				m_ReleaseMode = 0;
				stopRelease();
			}
			else {
				m_ReleaseMode = rmode;
				stopRelease();
			}
		}
		private function stopRelease():void {
			m_ReleaseLeft = 0;
			m_ReleaseDiff = 0.0;
		}
		private function prepareNextValue():void {
			var val:int;
			if (m_length > 0) {
				val = (s_table[m_waveNo][m_address] >> m_bit) & 0x0ffff;
				if ((val & 0x08000) != 0) {
					val |= 0xffff0000;
				}
				m_NextWav = Number(val) / m_amp;
				m_NextDiff = m_NextWav - m_wav;
			}
		}
		private function getValue():Number {
			if (m_length > 0) {
				m_wav = m_NextWav;
				m_length--;
				if (m_length > 0) {
					//残りがある場合はポインタを進める
					m_bit += 16;
					if (m_bit >= 32) {
						m_bit = 0;
						m_address++;
					}
					prepareNextValue();
				}
				else {
					//残りが無い場合はループ処理もしくは終端処理
					if (s_loopPt[m_waveNo] >= 0) {
						m_address = (s_loopPt[m_waveNo] >> 1);
						m_bit = (s_loopPt[m_waveNo] % 2) * 16;
						m_length = s_length[m_waveNo] - s_loopPt[m_waveNo];
						prepareNextValue();
					}
					else {
						m_NextWav = m_wav;		//終端値の継続
						m_NextDiff = 0.0;
					}
				}
			}
			else if (m_length == 0) {
				if (m_ReleaseMode > 0) {
					//変位終端のリリースシーケンスモード
					m_length = (-1);
					m_ReleaseLeft = m_ReleaseMode;
					m_ReleaseDiff = (0.0 - m_wav) / Number(m_ReleaseMode);
				}
				else {
					//変位終端値の継続モード
					m_length = (-2);
					stopRelease();
				}
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
			stopRelease();
		}
		private function getNextSample0():Number {
			var val:Number = m_wav;
			m_position = m_position + m_interval;
			while (m_position >= 1.0) {
				m_position -= 1.0;
				val = getValue();
			}
			//変位終端のリリースシーケンス要求に応じて処理
			if (m_length == (-1)) {
				if (m_ReleaseLeft > 0) {
					m_ReleaseLeft--;
					m_wav += m_ReleaseDiff;
				}
				else {
					m_length = (-2);
				}
			}
			return val;
		}
		private function getNextSample1():Number {
			var val:Number = m_wav;
			m_position += m_interval;
			if (m_interval < 1.0) {
				//44.1kHz未満の場合のみ線形補完を考慮する手順
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
			//変位終端のリリースシーケンス要求に応じて処理
			if (m_length == (-1)) {
				if (m_ReleaseLeft > 0) {
					m_ReleaseLeft--;
					m_wav += m_ReleaseDiff;
				}
				else {
					m_length = (-2);
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
			if (s_adpType[m_waveNo] == ADPTYPE_YM) {
				m_amp = 32768.0;
			}
			else if (s_adpType[m_waveNo] == ADPTYPE_MSM) {
				m_amp = 2048.0;
			}
			else {
				m_amp = 32768.0;
			}
			resetPhase();		//resetPhase() は m_amp 確定後に呼ぶ
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
			case 5:		//sp.func.5: setReleaseModeValue
				setReleaseModeValue(int(n));
				break;
			}
		}
	}
}