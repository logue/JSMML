package com.flmml {
	import __AS3__.vec.Vector;
	
	/**
	 * FM sound generator module 'OPMS' core unit
	 * @author LinearDrive
	 */
	public class MOscOPMS extends MOscMod {
		private static var s_init:int = 0;
		private static const MAX_TONE:int = 256;				//音色メモリ数の上限
		private static const OP1:int = 0,  OP2:int = 1,  OP3:int = 2,  OP4:int = 3;
		private static const OPMAX:int = 4;
		private static const PARAMAX:int = 61;
		public  static const OPMCLK358:Number = (3579545.0);
		public  static const OPNACLK39936:Number = (3993600.0);
		public  static const CLOCK4M:Number = (4000000.0);
		public  static const NOTEOFS:int = ((11 + 24) * 64);	//オクターブ拡張補正込み
		private static const DT3MAX:Number = (3600.0);
		private static const DT3MIN:Number = (-3600.0);
		public  static const FBBIASMAX:Number = (1.25);
		public  static const FBBIASMIN:Number = (0.925);
		public  static const HLFOSPMAX:Number = (2.0);
		public  static const HLFOSPMIN:Number = (0.5);
		
		private static var s_letter:int;						//音色テキスト数値解析用インデックス
		private static var s_string:String;						//音色テキスト数値解析用文字列
		private static var s_ToneTable:Vector.<Vector.<Number>>;
		private static var s_ofs:Vector.<int> = Vector.<int>([1,16,31,46]);
		private static var s_of2:Vector.<int> = Vector.<int>([2,13,24,35]);
		
		public  static var s_OpmClock:Number = (OPMCLK358);
		public  static var s_OpmRateN:Number = (OPMCLK358 / 64.0);	// テーブル計算用。入力クロック÷64
		public  static var s_SamprateN:Number = (44100.0);
		private static var s_LvOfs:Number = Math.pow(2.0, Number(MOscOPMSop.SIZESINTBL_BITS + 2));			//2^x,  x = SIZESINTBL_BITS + 2
		public  static var s_FbLvBIAS:Number = (1.0);				//Feedback Level BIAS（メタ指定のデフォルト用）
		public  static var s_HLFO_OPMSP:Number = (1.0);				//Hard LFO Speed Adj.（メタ指定のデフォルト用）
		public  static var s_HLFO_OPNASP:Number = (1.0);			//Hard LFO Speed Adj.（メタ指定のデフォルト用）
		
		private static var s_KCtable:Vector.<int> = Vector.<int>([
		//  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
			0xE,0x0,0x1,0x2,0x4,0x5,0x6,0x8,0x9,0xA,0xC,0xD,
		]);
		
		private static var defaultOPMS_Tone:Vector.<Number> = Vector.<Number>([
			/* CON */
				 4,
			/*  AR D1R D2R  RR D1L  TL  KS MUL DT1 DT2 AME MSK  FB DT3  AI */
				31,  5,  0,  0,  0, 23,  1,  1,  3,  0,  0,  0,  5,  0, -1,
				20, 10,  3,  7,  8,  0,  1,  1,  3,  0,  0,  0,  0,  0, -1,
				31,  3,  0,  0,  0, 25,  1,  1,  7,  0,  0,  0,  0,  0, -1,
				31, 12,  3,  7, 10,  2,  1,  1,  7,  0,  0,  0,  0,  0, -1,
		]);
			/*	 0
				 1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
				16  17  18  19  20  21  22  23  24  25  26  27  28  29  30
				31  32  33  34  35  36  37  38  39  40  41  42  43  44  45
				46  47  48  49  50  51  52  53  54  55  56  57  58  59  60
				（全61個。ネイティブ定義）*/
		
		private static var defaultOPM_Tone:Vector.<Number> = Vector.<Number>([
			/* CON  FB  */
				 4,  5,
			/*  AR D1R D2R  RR D1L  TL  KS MUL DT1 DT2 AME */
				31,  5,  0,  0,  0, 23,  1,  1,  3,  0,  0,
				20, 10,  3,  7,  8,  0,  1,  1,  3,  0,  0,
				31,  3,  0,  0,  0, 25,  1,  1,  7,  0,  0,
				31, 12,  3,  7, 10,  2,  1,  1,  7,  0,  0,
			//  OM
				15,
		]);
			/*	 0   1
				 2   3   4   5   6   7   8   9  10  11  12
				13  14  15  16  17  18  19  20  21  22  23
				24  25  26  27  28  29	30  31  32  33  34
				35  36  37  38  39  40  41  42  43  44  45
				46 （全47個。OPM定義と互換）*/
		
		// メンバ記憶域
		private var m_curTone:int;			// カレント音色番号
		private var m_KeyOn:Boolean;
		private var m_EgResetMode:Boolean;
		private var m_FbLvBIAS:Number;		//Feedback Level BIAS（逐次指定のY-control用）
		private var m_HLFO_OPMSP:Number;	//Hard LFO Speed Adj.（逐次指定のY-control用）
		private var m_HLFO_OPNASP:Number;	//Hard LFO Speed Adj.（逐次指定のY-control用）
		
		private var m_ampLV:Number;			// 音量レベル（シーケンサ側からの指示）
		private var m_outputLV:Number;		// 出力レベル（s_gainLV * m_ampLV * 整数pcmからfloatへの変換値）
		private var m_OpOut:Number;
		private var m_val:Number;			// 最終音声の変位
		private var m_getValue:Function;	// CONに従ったアルゴリズムのメソッドを指定
		
		private var m_Y_DT3:Vector.<Number>;
		private var m_Y_TL:Vector.<int>;
		
		private var m_compleCount:int;		// ノートオン時のプチノイズ防止補完用カウンタ
		private var m_compleDelta:Number;	// 補完用差分値
		private var m_compleWorkVal:Number;	// 補完作業中の変位
		
		private var OP:Vector.<MOscOPMSop>;
		private var m_EnvCounter1:int;
		private var m_EnvCounter2:int;
		private var m_rate:Number;
		
		private var lfo:MOscOPMSlfo;
		private var lfoA:MOscOPMSlfoA;
		private var m_lfoUpdate:Function;
		private var m_lfoGetPMV:Function;
		private var m_lfoGetAMV:Function;
		private var m_lfoGetSYNC:Function;
		private var m_lfoResetPhase:Function;
		private var m_lfopitch:int;
		private var m_lfolevel:int;
		private var m_lfoMode:Boolean;
		
		public function MOscOPMS() {
			boot();
			m_modID = MOscillator.OPMS;
			
			OP = new Vector.<MOscOPMSop>(OPMAX);
			OP.fixed = true;
			OP[OP1] = new MOscOPMSop();
			OP[OP2] = new MOscOPMSop();
			OP[OP3] = new MOscOPMSop();
			OP[OP4] = new MOscOPMSop();
			lfo = new MOscOPMSlfo();
			lfoA = new MOscOPMSlfoA();
			m_Y_DT3 = Vector.<Number>([0.0, 0.0, 0.0, 0.0]);
			m_Y_TL  = Vector.<int>([0, 0, 0, 0]);
			m_FbLvBIAS = s_FbLvBIAS;	// メタ指定のデフォルト値を受け取る
			m_HLFO_OPMSP = s_HLFO_OPMSP;
			m_HLFO_OPNASP = s_HLFO_OPNASP;
			setVolume(1.0);				// m_ampLV,m_outputLVの初期設定
			Reset();
			setWaveNo(0);				// boot()で定義されたデフォルト音色を音源に設定。
			m_compleCount = 0;
			setHLFOMODE(0);				// OPM mode
			
			super();
		}
		public static function boot():void {
			if (s_init != 0) return;
			// -----
			s_ToneTable = new Vector.< Vector.<Number> >(MAX_TONE);
			s_ToneTable.fixed = true;
			s_ToneTable[0] = defaultOPMS_Tone;
			SetOpmClock(OPMCLK358);
			// -----
			s_init = 1;
		}
		public static function SetOpmClock(val:Number):void {
			s_OpmClock = limitNum(OPMCLK358, CLOCK4M, val);
			s_OpmRateN = s_OpmClock / 64.0;
		}
		// 動作モード初期化
		public function Reset():void {
			m_KeyOn = false;
			m_EgResetMode = false;
			m_rate = 0.0;
			m_OpOut = 0;
			m_val = 0.0;
			// 全オペレータを初期化
			OP[OP1].Init(OP1);
			OP[OP2].Init(OP2);
			OP[OP3].Init(OP3);
			OP[OP4].Init(OP4);
			setCON(0);
			// エンベロープ用カウンタを初期化
			m_EnvCounter1 = 0;
			m_EnvCounter2 = 3;
			// LFO初期化
			lfo.Init(s_OpmRateN * m_HLFO_OPMSP);
			lfoA.Init((OPNACLK39936 / 72.0) * m_HLFO_OPNASP);
		}
		// パラメータの最小値・最大値のリミッタ機能
		private static function limitNum(l1:Number, l2:Number, num:Number):Number {
			if (isNaN(num) == true) return 0.0;
			var n:Number = num;
			if (n < l1) n = l1;
			if (n > l2) n = l2;
			return n;
		}
		private static function limitNumI(l1:int, l2:int, num:int):int {
			var n:int = num;
			if (n < l1) n = l1;
			if (n > l2) n = l2;
			return n;
		}
		//テキスト数値読み取り関数(要:s_string,s_letter)：getChar(),next(),getUint(),getUNumber()
		private static function getChar():String {
			return (s_letter < s_string.length) ? s_string.charAt(s_letter) : '';
		}
		private static function next(i:int = 1):void {
			s_letter += 1;
		}
		private static function getUInt(def:int):int {
			var ret:int = 0;
			var l:int = s_letter;
			var f:Boolean = true;
			while(f) {
				var c:String = getChar();
				switch(c) {
					case '0': ret = (ret * 10) + 0; next(); break;
					case '1': ret = (ret * 10) + 1; next(); break;
					case '2': ret = (ret * 10) + 2; next(); break;
					case '3': ret = (ret * 10) + 3; next(); break;
					case '4': ret = (ret * 10) + 4; next(); break;
					case '5': ret = (ret * 10) + 5; next(); break;
					case '6': ret = (ret * 10) + 6; next(); break;
					case '7': ret = (ret * 10) + 7; next(); break;
					case '8': ret = (ret * 10) + 8; next(); break;
					case '9': ret = (ret * 10) + 9; next(); break;
					default: f = false; break;
				}
			}
			return (s_letter == l) ? def : ret;
		}
		private static function getUNumber(def:Number):Number {
			var ret:Number;
			var l:int;
			var d:Number = 1.0;
			l = s_letter;
			ret = Number( getUInt(0) );
			if (getChar() == '.') {
				next();
				var f:Boolean = true;
				while(f) {
					var c:String = getChar();
					d *= (0.1);
					switch(c) {
						case '0': ret = ret + (0.0 * d); next(); break;
						case '1': ret = ret + (1.0 * d); next(); break;
						case '2': ret = ret + (2.0 * d); next(); break;
						case '3': ret = ret + (3.0 * d); next(); break;
						case '4': ret = ret + (4.0 * d); next(); break;
						case '5': ret = ret + (5.0 * d); next(); break;
						case '6': ret = ret + (6.0 * d); next(); break;
						case '7': ret = ret + (7.0 * d); next(); break;
						case '8': ret = ret + (8.0 * d); next(); break;
						case '9': ret = ret + (9.0 * d); next(); break;
						default: f = false; break;
					}
				}
			}
			return (s_letter == l) ? def : ret;
		}
		//正の分数テキストを読み取って実数を返す関数
		private static function getUFraction(s:String):Number {
			var n1:Number, n2:Number;
			var f:Boolean;
			s_letter = 0;
			s_string = s.replace(new RegExp("[ 　\n\r\t\f]+","g"),"");
			n1 = getUNumber(-1.0);
			if (n1 == (-1.0)) return 1.0;		//error終了
			if (getChar() == '/') {
				next();
				n2 = getUNumber(1.0);
			}
			else {
				n2 = 1.0;
			}
			if (n2 == 0.0) n2 = 1.0;
			return (n1/n2);
		}
		// テキストからstatic音色テーブルへデータロード（ネイティブ定義）
		public static function loadToneOPMS(num:int, str:String):int {
			if (num < 0 || num >= MAX_TONE) return (-1);
			var i:int;
			var s:String = str;
			var a:Array;
			var t:Vector.<Number> = new Vector.<Number>(PARAMAX);
			s = s.replace(/[,;\s\t\r\n]+/gm, ",");
			s = s.replace(/^[,]*/m, '').replace(/[,]*$/m, '');
			a = s.split(",");
			if (a.length != 61) return (-2);		//too short or too long
			for (i=0; i<PARAMAX; i++) {
				t[i] = 0.0;
			}
			for (i=OP1; i<OPMAX; i++) {
				t[ 0 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 0 + s_ofs[i] ]) );		// AR
				t[ 1 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 1 + s_ofs[i] ]) );		// D1R
				t[ 2 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 2 + s_ofs[i] ]) );		// D2R
				t[ 3 + s_ofs[i] ] = limitNum( 0.0, 15.0, Number(a[ 3 + s_ofs[i] ]) );		// RR
				t[ 4 + s_ofs[i] ] = limitNum( 0.0, 15.0, Number(a[ 4 + s_ofs[i] ]) );		// D1L
				t[ 5 + s_ofs[i] ] = limitNum( 0.0,127.0, Number(a[ 5 + s_ofs[i] ]) );		// TL
				t[ 6 + s_ofs[i] ] = limitNum( 0.0,  3.0, Number(a[ 6 + s_ofs[i] ]) );		// KS
				t[ 7 + s_ofs[i] ] = limitNum( 0.0, 16.0, getUFraction( String(a[ 7 + s_ofs[i] ])) );	// MUL
				t[ 8 + s_ofs[i] ] = limitNum( 0.0,  7.0, Number(a[ 8 + s_ofs[i] ]) );		// DT1
				t[ 9 + s_ofs[i] ] = limitNum( 0.0,  3.0, Number(a[ 9 + s_ofs[i] ]) );		// DT2
				t[10 + s_ofs[i] ] = limitNum( 0.0,  1.0, Number(a[10 + s_ofs[i] ]) );		// AME
				t[11 + s_ofs[i] ] = limitNum( 0.0,  1.0, Number(a[11 + s_ofs[i] ]) );		// MSK
				t[12 + s_ofs[i] ] = limitNum( 0.0,  8.0, Number(a[12 + s_ofs[i] ]) );		// FB: 0-8...0,pi/16,pi/8,pi/4,pi/2,pi,2pi,4pi,8pi
				t[13 + s_ofs[i] ] = limitNum(DT3MIN, DT3MAX, Number(a[13 + s_ofs[i] ]) );	// DT3
				t[14 + s_ofs[i] ] = limitNum(-1.0,128.0, Number(a[14 + s_ofs[i] ]) );		// AI
			}
			t[ 0] = limitNum( 0.0,  7.0, Number(a[ 0]) );								// CON
			s_ToneTable[num] = t;
			return 0;
		}
		// テキストからstatic音色テーブルへデータロード（OPM互換）
		public static function loadToneOPM(num:int, str:String):int {
			if (num < 0 || num >= MAX_TONE) return (-1);
			var i:int;
			var n:Number;
			var s:String = str;
			var a:Array;
			var t:Vector.<Number> = new Vector.<Number>(PARAMAX);
			var om:int;
			s = s.replace(/[,;\s\t\r\n]+/gm, ",");
			s = s.replace(/^[,]*/m, '').replace(/[,]*$/m, '');
			a = s.split(",");
			if (a.length < 46 || a.length > 47) return (-2);		//too short or too long
			for (i=0; i<PARAMAX; i++) {
				t[i] = 0.0;
			}
			if (  (a.length == 46) || (String(a[46]).search(/[0-9]/) == (-1))  ) {
				om = (-1);
			}
			else {
				om = int(a[46]);
			}
			for (i=OP1; i<OPMAX; i++) {
				t[ 0 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 0 + s_of2[i] ]) );		// AR
				t[ 1 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 1 + s_of2[i] ]) );		// D1R
				t[ 2 + s_ofs[i] ] = limitNum( 0.0, 31.0, Number(a[ 2 + s_of2[i] ]) );		// D2R
				t[ 3 + s_ofs[i] ] = limitNum( 0.0, 15.0, Number(a[ 3 + s_of2[i] ]) );		// RR
				t[ 4 + s_ofs[i] ] = limitNum( 0.0, 15.0, Number(a[ 4 + s_of2[i] ]) );		// D1L
				t[ 5 + s_ofs[i] ] = limitNum( 0.0,127.0, Number(a[ 5 + s_of2[i] ]) );		// TL
				t[ 6 + s_ofs[i] ] = limitNum( 0.0,  3.0, Number(a[ 6 + s_of2[i] ]) );		// KS
				t[ 7 + s_ofs[i] ] = limitNum( 0.0, 16.0, getUFraction( String(a[ 7 + s_of2[i] ])) );	// MUL
				t[ 8 + s_ofs[i] ] = limitNum( 0.0,  7.0, Number(a[ 8 + s_of2[i] ]) );		// DT1
				t[ 9 + s_ofs[i] ] = limitNum( 0.0,  3.0, Number(a[ 9 + s_of2[i] ]) );		// DT2
				t[10 + s_ofs[i] ] = limitNum( 0.0,  1.0, Number(a[10 + s_of2[i] ]) );		// AME
				if (om >= 0) {
					switch(i){
						case OP1:	t[11 + s_ofs[i] ] = ((om & 1) != 0) ? 0.0 : 1.0;	break;	//MSK
						case OP2:	t[11 + s_ofs[i] ] = ((om & 2) != 0) ? 0.0 : 1.0;	break;
						case OP3:	t[11 + s_ofs[i] ] = ((om & 4) != 0) ? 0.0 : 1.0;	break;
						case OP4:	t[11 + s_ofs[i] ] = ((om & 8) != 0) ? 0.0 : 1.0;	break;
					}
				}
				else {
					switch(i){
						case OP1:	t[11 + s_ofs[i] ] = 0.0;	break;
						case OP2:	t[11 + s_ofs[i] ] = 0.0;	break;
						case OP3:	t[11 + s_ofs[i] ] = 0.0;	break;
						case OP4:	t[11 + s_ofs[i] ] = 0.0;	break;
					}
				}
				if (i == OP1) {
					t[12 + s_ofs[i] ] = limitNum( 0.0,  8.0, Number(a[1]) );		// FB: 0-8...0,pi/16,pi/8,pi/4,pi/2,pi,2pi,4pi,8pi
				}
				else {
					t[12 + s_ofs[i] ] = 0.0;
				}
				t[13 + s_ofs[i] ] = 0.0;											// DT3
				t[14 + s_ofs[i] ] = (-1.0);											// AI
			}
			t[ 0] = limitNum( 0.0,  7.0, Number(a[ 0]) );							// CON
			s_ToneTable[num] = t;
			return 0;
		}
		private function selectTone(t:Vector.<Number>):void {
			var i:int;
			for (i=OP1; i<OPMAX; i++) {
				setAR(  i, int(t[ 0 + s_ofs[i] ]));
				setD1R( i, int(t[ 1 + s_ofs[i] ]));
				setD2R( i, int(t[ 2 + s_ofs[i] ]));
				setRR(  i, int(t[ 3 + s_ofs[i] ]));
				setD1L( i, int(t[ 4 + s_ofs[i] ]));
				setTL(  i, int(t[ 5 + s_ofs[i] ]));
				setKS(  i, int(t[ 6 + s_ofs[i] ]));
				setMUL( i,     t[ 7 + s_ofs[i] ] );
				setDT1( i, int(t[ 8 + s_ofs[i] ]));
				setDT2( i, int(t[ 9 + s_ofs[i] ]));
				setAME( i, int(t[10 + s_ofs[i] ]));
				setMSK( i, int(t[11 + s_ofs[i] ]));
				setFB(  i,     t[12 + s_ofs[i] ] );
				setDT3( i,     t[13 + s_ofs[i] ] );
				setAI(  i, int(t[14 + s_ofs[i] ]));
			}
			setCON( int(t[ 0]) );
			resetFBbufALLOP();
			resetPhaseExecALLOP();
		}
		private function setCON(val:int):void {
			switch(val) {
				case 0:
				default:
					m_getValue = getValueAL00;
					break;
				case 1:
					m_getValue = getValueAL01;
					break;
				case 2:
					m_getValue = getValueAL02;
					break;
				case 3:
					m_getValue = getValueAL03;
					break;
				case 4:
					m_getValue = getValueAL04;
					break;
				case 5:
					m_getValue = getValueAL05;
					break;
				case 6:
					m_getValue = getValueAL06;
					break;
				case 7:
					m_getValue = getValueAL07;
					break;
			}
		}
		private function setFB(op:int, val:Number):void {
			OP[op].SetFL(val, m_FbLvBIAS);
		}
		private function setMSK(op:int, val:int):void {
			if (val != 0) OP[op].SetTL(127);
		}
		private function setAR(op:int, val:int):void {
			OP[op].SetAR(val);
		}
		private function setD1R(op:int, val:int):void {
			OP[op].SetD1R(val);
		}
		private function setD2R(op:int, val:int):void {
			OP[op].SetD2R(val);
		}
		private function setRR(op:int, val:int):void {
			OP[op].SetRR(val);
		}
		private function setD1L(op:int, val:int):void {
			OP[op].SetD1L(val);
		}
		private function setTL(op:int, val:int):void {
			OP[op].SetTL(  int( limitNum(0.0, 127.0, (Number(val) + m_Y_TL[op])) )  );
		}
		private function setKS(op:int, val:int):void {
			OP[op].SetKS(val);
		}
		private function setMUL(op:int, val:Number):void {
			OP[op].SetMUL(val);
		}
		private function setDT1(op:int, val:int):void {
			OP[op].SetDT1(val);
		}
		private function setDT2(op:int, val:int):void {
			OP[op].SetDT2(val);
		}
		private function setDT3(op:int, val:Number):void {
			var DT3:Number;
			DT3 = Math.pow(2.0, (  limitNum(DT3MIN, DT3MAX, (val + m_Y_DT3[op]))  /1200.0));
			OP[op].SetDT3(DT3);
		}
		private function setAME(op:int, val:int):void {
			OP[op].SetAME(val);
		}
		private function setAI(op:int, val:int):void {
			if (m_EgResetMode == false) {
				OP[op].SetAI(val);
			}
			else {
				OP[op].SetAI(126);			//強制モード発動時
			}
		}
		
		private function getValueAL00():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].inp = OP[OP2].out;
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp = OP[OP3].out;
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP4].out;
		}
		private function getValueAL01():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].inp += OP[OP2].out;
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp = OP[OP3].out;
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP4].out;
		}
		private function getValueAL02():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].inp = OP[OP2].out;
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp += OP[OP3].out;
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP4].out;
		}
		private function getValueAL03():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp = OP[OP2].out;
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp += OP[OP3].out;
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP4].out;
		}
		private function getValueAL04():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].inp = OP[OP3].out;
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP2].out + OP[OP4].out;
		}
		private function getValueAL05():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].inp = OP[OP1].out;
			OP[OP3].inp = OP[OP1].out;
			OP[OP4].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP2].out + OP[OP3].out + OP[OP4].out;
		}
		private function getValueAL06():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].inp = OP[OP1].out;
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP2].out + OP[OP3].out + OP[OP4].out;
		}
		private function getValueAL07():void {
			OP[OP1].OutputS(m_lfopitch, m_lfolevel);
			OP[OP2].OutputS(m_lfopitch, m_lfolevel);
			OP[OP3].OutputS(m_lfopitch, m_lfolevel);
			OP[OP4].OutputS(m_lfopitch, m_lfolevel);
			m_OpOut = OP[OP1].out + OP[OP2].out + OP[OP3].out + OP[OP4].out;
		}
		
		public override function getNextSample():Number {
			if (m_compleCount > 0) {
				//ノートオン時のプチノイズ軽減
				--m_compleCount;
				m_compleWorkVal += m_compleDelta;
				return m_compleWorkVal;
			}
			m_rate -= s_OpmRateN;
			while (m_rate < 0.0) {
				m_rate += s_SamprateN;
				if ((--m_EnvCounter2) == 0) {
					m_EnvCounter2 = 3;
					++m_EnvCounter1;
					OP[OP1].Envelope(m_EnvCounter1);
					OP[OP2].Envelope(m_EnvCounter1);
					OP[OP3].Envelope(m_EnvCounter1);
					OP[OP4].Envelope(m_EnvCounter1);
				}
			}
			m_lfoUpdate();
			m_lfopitch = m_lfoGetPMV();
			m_lfolevel = m_lfoGetAMV();
			OP[OP1].inp = OP[OP2].inp = OP[OP3].inp = OP[OP4].inp = 0;
			m_getValue();
			
			m_val = m_OpOut * m_outputLV;		//利得を含むm_outputLVにつき、クリッピングしない。
			return m_val;
		}
		
		// 指定サイズ分の音声サンプルを生成
		public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
			var i:int;
			for (i = start; i < end; i++) {
				samples[i] = getNextSample();
			}
		}
		
		public function setVolume(ex:Number):void {
			m_ampLV = ex;
			m_outputLV = m_ampLV / s_LvOfs;
		}
		public function IsPlaying():Boolean {
			var f:Boolean;
			f = OP[OP1].isPlaying() ||
				OP[OP2].isPlaying() ||
				OP[OP3].isPlaying() ||
				OP[OP4].isPlaying();
			return f;
		}
		public function noteOn():void {
			if (m_KeyOn == false) {
				OP[OP1].KeyON();
				OP[OP2].KeyON();
				OP[OP3].KeyON();
				OP[OP4].KeyON();
				m_rate = 0.0;				//sync note-on: env.render
				m_EnvCounter2 = 1;			//sync note-on: env.render
				m_KeyOn = true;
				if (m_lfoGetSYNC() == true) m_lfoResetPhase();
				{
					//ノートオン時のプチノイズ軽減
					var srcV:Number,dstV:Number,diff:Number,a_diff:Number;
					srcV = m_val;
					dstV = getNextSample();
					diff = dstV - srcV;
					a_diff = Math.abs(diff);
					//trace("diff:"+diff+"  dstV:"+dstV+"¥n");
					if (a_diff < 0.03125) {
						m_compleDelta = diff / 1.0;
						m_compleCount = 1;
					}
					else if (a_diff < 0.0625) {
						m_compleDelta = diff / 3.0;
						m_compleCount = 3;
					}
					else if (a_diff < 0.125) {
						m_compleDelta = diff / 6.0;
						m_compleCount = 6;
					}
					else if (a_diff < 0.25) {
						m_compleDelta = diff / 9.0;
						m_compleCount = 9;
					}
					else if (a_diff < 0.5) {
						m_compleDelta = diff / 12.0;
						m_compleCount = 12;
					}
					else {
						m_compleDelta = diff / 15.0;
						m_compleCount = 15;
					}
					m_compleWorkVal = srcV;
				}
			}
		}
		public function noteOff():void {
			if (m_KeyOn == true) {
				OP[OP1].KeyOFF();
				OP[OP2].KeyOFF();
				OP[OP3].KeyOFF();
				OP[OP4].KeyOFF();
				m_KeyOn = false;
			}
		}
		public override function setFrequency(frequency:Number):void {
			m_frequency = frequency;
			m_freqShift = frequency / 44100.0;
			
			//周波数から音程指示コード、キースケール用コードを生成
			var n:int;
			var kc:int;
			var kskc:int;
			var nt:int;
			var note:int;
			var kf:int;
			
			n = int(
					Math.round(   ((12.0 * 64.0) * Math.log(frequency / 440.0) * Math.LOG2E) + (57.0 * 64.0)   )
				);	//周波数からcent scaleのkey code。（o4a = 57）
			
			kc = (limitNumI( ( 1 * 64), ( 96 * 64), n)  /  64);			//o0c+〜o8cの範囲に制限
			kskc = (((kc-1)/12) << 4) | s_KCtable[(kc+1200) % 12];		//KeyScale用コード。o0c+〜o8cへ変換
			
			nt =  limitNumI( (23 * 64), (167 * 64), (n + NOTEOFS));		//発音用 o(-1)c〜o11c の範囲に制限
			note = (nt / 64);
			kf   = (nt % 64);
			
			OP[OP1].SetExKCKF(note, kskc, kf);
			OP[OP2].SetExKCKF(note, kskc, kf);
			OP[OP3].SetExKCKF(note, kskc, kf);
			OP[OP4].SetExKCKF(note, kskc, kf);
		}
		public function resetPhaseExecALLOP():void {
			if (m_phaseResetPoint >= 0.0) {
				m_phase = m_phaseResetPoint;
			}
			else {
				m_phase = Math.random();
			}
			OP[OP1].ResetPhase(m_phase);
			OP[OP2].ResetPhase(m_phase);
			OP[OP3].ResetPhase(m_phase);
			OP[OP4].ResetPhase(m_phase);
		}
		public function resetPhaseExecCheckedOP():void {
			if (m_phaseResetPoint >= 0.0) {
				m_phase = m_phaseResetPoint;
			}
			else {
				m_phase = Math.random();
			}
			if (OP[OP1].isPlaying() == false) OP[OP1].ResetPhase(m_phase) else OP[OP1].RefreshPhase();
			if (OP[OP2].isPlaying() == false) OP[OP2].ResetPhase(m_phase) else OP[OP2].RefreshPhase();
			if (OP[OP3].isPlaying() == false) OP[OP3].ResetPhase(m_phase) else OP[OP3].RefreshPhase();
			if (OP[OP4].isPlaying() == false) OP[OP4].ResetPhase(m_phase) else OP[OP4].RefreshPhase();
		}
		public override function resetPhase():void {
			if (m_phaseOnetimeResetReq == true) {
				resetPhaseExecALLOP();
				m_phaseOnetimeResetReq = false;
			}
			else {
				switch (m_phaseResetMode) {
					case 0:
						break;
					case 1:
					default:
						resetPhaseExecALLOP();
						break;
					case 2:
						resetPhaseExecCheckedOP();
						break;
					case 3:
						resetPhaseExecCheckedOP();
						break;
				}
			}
		}
		public function resetFBbufALLOP():void {
			OP[OP1].ResetFBbuf();
			OP[OP2].ResetFBbuf();
			OP[OP3].ResetFBbuf();
			OP[OP4].ResetFBbuf();
		}
		public function setOPMEgResetMode(mode:Boolean):void {
			m_EgResetMode = mode;
			if (m_EgResetMode == true) {
				setAI(OP1, 126);
				setAI(OP2, 126);
				setAI(OP3, 126);
				setAI(OP4, 126);
			}
			else {
				// Attack のスタートは現在の音色定義内データに従う
				setAI(OP1, s_ToneTable[m_curTone][15]);
				setAI(OP2, s_ToneTable[m_curTone][30]);
				setAI(OP3, s_ToneTable[m_curTone][45]);
				setAI(OP4, s_ToneTable[m_curTone][60]);
			}
		}
		public function setHLFOMODE(val:int):void {
			if (val == 0) {
				m_lfoMode = true;
				m_lfoUpdate = lfo.Update;
				m_lfoGetPMV = lfo.GetPmValue;
				m_lfoGetAMV = lfo.GetAmValue;
				m_lfoGetSYNC = lfo.GetSyncMode;
				m_lfoResetPhase = lfo.ResetPhase;
			}
			else {
				m_lfoMode = false;
				m_lfoUpdate = lfoA.Update;
				m_lfoGetPMV = lfoA.GetPmValue;
				m_lfoGetAMV = lfoA.GetAmValue;
				m_lfoGetSYNC = lfoA.GetSyncMode;
				m_lfoResetPhase = lfoA.ResetPhase;
			}
		}
		public function setWF(val:int):void {
			lfo.SetWaveForm(val);
		}
		public function setLFRQ(val:int):void {
			lfo.SetLFRQ(val);
		}
		public function setPMD(val:int):void {
			lfo.SetPMDAMD( ((val|0x80) & 0x0ff) );
		}
		public function setAMD(val:int):void {
			lfo.SetPMDAMD( (val&0x7f) );
		}
		public function setPMSAMS(val:int):void {
			lfo.SetPMSAMS(val);
		}
		public function setSYNC(val:int):void {
			if (val == 0) { lfo.SetSYNC(false); }
			else          { lfo.SetSYNC(true); }
		}
		public function setLFRQa(val:int):void {
			lfoA.SetLFRQ(val);
		}
		public function setAMSPMSa(val:int):void {
			lfoA.SetAMSPMS(val);
		}
		public function setSYNCa(val:int):void {
			if (val == 0) { lfoA.SetSYNC(false); }
			else          { lfoA.SetSYNC(true); }
		}
		
		public override function setWaveNo(toneNo:int):void {
			var n:int = toneNo;
			if (n >= MAX_TONE) n = MAX_TONE-1;
			if (n < 0) n = 0;
			if (s_ToneTable[n] == null) n = 0;
			selectTone(s_ToneTable[n]);
			m_curTone = n;						//現在の音色番号を保持
		}
		
		public override function setYControl(m:int, f:int, n:Number):void {
			var status:Boolean;
			var value:Number;
			var i:int;
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
			
			case 5:		//sp.func.5: OPM_EG_Reset_MODE
				status = (n == 0.0) ? false : true;
				setOPMEgResetMode(status);
				break;
			
			case 6:		//sp.func.6: OPM Feedback-Level BIAS
				m_FbLvBIAS = limitNum(FBBIASMIN,FBBIASMAX,n);
				for (i=0; i<OPMAX; i++) {
					setFB(i, s_ToneTable[m_curTone][s_ofs[i]+12]);
				}
				break;
			
			case 10:	//sp.func.10: OP1-OP4 Detune3/TL add.param.reset
				for (i=0; i<OPMAX; i++) {
					m_Y_DT3[i] = 0.0;
					m_Y_TL[i]  = 0;
					setDT3(i, s_ToneTable[m_curTone][13 + s_ofs[i]]);
					setTL( i, s_ToneTable[m_curTone][ 5 + s_ofs[i]]);
				}
				break;
			case 11:	//sp.func.11: add OP1-Detune3
				m_Y_DT3[OP1] = n;
				//refresh MUL/DT3
				setDT3(OP1, s_ToneTable[m_curTone][13 + s_ofs[OP1]]);
				break;
			case 12:	//sp.func.12: add OP1-TL
				m_Y_TL[OP1] = int(n);
				//refresh TL
				setTL(OP1, s_ToneTable[m_curTone][ 5 + s_ofs[OP1]]);
				break;
			case 21:	//sp.func.21: add OP2-Detune3
				m_Y_DT3[OP2] = n;
				//refresh MUL/DT3
				setDT3(OP2, s_ToneTable[m_curTone][13 + s_ofs[OP2]]);
				break;
			case 22:	//sp.func.22: add OP2-TL
				m_Y_TL[OP2] = int(n);
				//refresh TL
				setTL(OP2, s_ToneTable[m_curTone][ 5 + s_ofs[OP2]]);
				break;
			case 31:	//sp.func.31: add OP3-Detune3
				m_Y_DT3[OP3] = n;
				//refresh MUL/DT3
				setDT3(OP3, s_ToneTable[m_curTone][13 + s_ofs[OP3]]);
				break;
			case 32:	//sp.func.32: add OP3-TL
				m_Y_TL[OP3] = int(n);
				//refresh TL
				setTL(OP3, s_ToneTable[m_curTone][ 5 + s_ofs[OP3]]);
				break;
			case 41:	//sp.func.41: add OP4-Detune3
				m_Y_DT3[OP4] = n;
				//refresh MUL/DT3
				setDT3(OP4, s_ToneTable[m_curTone][13 + s_ofs[OP4]]);
				break;
			case 42:	//sp.func.42: add OP4-TL
				m_Y_TL[OP4] = int(n);
				//refresh TL
				setTL(OP4, s_ToneTable[m_curTone][ 5 + s_ofs[OP4]]);
				break;
			
			case 50:	//sp.func.50: HARD LFO mode [OPM/OPNA]
				setHLFOMODE(int(limitNum(0.0,1.0,n)));
				break;
			case 51:	//sp.func.51: OPM HARD LFO wf
				setWF(int(limitNum(0.0,3.0,n)));
				break;
			case 52:	//sp.func.52: OPM HARD LFO lfreq
				setLFRQ(int(limitNum(0.0,255.0,n)));
				break;
			case 53:	//sp.func.53: OPM HARD LFO pmd
				setPMD(int(limitNum(0.0,127.0,n)));
				break;
			case 54:	//sp.func.54: OPM HARD LFO amd
				setAMD(int(limitNum(0.0,127.0,n)));
				break;
			case 55:	//sp.func.55: OPM HARD LFO pms/ams
				setPMSAMS(int(limitNum(0.0,255.0,n)));
				break;
			case 56:	//sp.func.56: OPM HARD LFO sync
				setSYNC(int(limitNum(0.0,1.0,n)));
				break;
			case 57:	//sp.func.57: OPM Hard LFO Speed adjust
				m_HLFO_OPMSP = limitNum(HLFOSPMIN, HLFOSPMAX, n);
				lfo.InitSamprate(s_OpmRateN * m_HLFO_OPMSP);
				break;
			case 61:	//sp.func.61: OPNA HARD LFO lfreq
				setLFRQa(int(limitNum(0.0,7.0,n)));
				break;
			case 62:	//sp.func.62: OPNA HARD LFO ams/pms
				setAMSPMSa(int(limitNum(0.0,255.0,n)));
				break;
			case 63:	//sp.func.63: OPNA HARD LFO sync
				setSYNCa(int(limitNum(0.0,1.0,n)));
				break;
			case 64:	//sp.func.64: OPNA Hard LFO Speed adjust
				m_HLFO_OPNASP = limitNum(HLFOSPMIN, HLFOSPMAX, n);
				lfoA.InitSamprate((OPNACLK39936 / 72.0) * m_HLFO_OPNASP);
				break;
			}
		}
	}
}