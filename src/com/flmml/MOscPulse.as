package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscPulse extends MOscMod {
		private static const MAX_EXOP:int  = 4;
		
		private static const OP_DETUNE:int = 0;
		private static const OP_FREQ:int   = 1;
		private static const OP_FSHIFT:int = 2;
		private static const OP_PHASE:int  = 3;
		private static const OP_PWM:int    = 4;
		private static const OP_PWMREQ:int = 5;
		private static const OP_AMP:int    = 6;
		private static const OP_VAL:int    = 7;
		private static const OP_MAX:int    = 8;
		
		private static const DEF_DETUNE:Number = 8.0;
		private static const DEF_DT_MAX:Number = 3600.0;
		private static const DEF_DT_MIN:Number = -3600.0;
		private static const DEF_LV_MIN:Number = -60.0;
		
		protected static var s_init:int = 0;
		protected var m_waveNo:int;
		protected var m_getValue:Function;
		protected var m_op:Vector.<Vector.<Number>>;
		protected var m_pwm:Number;
		protected var m_detune:Number;
		protected var m_ampDenom:Number;
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
			//初期変数のセット
			m_detune = DEF_DETUNE;
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
			for (i = 0; i < MAX_EXOP; i++) {
				m_op[i][OP_DETUNE] = 0.0;
				m_op[i][OP_FREQ]   = 440.0;
				m_op[i][OP_FSHIFT] = m_op[i][OP_FREQ] / 44100.0;
				m_op[i][OP_PHASE]  = 0.0;
				m_op[i][OP_PWM]    = 0.5;
				m_op[i][OP_PWMREQ] = 0.0;
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
		}
		
		private function getValueOP(op:Vector.<Number>):void {
			if ( op[OP_PHASE] < (op[OP_FSHIFT]/2.0) ) {
				op[OP_VAL] = (op[OP_PHASE] / (op[OP_FSHIFT]/2.0)) * (1.0 - 0.0) + 0.0;
			}
			else if ( (op[OP_PHASE] >= (op[OP_PWM] - (op[OP_FSHIFT]/2.0))) && (op[OP_PHASE] < (op[OP_PWM] + (op[OP_FSHIFT]/2.0))) ) {
				op[OP_VAL] = (op[OP_PHASE] - (op[OP_PWM] - (op[OP_FSHIFT]/2.0))) / (op[OP_FSHIFT]) * ((-1.0) - 1.0) + (1.0);
			}
			else if ( op[OP_PHASE] > (1.0 - (op[OP_FSHIFT]/2.0)) ) {
				op[OP_VAL] = (op[OP_PHASE] - (1.0 - (op[OP_FSHIFT]/2.0))) / (op[OP_FSHIFT]/2.0) * ((0.0) - (-1.0)) + (-1.0);
			}
			else {
				op[OP_VAL] = (op[OP_PHASE] < op[OP_PWM]) ? 1.0 : -1.0;
			}
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
		
		private function setAmplvOP(op:Vector.<Number>, lv:Number):void {
			op[OP_AMP] = Math.pow(10.0, (lv/20.0));		//lv:dB
		}
		
		private function setPWMOP(op:Vector.<Number>, pwm:Number):void {
			op[OP_PWMREQ] = pwm;
		}
		
		private function syncOperatorOP(op:Vector.<Number>):void {
			setFrequencyOP(op, m_frequency);
			op[OP_PWMREQ] = m_pwm;
			op[OP_VAL]   = 0.0;
			resetPhaseExecOP(op);
		}
		// Operator Func. end -----------------------------
		
		
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
			m_val = ((m_op[0][OP_VAL] * m_op[0][OP_AMP]) + (m_op[1][OP_VAL] * m_op[1][OP_AMP])) / m_ampDenom;
			m_phase = m_op[0][OP_PHASE];
		}
		private function getValueW30():void {
			getValueOP(m_op[0]);
			getValueOP(m_op[1]);
			getValueOP(m_op[2]);
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
			m_frequency = frequency;
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
		public function setPWM(pwm:Number):void {
			var p:Number = pwm;
			if (p < 0.005) p = 0.005;
			if (p > 0.995) p = 0.995;
			m_pwm = p;
			var i:int;
			for (i=0; i<MAX_EXOP; i++) {
				setPWMOP(m_op[i], m_pwm);
			}
		}
		public function setDetune(detune:Number):void {
			m_detune = limitNum(-100.0, 100.0, detune);
			setDetuneOP(m_op[0], 0.0);
			setDetuneOP(m_op[1], m_detune);
			setDetuneOP(m_op[2], (m_detune * (-1.0)));
			setDetuneOP(m_op[3], (m_detune / 2.0));
			setFrequency(m_frequency);
		}
		public function setNoiseModule(noise:MOscNoisePSG):void {
			m_modNoise = noise;
		}
		private function refreshAmpDenom():void {
			switch (m_waveNo) {
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
			if (m_waveNo == n) return;			//同番号指定による再初期化防止
			
			switch(waveNo) {
			default:
				n = 0;							//規定外指定は０番指定に矯正
				if (m_waveNo == n) return;		//過去０番だった時、同番号指定による再初期化防止
			case 0:
				m_getValue = getValueW0;
				break;
			case 1:
				m_getValue = getValueW1;
				break;
			case 2:
				m_getValue = getValueW2;
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
			m_waveNo = n;
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
				setWaveNo(int(n));
				break;
			case 3:		//func.3: setDetune
				setDetune(n);
				break;
			case 4:		//func.4: reserved
				break;
			case 5:		//sp.func.5: PWM
				setPWM(n);
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
