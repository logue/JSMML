package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscPulse extends MOscMod {
		private static const MAX_EXOP:int  = 3;
		
		private static const OP_DETUNE:int = 0;
		private static const OP_FREQ:int   = 1;
		private static const OP_FSHIFT:int = 2;
		private static const OP_PHASE:int  = 3;
		private static const OP_PWM:int    = 4;
		private static const OP_PWMREQ:int = 5;
		private static const OP_NOW_V:int  = 6;
		private static const OP_OLD_V:int  = 7;
		private static const OP_VAL:int    = 8;
		private static const OP_MAX:int    = 9;
		
		protected static var s_init:int = 0;
		protected var m_waveNo:int;
		protected var m_getValue:Function;
		protected var m_setFrequency:Function;
		protected var m_setPWM:Function;
		protected var m_resetPhaseExec:Function;
		protected var m_op:Vector.<Vector.<Number>>;
		protected var m_pwm:Number;
		protected var m_detune:Number;
		protected var m_val:Number;
		protected var m_modNoise:MOscNoisePSG;

		public function MOscPulse() {
			boot();
			m_modID = MOscillator.PULSE;
			//オペレータ領域確保
			m_op = newVect2DN(MAX_EXOP, OP_MAX);
			//初期関数のセット
			m_waveNo = 0;
			m_getValue = getValueW0;
			m_setPWM = setPWMW0;
			m_setFrequency = setFrequencyW0;
			m_resetPhaseExec = resetPhaseExecW0;
			//初期変数のセット
			m_detune = 0.0;
			m_pwm = 0.5;
			m_val = 0.0;
			//初期設定
			initOp();
			super();
			setPhaseResetMode(0, -1.0);		//disable phase reset, and first-note-phase is random
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		private function initOp():void {
			var i:int;
			setFrequencyW30(440.0);			//全OP強制初期化
			setDetune(8.0);					//初期detuneは 8 cent
			for (i = 0; i < MAX_EXOP; i++) {
				m_op[i][OP_PHASE]  = 0.0;
				m_op[i][OP_PWM]    = 0.5;
				m_op[i][OP_PWMREQ] = 0.0;
				m_op[i][OP_NOW_V]  = 0.0;
				m_op[i][OP_OLD_V]  = 0.0;
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
		
		// Operator Func.----------------------------------
		private function resetPhaseExecOP(op:Vector.<Number>):void {
			if (m_phaseResetPoint >= 0.0) {
				op[OP_PHASE] = m_phaseResetPoint;
			}
			else {
				op[OP_PHASE] = Math.random();
			}
			
			//以下追加部分
			if (op[OP_PWMREQ] != 0.0) {
				op[OP_PWM] = op[OP_PWMREQ];
				op[OP_PWMREQ] = 0.0;
			}
			if (m_infoIsPlaying == true) {
				op[OP_OLD_V] = ( op[OP_OLD_V] + ((op[OP_PHASE] < op[OP_PWM]) ? 1.0 : -1.0) ) / 2.0;	//位相リセット直後の過去値をスタート値との中点にする
			}
			else {
				op[OP_OLD_V] = ( 0.0          + ((op[OP_PHASE] < op[OP_PWM]) ? 1.0 : -1.0) ) / 2.0;
			}
		}
		
		private function getValueOP(op:Vector.<Number>):void {
			
			op[OP_NOW_V] = (op[OP_PHASE] < op[OP_PWM]) ? 1.0 : -1.0;
			
			//変位m_oldsmpからm_nowsmpへの、１ステップ未満の端数位相（位置）での補完
			if (op[OP_OLD_V] == op[OP_NOW_V]) {
				op[OP_VAL] = op[OP_NOW_V];
			}
			else if (op[OP_PHASE] < op[OP_PWM]) {
				//位相スタート時点での２値切り替え時
				if ( op[OP_PHASE] < op[OP_FSHIFT] ) {
					op[OP_VAL] = ((op[OP_PHASE] / op[OP_FSHIFT]) * (op[OP_NOW_V] - op[OP_OLD_V])) + op[OP_OLD_V];
				}
				else {
					op[OP_VAL] = op[OP_NOW_V];
				}
			}
			else {
				//位相がm_pwm閾値を超えた時点での２値切り替え時
				if ( (op[OP_PHASE] - op[OP_PWM]) < op[OP_FSHIFT] ) {
					op[OP_VAL] = (((op[OP_PHASE] - op[OP_PWM]) / op[OP_FSHIFT]) * (op[OP_NOW_V] - op[OP_OLD_V])) + op[OP_OLD_V];
				}
				else {
					op[OP_VAL] = op[OP_NOW_V];
				}
			}
			op[OP_OLD_V] = op[OP_VAL];
			
			shiftPhaseOP(op);
		}
		
		private function shiftPhaseOP(op:Vector.<Number>):void {
			if ( (op[OP_PHASE] + op[OP_FSHIFT]) >= 1.0 ) {
				if (op[OP_PWMREQ] != 0.0) {
					op[OP_PWM] = op[OP_PWMREQ];
					op[OP_PWMREQ] = 0.0;
				}
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
		
		private function setPWMOP(op:Vector.<Number>, pwm:Number):void {
			op[OP_PWMREQ] = pwm;
		}
		
		private function syncOperatorOP(op:Vector.<Number>):void {
			setFrequencyOP(op, m_frequency);
			op[OP_PWMREQ] = m_pwm;
			op[OP_OLD_V] = 0.0;
			op[OP_NOW_V] = 0.0;
			op[OP_VAL]   = 0.0;
			resetPhaseExecOP(op);
		}
		// Operator Func. end -----------------------------
		
		private function resetPhaseExecW0():void {
			resetPhaseExecOP(m_op[0]);
			m_phase = m_op[0][OP_PHASE];
		}
		private function resetPhaseExecW1():void {
			resetPhaseExecOP(m_op[0]);
			m_phase = m_op[0][OP_PHASE];
		}
		private function resetPhaseExecW2():void {
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
		private function getValueW1():void {
			m_val = (m_op[0][OP_PHASE] < m_op[0][OP_PWM]) ? 1.0 : m_modNoise.getNextSample();
			shiftPhaseOP(m_op[0]);
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW2():void {
			m_val = m_modNoise.getNextSample();
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
			m_frequency = frequency;
			m_freqShift = frequency / 44100.0;
		}
		private function setFrequencyW0(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], frequency);
		}
		private function setFrequencyW1(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], frequency);
		}
		private function setFrequencyW2(frequency:Number):void {
			setFrequencyW(frequency);
		}
		private function setFrequencyW20(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], frequency);
			setFrequencyOP(m_op[1], frequency);
		}
		private function setFrequencyW30(frequency:Number):void {
			setFrequencyW(frequency);
			setFrequencyOP(m_op[0], frequency);
			setFrequencyOP(m_op[1], frequency);
			setFrequencyOP(m_op[2], frequency);
		}
		
		
		private function setPWMW(pwm:Number):void {
			var p:Number = pwm;
			if (p < 0.005) p = 0.005;
			if (p > 0.995) p = 0.995;
			m_pwm = p;
		}
		private function setPWMW0(pwm:Number):void {
			setPWMW(pwm);
			setPWMOP(m_op[0], m_pwm);
		}
		private function setPWMW1(pwm:Number):void {
			setPWMW(pwm);
			setPWMOP(m_op[0], m_pwm);
		}
		private function setPWMW2(pwm:Number):void {
			setPWMW(pwm);
		}
		private function setPWMW20(pwm:Number):void {
			setPWMW(pwm);
			setPWMOP(m_op[0], m_pwm);
			setPWMOP(m_op[1], m_pwm);
		}
		private function setPWMW30(pwm:Number):void {
			setPWMW(pwm);
			setPWMOP(m_op[0], m_pwm);
			setPWMOP(m_op[1], m_pwm);
			setPWMOP(m_op[2], m_pwm);
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
		public function setPWM(pwm:Number):void {
			m_setPWM(pwm);
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
		public function setNoiseModule(noise:MOscNoisePSG):void {
			m_modNoise = noise;
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (m_waveNo == n) return;			//同番号指定による再初期化防止
			
			switch(waveNo) {
			default:
				n = 0;							//規定外指定は０番指定に矯正
				if (m_waveNo == n) return;		//過去０番だった時、同番号指定による再初期化防止
			case 0:
				m_getValue = getValueW0;
				m_setPWM = setPWMW0;
				m_setFrequency = setFrequencyW0;
				m_resetPhaseExec = resetPhaseExecW0;
				break;
			case 1:
				m_getValue = getValueW1;
				m_setPWM = setPWMW1;
				m_setFrequency = setFrequencyW1;
				m_resetPhaseExec = resetPhaseExecW1;
				break;
			case 2:
				m_getValue = getValueW2;
				m_setPWM = setPWMW2;
				m_setFrequency = setFrequencyW2;
				m_resetPhaseExec = resetPhaseExecW2;
				break;
			case 20:
				m_getValue = getValueW20;
				m_setPWM = setPWMW20;
				m_setFrequency = setFrequencyW20;
				m_resetPhaseExec = resetPhaseExecW20;
				break;
			case 30:
				m_getValue = getValueW30;
				m_setPWM = setPWMW30;
				m_setFrequency = setFrequencyW30;
				m_resetPhaseExec = resetPhaseExecW30;
				break;
			}
			m_waveNo = n;
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
				setWaveNo(int(n));
				break;
			case 3:		//func.3: setDetune
				setDetune(n);
				break;
			case 4:		//func.4: reserved
				break;
			case 5:
				setPWM(n);
				break;
			}
		}
	}
}
