package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscLTable extends MOscModL {
		public static const MAX_WAVE:int = 256;
		public static const MAX_LENGTH:int = 1024;
		public static const T_L_ENTRY:int  = 0;
		public static const T_C_MODE:int   = 1;
		public static const T_D_OFFSET:int = 2;
		public static const T_D_DENOM:int  = 3;
		public static const T_W_MODE:int   = 4;
		public static const T_W_DENOM:int  = 5;
		public static const T_ELEM_ST:int  = 6;
		public static var s_Pmode:int = 0;			//ポインタプロセスモード。0:ポインタ事後加算。1:ポインタ事前加算。
		protected static var s_init:int = 0;
		protected static var s_table:Vector.<Vector.<Number>>;
		protected static var s_length:Vector.<int>;
		protected static var s_Lentry:Vector.<int>;
		protected static var s_Cmode:Vector.<Boolean>;
		protected static var s_Wmode:Vector.<Boolean>;
		protected static var s_Wdenom:Vector.<Number>;
		protected var m_waveNo:int;
		protected var m_waveNo1st:int;
		protected var m_waveNo2nd:int;
		protected var m_position:Number;			//テーブル読み込み位置
		protected var m_ptrShift:Number;			//読み込みポインタへの加算値（０より大きく、１以下）
		protected var m_val:Number;

		public function MOscLTable() {
			boot();
			super();
			setWaveNoForSwitchCtrl(0, (-1));
			resetPhase();
			m_ptrShift = 1.0;
		}
		public static function boot():void {
			if (s_init != 0) return;
			s_table  = new Vector.<Vector.<Number>>(MAX_WAVE);
			s_length = new Vector.<int>(MAX_WAVE);
			s_Lentry = new Vector.<int>(MAX_WAVE);
			s_Cmode  = new Vector.<Boolean>(MAX_WAVE);
			s_Wmode  = new Vector.<Boolean>(MAX_WAVE);
			s_Wdenom = new Vector.<Number>(MAX_WAVE);
			setTable(0, "-1, 0, 0, 1, 0, 1,   0,0,0,0");
			s_init = 1;
		}
		public override function resetPhase():void {
			m_position = 0.0;
			m_val = 0.0;
		}
		private static function trim(str:String):String {
			var regexHead:RegExp = /^[,]*/m;
			var regexFoot:RegExp = /[,]*$/m;
			return str.replace(regexHead, '').replace(regexFoot, '');
		}       
		public static function setTable(tableNo:int, s:String):int {
			/* 読み込みstringデータフォーマットは区切り文字で下記要素として認識
			 * 0: loop entry point:			-1:ループしない。終端到達後、ノートオンリセットされるまで終端を返す。0以上:ループエントリポイント
			 * 1: [変位]complement mode:	0:０次補間。 1:線形補間。
			 * 2: [変位]displacement offset: 各要素値に対するオフセット
			 * 3: [変位]displacement denominator: 各要素値に対する分母（変位スケール）。０より大きい数であること。
			 * 4: [時間]width mode: LFO-widthの処理モード。0:step数（範囲は1以上）。1:shift数（範囲は分母で除算後で0より大きく1以下であること）。
			 * 5: [時間]shift-number denominator: LFO-widthをshift数で受ける場合のみ有効な、shift数に対する分母。０より大きい数であること。
			 * 6: table[0]:Number
			 * 7: table[1]
			 * 8: table[2]
			 *     :
			 * n: table[n-6]
			 */
			var result:int = 0;
			
			if (tableNo < 0 || tableNo >= MAX_WAVE) {
				return -1;
			}
			
			s = s.replace(/[,;\s\t\r\n]+/gm, ",");
			s = trim(s);
			var a:Array = s.split(",");
			var len:int = a.length - T_ELEM_ST;
			if (len < 1 || len > MAX_LENGTH) {
				a = null;
				return -2;
			}
			
			var Lentry:int = int(a[T_L_ENTRY]);
			if (Lentry >= len || Lentry < 0) {
				Lentry = -1;
			}
			
			var Cmode:Boolean;
			if (int(a[T_C_MODE]) == 0) Cmode = false;
			else Cmode = true;
			
			var Doffset:Number = Number(a[T_D_OFFSET]);
			
			var Ddenom:Number  = Number(a[T_D_DENOM]);
			if (Ddenom <= 0.0) Ddenom = 1.0;		//分母指定が０以下の場合は強制的に分母１に。
			
			var Wmode:Boolean;
			if (int(a[T_W_MODE]) == 0) Wmode = false;
			else Wmode = true;
			
			var Wdenom:Number  = Number(a[T_W_DENOM]);
			if (Wdenom <= 0.0) Wdenom = 1.0;		//分母指定が０以下の場合は強制的に分母１に。
			
			s_length[tableNo] = len;
			s_Lentry[tableNo] = Lentry;
			s_Cmode[tableNo]  = Cmode;
			s_Wmode[tableNo]  = Wmode;
			s_Wdenom[tableNo] = Wdenom;
			s_table[tableNo]  = new Vector.<Number>(len);
			
			var element:Number;
			for (var i:int = 0; i < len; i++) {
				element = (Number(a[T_ELEM_ST + i]) - Doffset) / Ddenom;
				if (isNaN(element) == true) {
					result = -3;
					a = null;
					s_table[tableNo] = null;
					break;
				}
				s_table[tableNo][i] = element;
			}
			return result;
		}
		private function getValueMode0():void {
			var val0:Number;
			var val1:Number;
			var p0:int;
			var p1:int;
			var ep:int = s_length[m_waveNo];
			var endp:Number = Number(ep);			//少数以下切捨て値をindexとするので、無効位置はlength以降になる。
			var dp:Number;
			
			if (s_Cmode[m_waveNo] == false) {
				m_val = s_table[m_waveNo][ int(Math.floor(m_position)) ];
			}
			else {
				dp = m_position % 1.0;
				p0 = int(Math.floor(m_position));
				p1 = p0 + 1;
				if (p1 >= ep) {
					if (s_Lentry[m_waveNo] < 0) {
						p1 = p0;
					}
					else {
						p1 = s_Lentry[m_waveNo];
					}
				}
				val0 = s_table[m_waveNo][ p0 ];
				val1 = s_table[m_waveNo][ p1 ];
				m_val = val0 + ((val1 - val0) * dp);
			}
			
			m_position += m_ptrShift;
			
			if (m_position >= endp) {
				dp = m_position - endp;
				if (s_Lentry[m_waveNo] < 0) {
					m_position = (endp - 1.0) + dp;
				}
				else {
					m_position = Number(s_Lentry[m_waveNo]) + dp;
				}
			}
		}
		private function getValueMode1():void {
			var val0:Number;
			var val1:Number;
			var p0:int;
			var p1:int;
			var ep:int = s_length[m_waveNo];
			var endp:Number = Number(ep);			//少数以下切捨て値をindexとするので、無効位置はlength以降になる。
			var dp:Number;
			
			m_position += m_ptrShift;
			
			if (m_position >= endp) {
				dp = m_position - endp;
				if (s_Lentry[m_waveNo] < 0) {
					m_position = (endp - 1.0) + dp;
				}
				else {
					m_position = Number(s_Lentry[m_waveNo]) + dp;
				}
			}
			
			if (s_Cmode[m_waveNo] == false) {
				m_val = s_table[m_waveNo][ int(Math.floor(m_position)) ];
			}
			else {
				dp = m_position % 1.0;
				p0 = int(Math.floor(m_position));
				p1 = p0 + 1;
				if (p1 >= ep) {
					if (s_Lentry[m_waveNo] < 0) {
						p1 = p0;
					}
					else {
						p1 = s_Lentry[m_waveNo];
					}
				}
				val0 = s_table[m_waveNo][ p0 ];
				val1 = s_table[m_waveNo][ p1 ];
				m_val = val0 + ((val1 - val0) * dp);
			}
		}
		public override function getNextSample():Number {
			if (s_Pmode == 0) {
				getValueMode0();
			}
			else {
				getValueMode1();
			}
			return m_val;
		}
		public function setPShiftParam(param:Number):void {
			if (s_Wmode[m_waveNo] == false) {
				var step:Number;
				var p:Number = param;
				if (p < 1.0) p = 1.0;
				step = 1.0 / p;
				if (step > 0.0 && step <= 1.0) {
					m_ptrShift = step;
				} else {
					m_ptrShift = 1.0;
				}
			}
			else {
				var shift:Number;
				shift = param / s_Wdenom[m_waveNo];
				if (shift > 0.0 && shift <= 1.0) {
					m_ptrShift = shift;
				} else {
					m_ptrShift = 1.0;
				}
			}
		}
		public override function setWaveNo(waveNo:int):void {
			var n:int = waveNo;
			if (n >= MAX_WAVE) n = MAX_WAVE-1;
			if (n < 0) n = 0;
			if (s_table[n] == null) n = 0;		//未定義テーブル番号へのリクエストは０番に矯正
			m_waveNo = n;
		}
		public override function setWaveNoForSwitchCtrl(w1:int, w2:int):void {
			var n2:int = w2;
			if (n2 >= MAX_WAVE) n2 = MAX_WAVE-1;
			if (n2 < 0) n2 = (-1);
			if (n2 >= 0) {
				if (s_table[n2] == null) n2 = (-1);
			}
			
			setWaveNo(w1);
			m_waveNo1st = m_waveNo;
			m_waveNo2nd = n2;
		}
		public function setWaveNo1st():void {
			if (m_waveNo == m_waveNo1st) {
				return;
			}
			setWaveNo(m_waveNo1st);
		}
		public function setWaveNo2nd():void {
			if (m_waveNo2nd < 0) {
				return;
			}
			setWaveNo(m_waveNo2nd);
			resetPhase();
		}
		public function getWaveNo2nd():int {
			return m_waveNo2nd;
		}
	}
}