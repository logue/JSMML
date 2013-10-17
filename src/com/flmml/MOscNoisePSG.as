package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscNoisePSG extends MOscMod {
		protected static var s_init:int = 0;
		protected var m_masterClock:Number;		//仮想PSG(AY-3-8910)マスタークロック
		protected var m_preScale:Number;		//仮想PSG用プリスケーラ値
		protected var m_phaseDelta:Number;		//音声１サンプルあたりの仮想PSGサイクル
		protected var m_nfreqIndex:Number;		//ノイズ周波数指定値
		protected var m_Sreg:int;				//ノイズ生成用シフトレジスタ（size:17bit）
		protected var m_interval:Number;
		protected var m_position:Number;
		protected var m_val:Number;

		public function MOscNoisePSG() {
			boot();
			m_modID = MOscillator.NOISE_PSG;
			super();
			m_position = 0.0;
			m_Sreg = getSeed();
			m_val = 0.0;
			m_nfreqIndex = 1.0;
			setClockMode(0);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public function setClockMode(n:int):void {
			switch (n) {
			case 0:		//PC88モード
			default:
				m_masterClock = 3993600.0;
				m_preScale    = 32.0;
				break;
			case 1:		//X1モード
				m_masterClock = 4000000.0;
				m_preScale    = 32.0;
				break;
			case 2:		//MSXモード
				m_masterClock = 3579545.0;
				m_preScale    = 32.0;
				break;
			case 3:		//FM7モード
				m_masterClock = 1228800.0;
				m_preScale    = 16.0;
				break;
			}
			m_phaseDelta = m_masterClock / 44100.0;
			m_position = 0.0;
			setNoiseFreq(m_nfreqIndex);
		}
		private function getSeed():int {
			var seed:int;
			seed = int(Math.random() * 131071.0);
			if (seed < 1) {
				seed = 1;
			}
			else if (seed > 131070) {
				seed = 131070;
			}
			return seed;
		}
		private function getOneCycleValue():Number {
			var val:Number;
			switch (m_Sreg & 9) 
			{	//bit0とbit3のxorのnotを出力し、レジスタを1bit右シフトし、出力結果を最上位ビットにorする。
				case 0:
				case 9:
					val = 1.0;
					m_Sreg >>= 1;
					m_Sreg |= 0x10000;
					break;
				default:
					val = -1.0;
					m_Sreg >>= 1;
			}
			return val;
		}
		public override function getNextSample():Number {
			var sum:Number = 0.0;
			var cnt:Number = 0.0;
			var delta:Number = m_phaseDelta;
			var interval:Number = m_interval;
			while (delta >= interval) {
				delta -= interval;
				sum += getOneCycleValue();
				cnt += 1.0;
			}
			if (cnt > 0.0) {
				m_val = sum / cnt;
			}
			m_position += delta;
			if (m_position >= interval) {
				m_position -= interval;
				m_val = getOneCycleValue();			//相加平均が存在した場合、最後に計算した値を優先
			}
			return m_val;
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		public override function setNoiseFreq(index:Number):void {
			if (index < 1.0) {
				m_nfreqIndex = 1.0;
			} else if (index > 1023.0) {
				m_nfreqIndex = 1023.0;
			} else {
				m_nfreqIndex = index;
			}
			m_interval = (m_preScale * m_nfreqIndex);
			m_position = 0.0;
		}
		public override function setYControl(m:int, f:int, n:Number):void {
			if (m_modID != m) return;
			switch (f) {
				default:
				case 0:		//func.0: No Operation
					break;
				case 1:		//func.1: setWaveNo
					break;
				case 2:		//func.2: setRenderFunc
					break;
				case 3:		//func.3: setDetune
					break;
				case 4:		//func.4: reserved
					break;
				case 5:		//func.5: setNoiseFreq() [MML.as:@nで使用]
					setNoiseFreq(n);
					break;
				case 10:	//func.10: setClockMode() [MML.as:@ncで使用]
					setClockMode(int(n));
					break;
			}
		}
	}
}