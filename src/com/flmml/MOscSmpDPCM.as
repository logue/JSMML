package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscSmpDPCM extends MOscMod {
		public static const MAX_WAVE:int = 32;
		public static const FC_CPU_CYCLE:Number = (1789772.5 / 44100.0);
		public static const MAX_LENGTH:int = 0x0ff1;		//(0xff * 0x10) + 1 ファミコン準拠の最大レングス
		public static const MAX_TABLE_LEN:int = (MAX_LENGTH >> 2) + 4;
		protected static var s_init:int = 0;
		protected var m_address:int = 0;	//読み込み中のアドレス位置
		protected var m_bit:int = 0;		//読み込み中のビット位置
		protected var m_wav:int = 0;		//現在の変位
		protected var m_length:int = 0;		//残り読み込み長
		protected static var s_table:Vector.<Vector.<uint>>;
		protected static var s_intVol:Vector.<int>;		//波形初期位置
		protected static var s_loopFg:Vector.<int>;		//ループフラグ
		protected static var s_length:Vector.<int>;		//再生レングス。１サンプル１ビットでサンプル数を持つ。
		protected var m_waveNo:int;
		protected var m_interval:Number;
		protected var m_position:Number;
		//音程
		protected static var s_interval:Vector.<int> = Vector.<int>([
			428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106,  85,  72,  54,
		]);

		public function MOscSmpDPCM() {
			boot();
			m_modID = MOscillator.SMP_DPCM;
			super();
			setWaveNo(0);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_table = new Vector.<Vector.<uint>>(MAX_WAVE);
			s_intVol = new Vector.<int>(MAX_WAVE);
			s_loopFg = new Vector.<int>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
			setWave(0, 64, 0, 0, "55");
			s_init = 1;
		}
		public static function setWave(waveNo:int, intVol:int, loopFg:int, decMode:int, wave:String):void {
			s_intVol[waveNo] = intVol;
			s_loopFg[waveNo] = loopFg;
			s_length[waveNo] = 0;
			
			if (decMode == 1) {
				decodeBase64(waveNo, wave);
			}
			else {
				decodePlaintext(waveNo, wave);
			}

			//レングス中途半端な場合、削る
			s_length[waveNo] -= ((s_length[waveNo] - 8) % 0x80);
			//最大・最小サイズ調整
			if (s_length[waveNo] > MAX_LENGTH * 8) {
				s_length[waveNo] = MAX_LENGTH * 8;
			}
			if (s_length[waveNo] == 0) {
				s_length[waveNo] = 8;
			}
		}
		private static function decodeBase64(waveNo:int, wave:String):void {
			var strCnt:int = 0;
			var intCnt:int = 0;
			var intCn2:int = 0;
			var intPos:int = 0;
			var maxLen:int;
			maxLen = (((wave.length * 3) >> 4) + 4);		//１文字に6bitを１要素32bit長配列に。要素数を文字数*(6/8)/4+保険(4)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (var i:int = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}

			for(strCnt = 0; strCnt < wave.length; strCnt++) {
				var code:int = wave.charCodeAt(strCnt);
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
				//抽出した6bitを1bitずつ積む
				for(i = 5; i >=0 ; i--) {
					s_table[waveNo][intPos] += ((code >> i) & 1) << (intCnt*8 + 7-intCn2);
					intCn2++;
					if (intCn2 >= 8) {
						intCn2=0;
						intCnt++;
					}
					s_length[waveNo]++;			// 1bitごとに１サンプル
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
			maxLen = (((wave.length * 2) >> 4) + 4);		//１文字に4bitを１要素32bit長配列に。要素数を文字数*(4/8)/4+保険(4)に。
			if (maxLen > MAX_TABLE_LEN) maxLen = MAX_TABLE_LEN;
			s_table[waveNo] = new Vector.<uint>(maxLen);
			for (var i:int = 0; i < maxLen; i++) {
				s_table[waveNo][i] = 0;
			}

			for(strCnt = 0; strCnt < wave.length; strCnt++) {
				var code:int = wave.charCodeAt(strCnt);
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
				//抽出した4bitを1bitずつ積む
				for(i = 3; i >=0 ; i--) {
					s_table[waveNo][intPos] += ((code >> i) & 1) << (intCnt*8 + 7-intCn2);
					intCn2++;
					if (intCn2 >= 8) {
						intCn2=0;
						intCnt++;
					}
					s_length[waveNo]++;			// 1bitごとに１サンプル
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
		private function getValue():Number {
			if (m_length > 0) {
				if ((s_table[m_waveNo][m_address] >> m_bit) & 1) {
					if (m_wav < 126) m_wav += 2;
				}else {
					if (m_wav > 1)   m_wav -= 2;
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
			}
			return (Number(m_wav - 64) / 64.0);
		}
		public override function resetPhase():void {
			m_position = 0;
			m_address = 0;
			m_bit = 0;
			m_wav = s_intVol[m_waveNo];
			m_length = s_length[m_waveNo];
		}
		public override function getNextSample():Number {
			var val:Number = (Number(m_wav - 64) / 64.0);
			m_position = m_position + m_interval;
			while (m_position >= 1.0) {
				m_position -= 1.0;
				val = getValue();
			}
			return val;
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		public function setDpcmFreq(no:int):void {
			if (no < 0) no = 0;
			if (no > 15) no = 15;
			m_interval = FC_CPU_CYCLE / Number(s_interval[no]); // as interval
		}
		public override function setNoteNo(noteNo:int):void {
			setDpcmFreq(noteNo);
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (n >= MAX_WAVE) n = MAX_WAVE-1;
			if (n < 0) n = 0;
			if (s_table[n] == null) n = 0;		//未定義波形番号へのリクエストは０番に矯正
			m_waveNo = n;
		}
	}
}