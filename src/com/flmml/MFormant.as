package com.flmml {
	/**
	 * This class was created based on "Formant filter" that programmed by alex.
	 See following URL; http://www.musicdsp.org/showArchiveComment.php?ArchiveID=110
	 Thanks to his great works!
	*/
	import __AS3__.vec.Vector;
	
	public class MFormant {
		public static const VOWEL_A:int = 0;
		public static const VOWEL_E:int = 1;
		public static const VOWEL_I:int = 2;
		public static const VOWEL_O:int = 3;
		public static const VOWEL_U:int = 4;
		
		// ca = filter coefficients of 'a'
		private const m_ca0:Number = 0.00000811044;
		private const m_ca1:Number = 8.943665402;
		private const m_ca2:Number = -36.83889529;
		private const m_ca3:Number = 92.01697887;
		private const m_ca4:Number = -154.337906;
		private const m_ca5:Number = 181.6233289;
		private const m_ca6:Number = -151.8651235;
		private const m_ca7:Number = 89.09614114;
		private const m_ca8:Number = -35.10298511;
		private const m_ca9:Number = 8.388101016;
		private const m_caA:Number = -0.923313471;
		
		// ce = filter coefficients of 'e'
		private const m_ce0:Number = 0.00000436215;
		private const m_ce1:Number = 8.90438318;
		private const m_ce2:Number = -36.55179099;
		private const m_ce3:Number = 91.05750846;
		private const m_ce4:Number = -152.422234;
		private const m_ce5:Number = 179.1170248;
		private const m_ce6:Number = -149.6496211;
		private const m_ce7:Number = 87.78352223;
		private const m_ce8:Number = -34.60687431;
		private const m_ce9:Number = 8.282228154;
		private const m_ceA:Number = -0.914150747;
		
		// ci = filter coefficients of 'i'
		private const m_ci0:Number = 0.00000333819;
		private const m_ci1:Number = 8.893102966;
		private const m_ci2:Number = -36.49532826;
		private const m_ci3:Number = 90.96543286;
		private const m_ci4:Number = -152.4545478;
		private const m_ci5:Number = 179.4835618;
		private const m_ci6:Number = -150.315433;
		private const m_ci7:Number = 88.43409371;
		private const m_ci8:Number = -34.98612086;
		private const m_ci9:Number = 8.407803364;
		private const m_ciA:Number = -0.932568035;
		
		// co = filter coefficients of 'o'
		private const m_co0:Number = 0.00000113572;
		private const m_co1:Number = 8.994734087;
		private const m_co2:Number = -37.2084849;
		private const m_co3:Number = 93.22900521;
		private const m_co4:Number = -156.6929844;
		private const m_co5:Number = 184.596544;
		private const m_co6:Number = -154.3755513;
		private const m_co7:Number = 90.49663749;
		private const m_co8:Number = -35.58964535;
		private const m_co9:Number = 8.478996281;
		private const m_coA:Number = -0.929252233;
		
		// cu = filter coefficients of 'u'
		private const m_cu0:Number = 4.09431e-7;
		private const m_cu1:Number = 8.997322763;
		private const m_cu2:Number = -37.20218544;
		private const m_cu3:Number = 93.11385476;
		private const m_cu4:Number = -156.2530937;
		private const m_cu5:Number = 183.7080141;
		private const m_cu6:Number = -153.2631681;
		private const m_cu7:Number = 89.59539726;
		private const m_cu8:Number = -35.12454591;
		private const m_cu9:Number = 8.338655623;
		private const m_cuA:Number = -0.910251753;
		
		private var
		m_m0:Number, m_m1:Number, m_m2:Number, m_m3:Number, m_m4:Number,
		m_m5:Number, m_m6:Number, m_m7:Number, m_m8:Number, m_m9:Number;
		
		private var m_vowel:int;
		private var m_power:Boolean;
		
		public function MFormant() {
			m_vowel = VOWEL_A;
			m_power = false;
			reset();
		}
		
		public function setVowel(vowel:int):void {
			m_power = true;
			m_vowel = vowel;
		}
		
		public function disable():void {
			m_power = false;
			reset();
		}
		
		public function reset():void {
			 m_m0 = m_m1 = m_m2 = m_m3 = m_m4 = m_m5 = m_m6 = m_m7 = m_m8 = m_m9 = 0;
		}
		
		// 無音入力時に何かの信号を出力するかのチェック
		public function checkToSilence():Boolean {
			return m_power && (
				-0.000001 <= m_m0 && m_m0 <= 0.000001 &&
				-0.000001 <= m_m1 && m_m1 <= 0.000001 &&
				-0.000001 <= m_m2 && m_m2 <= 0.000001 &&
				-0.000001 <= m_m3 && m_m3 <= 0.000001 &&
				-0.000001 <= m_m4 && m_m4 <= 0.000001 &&
				-0.000001 <= m_m5 && m_m5 <= 0.000001 &&
				-0.000001 <= m_m6 && m_m6 <= 0.000001 &&
				-0.000001 <= m_m7 && m_m7 <= 0.000001 &&
				-0.000001 <= m_m8 && m_m8 <= 0.000001 &&
				-0.000001 <= m_m9 && m_m9 <= 0.000001
			);
		}
		
		public function run(samples:Vector.<Number>, start:int, end:int):void {
			if (!m_power) return;
			var i:int;
			switch(m_vowel) {
				case 0:
					for(i = start; i < end; i++) {
						samples[i] = m_ca0 * samples[i] +
									 m_ca1 * m_m0 + m_ca2 * m_m1 +
									 m_ca3 * m_m2 + m_ca4 * m_m3 +
									 m_ca5 * m_m4 + m_ca6 * m_m5 +
									 m_ca7 * m_m6 + m_ca8 * m_m7 +
									 m_ca9 * m_m8 + m_caA * m_m9;
						m_m9 = m_m8;
						m_m8 = m_m7;
						m_m7 = m_m6;
						m_m6 = m_m5;
						m_m5 = m_m4;
						m_m4 = m_m3;
						m_m3 = m_m2;
						m_m2 = m_m1;
						m_m1 = m_m0;
						m_m0 = samples[i];
					}
					return;
				case 1:
					for(i = start; i < end; i++) {
						samples[i] = m_ce0 * samples[i] +
									 m_ce1 * m_m0 + m_ce2 * m_m1 +
									 m_ce3 * m_m2 + m_ce4 * m_m3 +
									 m_ce5 * m_m4 + m_ce6 * m_m5 +
									 m_ce7 * m_m6 + m_ce8 * m_m7 +
									 m_ce9 * m_m8 + m_ceA * m_m9;
						m_m9 = m_m8;
						m_m8 = m_m7;
						m_m7 = m_m6;
						m_m6 = m_m5;
						m_m5 = m_m4;
						m_m4 = m_m3;
						m_m3 = m_m2;
						m_m2 = m_m1;
						m_m1 = m_m0;
						m_m0 = samples[i];
					}
					return;
				case 2:
					for(i = start; i < end; i++) {
						samples[i] = m_ci0 * samples[i] +
									 m_ci1 * m_m0 + m_ci2 * m_m1 +
									 m_ci3 * m_m2 + m_ci4 * m_m3 +
									 m_ci5 * m_m4 + m_ci6 * m_m5 +
									 m_ci7 * m_m6 + m_ci8 * m_m7 +
									 m_ci9 * m_m8 + m_ciA * m_m9;
						m_m9 = m_m8;
						m_m8 = m_m7;
						m_m7 = m_m6;
						m_m6 = m_m5;
						m_m5 = m_m4;
						m_m4 = m_m3;
						m_m3 = m_m2;
						m_m2 = m_m1;
						m_m1 = m_m0;
						m_m0 = samples[i];
					}
					return;
				case 3:
					for(i = start; i < end; i++) {
						samples[i] = m_co0 * samples[i] +
									 m_co1 * m_m0 + m_co2 * m_m1 +
									 m_co3 * m_m2 + m_co4 * m_m3 +
									 m_co5 * m_m4 + m_co6 * m_m5 +
									 m_co7 * m_m6 + m_co8 * m_m7 +
									 m_co9 * m_m8 + m_coA * m_m9;
						m_m9 = m_m8;
						m_m8 = m_m7;
						m_m7 = m_m6;
						m_m6 = m_m5;
						m_m5 = m_m4;
						m_m4 = m_m3;
						m_m3 = m_m2;
						m_m2 = m_m1;
						m_m1 = m_m0;
						m_m0 = samples[i];
					}
					return;
				case 4:
					for(i = start; i < end; i++) {
						samples[i] = m_cu0 * samples[i] +
									 m_cu1 * m_m0 + m_cu2 * m_m1 +
									 m_cu3 * m_m2 + m_cu4 * m_m3 +
									 m_cu5 * m_m4 + m_cu6 * m_m5 +
									 m_cu7 * m_m6 + m_cu8 * m_m7 +
									 m_cu9 * m_m8 + m_cuA * m_m9;
						m_m9 = m_m8;
						m_m8 = m_m7;
						m_m7 = m_m6;
						m_m6 = m_m5;
						m_m5 = m_m4;
						m_m4 = m_m3;
						m_m3 = m_m2;
						m_m2 = m_m1;
						m_m1 = m_m0;
						m_m0 = samples[i];
					}
					return;
			}
		}
	}
}