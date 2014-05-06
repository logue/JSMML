package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscWaveMem extends MOscMod {
		public static const MAX_WAVE:int = 64;
		public static const MAX_LENGTH:int = 1024;
		public static var s_OverSmpMultiple:Number = 4.0;			//オーバーサンプリングのデフォルト倍率をMML.asから受け取る。
		
		protected static var s_init:int = 0;
		protected static var s_table:Vector.<Vector.<Number>>;
		protected static var s_length:Vector.<int>;
		
		private static const MAX_EXOP:int  = 4;
		private static const OP_DETUNE:int = 0;
		private static const OP_FREQ:int   = 1;
		private static const OP_FSHIFT:int = 2;
		private static const OP_PHASE:int  = 3;
		private static const OP_AMP:int    = 4;
		private static const OP_VAL:int    = 5;
		private static const OP_MAX:int    = 6;
		
		private static const DEF_DETUNE:Number = 8.0;
		private static const DEF_DT_MAX:Number = 3600.0;
		private static const DEF_DT_MIN:Number = -3600.0;
		private static const DEF_LV_MIN:Number = -60.0;
		
		protected var m_waveNo:int;
		protected var m_renderingMode:int;
		protected var m_getValue:Function;
		protected var m_op:Vector.<Vector.<Number>>;
		protected var m_detune:Number;
		protected var m_ampDenom:Number;
		protected var m_val:Number;
		protected var m_OvSmpMul:Number;
		protected var m_detune_mode:Boolean;

		public function MOscWaveMem() {
			boot();
			m_modID = MOscillator.WAVEMEM;
			//オペレータ領域確保
			m_op = newVect2DN(MAX_EXOP, OP_MAX);
			//初期関数のセット
			m_waveNo = 0;
			m_renderingMode = 0;
			m_getValue = getValueW0;
			m_OvSmpMul = s_OverSmpMultiple;
			//初期変数のセット
			m_detune = DEF_DETUNE;
			m_val = 0.0;
			//初期設定
			initOp();
			super();
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_table = new Vector.<Vector.<Number>>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
			//               01234567890123456789012345678901
			setWave1c(0, 4, "89abcdeffedcba987654321001234567");
			s_init = 1;
		}
		private function initOp():void {
			var i:int;
			for (i = 0; i < MAX_EXOP; i++) {
				m_op[i][OP_DETUNE] = 0.0;
				m_op[i][OP_FREQ]   = 440.0;
				m_op[i][OP_FSHIFT] = m_op[i][OP_FREQ] / 44100.0;
				m_op[i][OP_PHASE]  = 0.0;
				m_op[i][OP_AMP]    = 1.0;
				m_op[i][OP_VAL]    = 0.0;
			}
			m_ampDenom = 1.0;
			setDetune(m_detune);
		}
		private function newVect2DN(d1:int, d2:int):Vector.<Vector.<Number>> {
			var a:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(d1);
			for (var i:int = 0; i < d1; i++) {
				a[i] = new Vector.<Number>(d2);
			}
			return a;
		}
		public static function setWave1c(waveNo:int, bWidth:int, waveStr:String):void {
			//trace("["+waveNo+"]"+waveStr);
			var w:int;
			var nval:Number;
			var denom:Number;
			if (bWidth < 1) w = 1;
			else if (bWidth > 4) w = 4;
			else w = bWidth;
			denom = Number((1 << w) - 1);
			s_length[waveNo] = 0;
			s_table[waveNo] = new Vector.<Number>(waveStr.length);
			s_table[waveNo][0] = 0.0;
			for(var i:int = 0; (i < MAX_LENGTH) && (i < waveStr.length); i++) {
				var code:int = waveStr.charCodeAt(i);
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
				nval = (((Number(code) / denom) * 2.0) - 1.0);
				if (nval >  1.0) nval =  1.0;
				if (nval < -1.0) nval = -1.0;
				s_table[waveNo][i] = nval;
				s_length[waveNo] += 1;
			}
		}
		public static function setWave2c(waveNo:int, bWidth:int, waveStr:String):void {
			//trace("["+waveNo+"]"+waveStr);
			var i:int;
			var j:int;
			var val:int;
			var w:int;
			var nval:Number;
			var denom:Number;
			if (bWidth < 1) w = 1;
			else if (bWidth > 8) w = 8;
			else w = bWidth;
			denom = Number((1 << w) - 1);
			s_length[waveNo] = 0;
			s_table[waveNo] = new Vector.<Number>(waveStr.length/2);
			s_table[waveNo][0] = 0.0;
			for(i=0, j=0, val=0; (i < (MAX_LENGTH*2)) && (i < waveStr.length); i++, j++) {
				var code:int = waveStr.charCodeAt(i);
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
				if( j & 1 ){
					val += code;
					nval = (((Number(val) / denom) * 2.0) - 1.0);
					if (nval >  1.0) nval =  1.0;
					if (nval < -1.0) nval = -1.0;
					s_table[waveNo][s_length[waveNo]] = nval;
					s_length[waveNo] += 1;
				}else{
					val = code << 4;
				}
			}
			if (s_length[waveNo] == 0) s_length[waveNo] = 1;
		}
		
		// Operator Func.----------------------------------
		private function resetPhaseExecOP(op:Vector.<Number>):void {
			if (m_phaseResetPoint >= 0.0) {
				op[OP_PHASE] = m_phaseResetPoint;
			}
			else {
				op[OP_PHASE] = Math.random();
			}
		}
		
		private function getValueOP(op:Vector.<Number>):void {
			var i:int;
			var t:int = int(m_OvSmpMul);
			var val:Number;
			val = 0.0;
			//オーバーサンプリングし、相加平均を取る
			for (i = 0; i < t; i++) {
				val += s_table[m_waveNo][ int(op[OP_PHASE] * Number(s_length[m_waveNo])) ];
				shiftPhaseOP(op);
			}
			op[OP_VAL] = val / m_OvSmpMul;
		}
		
		private function shiftPhaseOP(op:Vector.<Number>):void {
			if ( (op[OP_PHASE] + op[OP_FSHIFT]) >= 1.0 ) {
				op[OP_PHASE] = (op[OP_PHASE] + op[OP_FSHIFT]) % (1.0);
			}
			else {
				op[OP_PHASE] = (op[OP_PHASE] + op[OP_FSHIFT]);
			}
		}
		
		private function setFrequencyOP(op:Vector.<Number>, freq:Number):void {
			op[OP_FREQ] = freq * Math.pow(2.0, op[OP_DETUNE]/1200.0);
			op[OP_FSHIFT] = op[OP_FREQ] / 44100.0;
		}
		
		private function setDetuneOP(op:Vector.<Number>, detune:Number):void {
			op[OP_DETUNE] = detune;
		}
		
		private function setAmplvOP(op:Vector.<Number>, lv:Number):void {
			op[OP_AMP] = Math.pow(10.0, (lv/20.0));		//lv:dB
		}
		
		private function syncOperatorOP(op:Vector.<Number>):void {
			setFrequencyOP(op, m_frequency);
			resetPhaseExecOP(op);
		}
		// Operator Func. end -----------------------------
		
		
		private function getValueW0():void {
			getValueOP(m_op[0]);
			m_val = m_op[0][OP_VAL];
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW20():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			m_val = ((m_op[0][OP_VAL] * m_op[0][OP_AMP]) + (m_op[1][OP_VAL] * m_op[1][OP_AMP])) / m_ampDenom;
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW30():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			getValueOP(m_op[2]);
			m_val = (m_op[0][OP_VAL] + m_op[1][OP_VAL] + m_op[2][OP_VAL]) / 3.0;
			m_val = (
						(m_op[0][OP_VAL] * m_op[0][OP_AMP]) +
						(m_op[1][OP_VAL] * m_op[1][OP_AMP]) +
						(m_op[2][OP_VAL] * m_op[2][OP_AMP])
					) / m_ampDenom;
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW40():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			getValueOP(m_op[2]);
			getValueOP(m_op[3]);
			m_val = (
						(m_op[0][OP_VAL] * m_op[0][OP_AMP]) +
						(m_op[1][OP_VAL] * m_op[1][OP_AMP]) +
						(m_op[2][OP_VAL] * m_op[2][OP_AMP]) +
						(m_op[3][OP_VAL] * m_op[3][OP_AMP])
					) / m_ampDenom;
			m_phase = m_op[0][OP_PHASE];
		}
		
		
		public override function getNextSample():Number {
			m_getValue();
			return m_val;
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for (i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		
		
		public override function setFrequency(frequency:Number):void {
			m_frequency = frequency / m_OvSmpMul;						//オーバーサンプリングに備える
			m_freqShift = m_frequency / 44100.0;
			var i:int;
			for (i=0; i<MAX_EXOP; i++) {
				setFrequencyOP(m_op[i], m_frequency);
			}
		}
		public override function resetPhaseExec():void {
			var i:int;
			for (i=0; i<MAX_EXOP; i++) {
				resetPhaseExecOP(m_op[i]);
			}
			m_phase = m_op[0][OP_PHASE];
		}
		public function setDetune(detune:Number):void {
			m_detune = limitNum(-100.0, 100.0, detune);
			setDetuneOP(m_op[0], 0.0);
			setDetuneOP(m_op[1], m_detune);
			setDetuneOP(m_op[2], (m_detune * (-1.0)));
			setDetuneOP(m_op[3], (m_detune / 2.0));
			setFrequency( m_frequency * m_OvSmpMul );			//オーバーサンプリング設定を考慮
		}
		private function refreshAmpDenom():void {
			switch (m_renderingMode) {
				default:
					m_ampDenom = 1.0;
					break;
				case 20:
					m_ampDenom = m_op[0][OP_AMP] + m_op[1][OP_AMP];
					break;
				case 30:
					m_ampDenom = m_op[0][OP_AMP] + m_op[1][OP_AMP] + m_op[2][OP_AMP];
					break;
				case 40:
					m_ampDenom = m_op[0][OP_AMP] + m_op[1][OP_AMP] + m_op[2][OP_AMP] + m_op[3][OP_AMP];
					break;
			}
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (n >= MAX_WAVE) n = MAX_WAVE-1;
			if (n < 0) n = 0;
			if (s_table[n] == null) n = 0;		//未定義波形番号へのリクエストは０番に矯正
			m_waveNo = n;
		}
		public function setRenderFunc(mode:int):void {
			var n:int = mode;
			if (m_renderingMode == n) return;		//同番号指定による再初期化防止
			
			switch(mode) {
			default:
				n = 0;								//規定外指定は０番指定に矯正
				if (m_renderingMode == n) return;	//過去０番だった時、同番号指定による再初期化防止
			case 0:
				m_getValue = getValueW0;
				break;
			case 20:
				m_getValue = getValueW20;
				break;
			case 30:
				m_getValue = getValueW30;
				break;
			case 40:
				m_getValue = getValueW40;
				break;
			}
			m_renderingMode = n;
			var i:int;
			for (i=0; i<MAX_EXOP; i++) {
				syncOperatorOP(m_op[i]);
			}
			refreshAmpDenom();
		}
		
		private function limitNum(min:Number, max:Number, n:Number):Number {
			if (n < min) return min;
			if (n > max) return max;
			return n;
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
				setDetune(n);
				break;
			case 4:		//func.4: reserved
				break;
			case 5:		//sp.func.5: Over Sampling Rate Setting
				var freq:Number;
				if ((n >= 1.0) && (n <= 10.0)) {
					freq = m_frequency * m_OvSmpMul;	//オリジナル周波数保存
					m_OvSmpMul = Math.floor(n);
					setFrequency(freq);					//新たなレートで内部周波数を再計算
				}
				break;
			case 10:	//sp.func.10: OP1-OP4 Detune/AmpLv reset
				setDetune(n);
				var i:int;
				for (i=0; i<MAX_EXOP; i++) {
					setAmplvOP(m_op[i], 0.0);
				}
				refreshAmpDenom();
				break;
			case 11:	//sp.func.11: OP1-Detune
				setDetuneOP(m_op[0], limitNum(DEF_DT_MIN, DEF_DT_MAX, n));
				break;
			case 12:	//sp.func.12: OP1-AmpLv
				setAmplvOP( m_op[0], limitNum(DEF_LV_MIN, 0.0, n));
				refreshAmpDenom();
				break;
			case 21:	//sp.func.21: OP2-Detune
				setDetuneOP(m_op[1], limitNum(DEF_DT_MIN, DEF_DT_MAX, n));
				break;
			case 22:	//sp.func.22: OP2-AmpLv
				setAmplvOP( m_op[1], limitNum(DEF_LV_MIN, 0.0, n));
				refreshAmpDenom();
				break;
			case 31:	//sp.func.31: OP3-Detune
				setDetuneOP(m_op[2], limitNum(DEF_DT_MIN, DEF_DT_MAX, n));
				break;
			case 32:	//sp.func.32: OP3-AmpLv
				setAmplvOP( m_op[2], limitNum(DEF_LV_MIN, 0.0, n));
				refreshAmpDenom();
				break;
			case 41:	//sp.func.41: OP4-Detune
				setDetuneOP(m_op[3], limitNum(DEF_DT_MIN, DEF_DT_MAX, n));
				break;
			case 42:	//sp.func.42: OP4-AmpLv
				setAmplvOP( m_op[3], limitNum(DEF_LV_MIN, 0.0, n));
				refreshAmpDenom();
				break;
			}
		}
	}
}
