package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscWaveMem extends MOscMod {
		public static const MAX_WAVE:int = 64;
		public static const MAX_LENGTH:int = 1024;
		public static var s_OverSmpMultiple:Number = 4.0;			//何倍オーバーサンプリングかを決定。2.0/4.0/8.0から選択して指定。
		
		protected static var s_init:int = 0;
		protected static var s_table:Vector.<Vector.<Number>>;
		protected static var s_length:Vector.<int>;
		
		private static const MAX_EXOP:int  = 3;
		private static const OP_DETUNE:int = 0;
		private static const OP_FREQ:int   = 1;
		private static const OP_FSHIFT:int = 2;
		private static const OP_PHASE:int  = 3;
		private static const OP_VAL:int    = 4;
		private static const OP_MAX:int    = 5;
		
		protected var m_waveNo:int;
		protected var m_renderingMode:int;
		protected var m_getValue:Function;
		protected var m_setFrequency:Function;
		protected var m_resetPhaseExec:Function;
		protected var m_op:Vector.<Vector.<Number>>;
		protected var m_detune:Number;
		protected var m_val:Number;

		public function MOscWaveMem() {
			boot();
			m_modID = MOscillator.WAVEMEM;
			//オペレータ領域確保
			m_op = newVect2DN(MAX_EXOP, OP_MAX);
			//初期関数のセット
			m_waveNo = 0;
			m_renderingMode = 0;
			m_getValue = getValueW0;
			m_setFrequency = setFrequencyW0;
			m_resetPhaseExec = resetPhaseExecW0;
			//初期変数のセット
			m_detune = 0.0;
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
			setFrequencyW30(440.0);			//全OP強制初期化
			setDetune(8.0);					//初期detuneは 8 cent
			for (i = 0; i < MAX_EXOP; i++) {
				m_op[i][OP_PHASE]  = 0.0;
				m_op[i][OP_VAL]    = 0.0;
			}
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
			var t:int = int(s_OverSmpMultiple);
			var val:Number;
			val = 0.0;
			//オーバーサンプリングし、相加平均を取る
			for (i = 0; i < t; i++) {
				val += s_table[m_waveNo][ int(op[OP_PHASE] * Number(s_length[m_waveNo])) ];
				shiftPhaseOP(op);
			}
			op[OP_VAL] = val / s_OverSmpMultiple;
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
		
		private function syncOperatorOP(op:Vector.<Number>):void {
			setFrequencyOP(op, m_frequency);
			resetPhaseExecOP(op);
		}
		// Operator Func. end -----------------------------
		
		private function resetPhaseExecW0():void {
			resetPhaseExecOP(m_op[0]);
			m_phase = m_op[0][OP_PHASE];
		}
		private function resetPhaseExecW20():void {
			resetPhaseExecOP(m_op[0]);
			resetPhaseExecOP(m_op[1]);
			m_phase = m_op[0][OP_PHASE];
		}
		private function resetPhaseExecW30():void {
			resetPhaseExecOP(m_op[0]);
			resetPhaseExecOP(m_op[1]);
			resetPhaseExecOP(m_op[2]);
			m_phase = m_op[0][OP_PHASE];
		}
		
		private function getValueW0():void {
			getValueOP(m_op[0]);
			m_val = m_op[0][OP_VAL];
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW20():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			m_val = (m_op[0][OP_VAL] + m_op[1][OP_VAL]) / 2.0;
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW30():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			getValueOP(m_op[2]);
			m_val = (m_op[0][OP_VAL] + m_op[1][OP_VAL] + m_op[2][OP_VAL]) / 3.0;
			m_phase = m_op[0][OP_PHASE];
		}
		
		private function setFrequencyW(frequency:Number):void {
			m_frequency = frequency / s_OverSmpMultiple;						//オーバーサンプリングに備える
			m_freqShift = m_frequency / 44100.0;
		}
		private function setFrequencyW0(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], m_frequency);
		}
		private function setFrequencyW20(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], m_frequency);
			setFrequencyOP(m_op[1], m_frequency);
		}
		private function setFrequencyW30(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], m_frequency);
			setFrequencyOP(m_op[1], m_frequency);
			setFrequencyOP(m_op[2], m_frequency);
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
			m_setFrequency(frequency);
		}
		public override function resetPhaseExec():void {
			m_resetPhaseExec();
		}
		public function setDetune(detune:Number):void {
			var d:int = detune;
			if (m_detune == detune) return;		//同値による再設定防止
			if (d >   100 ) d = 100;
			if (d < (-100)) d = (-100);
			m_detune = d;
			setDetuneOP(m_op[0], 0.0);
			setDetuneOP(m_op[1], m_detune);
			setDetuneOP(m_op[2], (m_detune * (-1)));
			setFrequencyW30(m_frequency);
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
				m_setFrequency = setFrequencyW0;
				m_resetPhaseExec = resetPhaseExecW0;
				break;
			case 20:
				m_getValue = getValueW20;
				m_setFrequency = setFrequencyW20;
				m_resetPhaseExec = resetPhaseExecW20;
				break;
			case 30:
				m_getValue = getValueW30;
				m_setFrequency = setFrequencyW30;
				m_resetPhaseExec = resetPhaseExecW30;
				break;
			}
			m_renderingMode = n;
			syncOperatorOP(m_op[0]);
			syncOperatorOP(m_op[1]);
			syncOperatorOP(m_op[2]);
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
			}
		}
	}
}
