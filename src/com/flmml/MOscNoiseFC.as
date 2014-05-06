package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscNoiseFC extends MOscMod {
		public static const NOISE_FC_M_FREQ:Number  = 1789772.5;						//１秒あたりのマスタサイクル数
		public static const NOISE_FC_P_DELTA:Number = NOISE_FC_M_FREQ / 44100.0;		//１サンプルあたりのマスタサイクル数

		protected static var s_interval:Vector.<int> = Vector.<int>([
			0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0060, 0x0080, 0x00a0,
			0x00ca, 0x00fe, 0x017c, 0x01fc, 0x02fa, 0x03f8, 0x07f2, 0x0fe4
		]);

		protected static var s_init:int = 0;
		protected var m_interval:Number;
		protected var m_position:Number;
		protected var m_Sreg:int;
		protected var m_xorBitImg:int;
		protected var m_val:Number;

		public function MOscNoiseFC() {
			boot();
			m_modID = MOscillator.NOISE_FC;
			super();
			m_val = 0.0;
			setLongMode();
			setNoiseFreq(0.0);
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_init = 1;
		}
		public function setShortMode():void {
			m_xorBitImg = 0x04100;
			m_Sreg = getSeedShort();
			m_position = 0.0;
		}
		public function setLongMode():void {
			m_xorBitImg = 0x06000;
			m_Sreg = getSeedLong();
			m_position = 0.0;
		}
		private function getSeedShort():int {
			var seed:int;
			var s:int;
			s = int(Math.random() * 14.0);
			if (s < 0) {
				s = 0;
			}
			else if (seed > 14) {
				s = 14;
			}
			seed = 1 << s;
			return seed;
		}
		private function getSeedLong():int {
			var seed:int;
			seed = int(Math.random() * 32767.0);
			if (seed < 1) {
				seed = 1;
			}
			else if (seed > 32766) {
				seed = 32766;
			}
			return seed;
		}
		private function getOneCycleValue():Number {
			var val:Number;
			var pattern:int = m_xorBitImg;
			switch (m_Sreg & pattern) 
			{	//(bit13とbit14)または(bit8とbit14)のxorのnotを出力し、レジスタを1bit左シフトし、xor結果を最下位ビットにorする。
				case 0x00000:
				case pattern:
					val = 1.0;
					m_Sreg <<= 1;
					break;
				default:
					val = -1.0;
					m_Sreg <<= 1;
					m_Sreg |= 0x00001;
			}
			return val;
		}
		public override function getNextSample():Number {
			var sum:Number = 0.0;
			var cnt:Number = 0.0;
			var delta:Number = NOISE_FC_P_DELTA;
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
			var n:int;
			n = int(index);
			if (n <  0) n =  0;
			if (n > 15) n = 15;
			m_interval = Number(s_interval[n]);
			m_position = 0.0;
		}
		public override function setWaveNo(mode:int):void {
			if (mode == 0) {
				if (m_xorBitImg != 0x06000) setLongMode();
			}
			else {
				if (m_xorBitImg != 0x04100) setShortMode();
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