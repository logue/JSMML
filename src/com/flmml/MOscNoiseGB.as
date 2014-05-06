package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscNoiseGB extends MOscMod {
		public static const NOISE_GB_M_FREQ:Number  = 1048576.0;						//１秒あたりのマスタサイクル数
		public static const NOISE_GB_P_DELTA:Number = NOISE_GB_M_FREQ / 44100.0;		//１サンプルあたりのマスタサイクル数
		
		protected static var s_interval_seed:Vector.<int> = Vector.<int>([ 2, 4, 8, 12, 16, 20, 24, 28]);
		
		protected static var s_init:int = 0;
		protected var m_interval:Number;
		protected var m_positionL:Number;
		protected var m_positionS:Number;
		protected var m_SregL:int;					//演奏中の切り替えを想定してシフトレジスタと生成ルーチンを別々に持つ
		protected var m_SregS:int;
		protected var m_valL:Number;
		protected var m_valS:Number;
		protected var m_Smode:int;

		public function MOscNoiseGB() {
			boot();
			m_modID = MOscillator.NOISE_GB;
			super();
			resetPhase();
			m_valL = 0.0;
			m_valS = 0.0;
			setLongMode();
			setNoiseFreq(0.0);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public override function resetPhase():void {
			m_positionL = 0.0;						//ノートオンの都度リセット
			m_positionS = 0.0;
			m_SregL = 0x00ffff;
			m_SregS = 0x0000ff;
		}
		public function setLongMode():void {
			m_Smode = 0;
		}
		public function setShortMode():void {
			m_Smode = 1;
		}
		private function getOneCycleValueL():Number {
			var val:Number;
			switch (m_SregL & 0x06000) 
			{	//bit13とbit14のxorのnotを出力し、レジスタを1bit左シフトし、xor結果を最下位ビットにorする。
				case 0x00000:
				case 0x06000:
					val = 1.0;
					m_SregL <<= 1;
					break;
				default:
					val = -1.0;
					m_SregL <<= 1;
					m_SregL |= 0x00001;
			}
			return val;
		}
		private function getOneCycleValueS():Number {
			var val:Number;
			switch (m_SregS & 0x00060) 
			{	//bit5とbit6のxorのnotを出力し、レジスタを1bit左シフトし、xor結果を最下位ビットにorする。
				case 0x00000:
				case 0x00060:
					val = 1.0;
					m_SregS <<= 1;
					break;
				default:
					val = -1.0;
					m_SregS <<= 1;
					m_SregS |= 0x00001;
			}
			return val;
		}
		private function getNextSampleL():Number {
			var sum:Number = 0.0;
			var cnt:Number = 0.0;
			var delta:Number = NOISE_GB_P_DELTA;
			var interval:Number = m_interval;
			while (delta >= interval) {
				delta -= interval;
				sum += getOneCycleValueL();
				cnt += 1.0;
			}
			if (cnt > 0.0) {
				m_positionL = 0.0;
				m_valL = sum / cnt;
			}
			m_positionL += delta;
			if (m_positionL >= interval) {
				m_positionL -= interval;
				if (cnt == 0.0) m_valL = getOneCycleValueL();
				else m_valL = (m_valL + getOneCycleValueL()) / 2.0;		//相加平均値があればさらに平均する。
			}
			return m_valL;
		}
		private function getNextSampleS():Number {
			var sum:Number = 0.0;
			var cnt:Number = 0.0;
			var delta:Number = NOISE_GB_P_DELTA;
			var interval:Number = m_interval;
			while (delta >= interval) {
				delta -= interval;
				sum += getOneCycleValueS();
				cnt += 1.0;
			}
			if (cnt > 0.0) {
				m_valS = sum / cnt;
			}
			m_positionS += delta;
			if (m_positionS >= interval) {
				m_positionS -= interval;
				if (cnt == 0.0) m_valS = getOneCycleValueS();
				else getOneCycleValueS();					//相加平均値があればそちらを優先し、より周期的な音味にする。
			}
			return m_valS;
		}
		public override function getNextSample():Number {
			if (m_Smode == 0) return getNextSampleL();
			else return getNextSampleS();
		}
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for(i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		public override function setNoiseFreq(index:Number):void {
			var n:int;
			var rate:int;
			var sft:int;
			n = int(index);
			if (n <   0) n =   0;
			if (n > 157) n = 157;
			rate = n % 10;
			sft  = n / 10;
			if (rate >  7) rate = 7;
			if (sft  > 15) sft = 15;
			m_interval = Number(1 << sft) * Number(s_interval_seed[rate]);
			if (m_interval < 2.0) m_interval = 2.0;
			if (m_interval > 524288.0) m_interval = 524288.0;		//524288.0 = (NOISE_GB_M_FREQ/2.0)
		}
		public override function setWaveNo(mode:int):void {
			if (mode == 0) {
				if (m_Smode != 0) setLongMode();
			}
			else {
				if (m_Smode != 1) setShortMode();
			}
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
				break;
			case 4:		//func.4: reserved
				break;
			case 5:		//sp.func.5: setNoiseFreq() [MML.as:@nで使用]
				setNoiseFreq(n);
				break;
			}
		}
	}
}