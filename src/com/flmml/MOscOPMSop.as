package com.flmml {
	import __AS3__.vec.Vector;

	/**
	 * FM sound generator 'OPMS' operator unit
	 * @author LinearDrive
	 */
	public class MOscOPMSop {
		private var m_id:int;
		private static var s_init:int = 0;
		
		public  static const SIZEALPHATBL_BITS:int = (15);
		private static const SIZEALPHATBL:int      = (1<<SIZEALPHATBL_BITS);
		private static const ALPHAZERO:int         = (SIZEALPHATBL*3);
		private static const EL2DL:int             = (SIZEALPHATBL_BITS - 6);
		private static const ELMIN:int             = (SIZEALPHATBL);
		private static const ELATROUND:int         = int( Math.pow(2.0, Number(SIZEALPHATBL_BITS - 10)) );
		
		public  static const SIZESINTBL_BITS:int   = (17);
		private static const SIZESINTBL:int        = (1<<SIZESINTBL_BITS);
		private static const MAXSINVAL:Number      = Number((1<<(SIZESINTBL_BITS+2)) - 1);
		private static const MASKPHASE:Number      = Number(SIZESINTBL);
		
		private static const KEYON:int       = (-1);
		private static const ATACK:int       = 0;
		private static const DECAY:int       = 1;
		private static const SUSTAIN:int     = 2;
		private static const SUSTAIN_MAX:int = 3;
		private static const RELEASE:int     = 4;
		private static const RELEASE_MAX:int = 5;
		private static const CULC_DELTA_T:int = (0x7FFFFFFF);
		private static const CULC_ALPHA:int   = (0x7FFFFFFF);
		private static const NEXTSTAT:Vector.<int> = Vector.<int>([
			DECAY, SUSTAIN, SUSTAIN_MAX, SUSTAIN_MAX, RELEASE_MAX, RELEASE_MAX,
		]);
		private static const MAXSTAT:Vector.<int> = Vector.<int>([
			ATACK, SUSTAIN_MAX, SUSTAIN_MAX, SUSTAIN_MAX, RELEASE_MAX, RELEASE_MAX,
		]);
		
		private static var ALPHATBL:Vector.<Number>;
		
		private static var SINTBL:Vector.<Number>;
		
		private static var STEPTBL:Vector.<Number>;	//oct(-2..+13),note(c+..>c),kf(0..63) -> 16*12*64=12288個
		
		private static var DT1TBL:Vector.<Number>;	//DT1TBL[128];
		private static var DT1TBL_org:Vector.<int> = Vector.<int>([
			0, 0, 1, 2, 
			0, 0, 1, 2, 
			0, 0, 1, 2, 
			0, 0, 1, 2, 
			0, 1, 2, 2, 
			0, 1, 2, 3, 
			0, 1, 2, 3, 
			0, 1, 2, 3, 
			0, 1, 2, 4, 
			0, 1, 3, 4, 
			0, 1, 3, 4, 
			0, 1, 3, 5, 
			0, 2, 4, 5, 
			0, 2, 4, 6, 
			0, 2, 4, 6, 
			0, 2, 5, 7, 
			0, 2, 5, 8, 
			0, 3, 6, 8, 
			0, 3, 6, 9, 
			0, 3, 7, 10, 
			0, 4, 8, 11, 
			0, 4, 8, 12, 
			0, 4, 9, 13, 
			0, 5, 10, 14, 
			0, 5, 11, 16, 
			0, 6, 12, 17, 
			0, 6, 13, 19, 
			0, 7, 14, 20, 
			0, 8, 16, 22, 
			0, 8, 16, 22, 
			0, 8, 16, 22, 
			0, 8, 16, 22, 
		]);
		
		private static var DT2TBL:Vector.<int> = Vector.<int>([
			0, 384, 500, 608
		]);
		
		private static var D1LTBL:Vector.<int>;		//[16];
		
		private static var XRTBL_and:Vector.<int> = Vector.<int>([		//[64]
			127,
			63,  63,  63,  63,
			31,  31,  31,  31,
			15,  15,  15,  15,
			7,   7,   7,   7,
			3,   3,   3,   3,
			1,   1,   1,   1,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,   0,
			0,   0,   0,
		]);
		private static var XRTBL_add:Vector.<int> = Vector.<int>([		//[64]
			8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			5,   6,   7,   8,
			10,  12,  14,  16,
			20,  24,  28,  32,
			40,  48,  56,  64,
			80,  96,  112, 128,
			160, 192, 224, 256,
			320, 384, 448, 512,
			640, 768, 896, 1024,
			1280,1536,1792,2048,
			2048,2048,2048,
		]);
		
		// フェーズジェネレータ関係
		public  var inp:Number;		// FM変調の入力
		
		private var LfoPitch:int;	// 前回のlfopitch値, CULC_DELTA_T値の時はDeltaTを再計算する。
		private var T:Number;		// 現在時間 (0 <= T < SIZESINTBL*PRECISION)
		private var DeltaT:Number;	// Δt
		private var Ame:int;		// 0(トレモロをかけない), -1(トレモロをかける)
		private var LfoLevel:int;	// 前回のlfopitch&Ame値, CULC_ALPHA値の時はAlphaを再計算する。
		private var Alpha:Number;	// 最終的なエンベロープ出力値
		
		public  var out:Number;		// オペレータの出力先
		
		private var Pitch:int;			// 0<=pitch<10*12*64
		private var Dt1Pitch:Number;	// Step に対する補正量
		private var Mul:Number;			// 0.5, 1, 2, 3, .., 15
		private var Dt3:Number;
		private var MulDt3:Number;
		private var Tl:int;				// (128 - (n & 127)) << (SIZEALPHATBL_BITS - 7)
		
		private var Out2Fb:Number;		// フィードバックへの出力値
		private var Inp_last:Number;	// 最後の入力値
		private var Fl:Number;			// フィードバックレベルのシフト値(31,7,6,5,4,3,2,1)
		
		// エンベロープ関係
		private var Xr_stat:int;
		private var Xr_el:int;
		private var Xr_step:int;
		private var Xr_and:int;
		private var Xr_cmp:int;
		private var Xr_add:int;
		private var Xr_limit:int;
		
		private var Note:int;		// 音階 (0 <= Note < 10*12)
		private var Kc:int;			// 音階 (1 <= Kc <= 127)
		private var Kf:int;			// 微調整 (0 <= Kf <= 63)
		private var Ar:int;			// 0 <= Ar <= 31
		private var D1r:int;		// 0 <= D1r <= 31
		private var D2r:int;		// 0 <= D2r <= 31
		private var Rr:int;			// 0 <= Rr <= 15
		private var Ks:int;			// 0 <= Ks <= 3
		private var Dt1:int;		// DT1の値(0〜7)
		private var Dt2:int;		// Pitch に対する補正量(0, 384, 500, 608)
		
		private var AI:int;			// Attack時の初期レベル(-1=通常。初期値設定なし。0=レベル最大で初期化。128=レベル最小で初期化。)
		
		// 状態推移テーブル StatTbl[RELEASE_MAX+1]
		private var StatTbl_and:Vector.<int>;
		private var StatTbl_cmp:Vector.<int>;
		private var StatTbl_add:Vector.<int>;
		private var StatTbl_limit:Vector.<int>;
		//           ATACK     DECAY   SUSTAIN     SUSTAIN_MAX RELEASE     RELEASE_MAX
		// and     :                               129                     129
		// cmp     :                               64                      64
		// add     :                               0                       0
		// limit   : 0         D1l     63          63          63          63
		// nextstat: DECAY     SUSTAIN SUSTAIN_MAX SUSTAIN_MAX RELEASE_MAX RELEASE_MAX
		
		public function MOscOPMSop() {
			boot();
			
			StatTbl_and   = new Vector.<int>(RELEASE_MAX+1);
			StatTbl_cmp   = new Vector.<int>(RELEASE_MAX+1);
			StatTbl_add   = new Vector.<int>(RELEASE_MAX+1);
			StatTbl_limit = new Vector.<int>(RELEASE_MAX+1);
		}
		
		public static function boot():void {
			if (s_init != 0) return;
			//スタティック属性の初期化処理
			MakeTable();
			s_init = 1;
		}
		
		public static function MakeTable():void {
			var i:int;
			// sinテーブルを作成
			SINTBL = new Vector.<Number>(SIZESINTBL+1);
			for (i=0; i<=SIZESINTBL; ++i) {
				SINTBL[i] =
					Math.sin(2.0 * Math.PI * Number(i) / Number(SIZESINTBL))  *  MAXSINVAL;
			}
			// エンベロープ値 → α 変換テーブルを作成
			ALPHATBL = new Vector.<Number>(ALPHAZERO+SIZEALPHATBL+1);
			for (i=0; i<=ALPHAZERO+SIZEALPHATBL; ++i) {
				ALPHATBL[i] = 0.0;
			}
			for (i=(SIZEALPHATBL/128); i<=SIZEALPHATBL; ++i) {
				ALPHATBL[ALPHAZERO+i] =
					Math.pow(2.0, (-1.0 * (Number(SIZEALPHATBL - i))) * (128.0/8.0) / Number(SIZEALPHATBL) );
			}
			// D1L変換テーブルを作成
			D1LTBL = new Vector.<int>(16);
			for (i=0; i<15; ++i) {
				D1LTBL[i] = i*2;
			}
			D1LTBL[15] = (15+16)*2;
			
			// Pitch→Δt変換テーブルを作成
			var	oct:int;
			var octofs:int = (-5);
			var	notekf:int;
			var sinsize:Number = Number(SIZESINTBL);
			var fSAM:Number = MOscOPMS.s_SamprateN;
			STEPTBL = new Vector.<Number>(16*12*64);
			for (oct=(-2); oct<=13; ++oct) {
				// オクターブごとに c+ から >c までの 64分割スケール のΔtテーブルを作成
				for (notekf=0; notekf<12*64; ++notekf) {
					STEPTBL[(oct+2)*12*64+notekf] = 
						(
							440.0
							* Math.pow( 2.0, Number(oct + octofs) )
							* Math.pow( 2.0, ((Number(notekf) - (8.0*64.0)) / 768.0) )		//c+からスタート
						)
						* sinsize / fSAM
						;
					//trace("step", (oct+2)*12*64+notekf,"=",STEPTBL[(oct+2)*12*64+notekf]);
				}
			}
			//DT1テーブル作成
			var dfs:Number = MOscOPMS.s_OpmRateN / MOscOPMS.s_SamprateN;
			var dtofs:Number = Math.pow(2.0, Number(SIZESINTBL_BITS - 20) ) * dfs;
			DT1TBL  = new Vector.<Number>(128);
			for (i=0; i<128; ++i) {
				DT1TBL[i] = (Number(DT1TBL_org[i])) * dtofs;
			}
		}
		
		public function Init(id:int):void {
			m_id = id;
			
			Note = 5*12+8;
			Kc = 5*16+8 + 1;
			Kf = 5;
			Ar = 10;
			D1r = 10;
			D2r = 5;
			Rr = 12;
			Ks = 1;
			Dt2 = 0;
			Dt1 = 0;
			
			Fl = 0.0;
			Out2Fb = 0.0;
			inp = 0.0;
			Inp_last = 0.0;
			DeltaT = 0.0;
			LfoPitch = CULC_DELTA_T;
			T = 0.0;
			LfoLevel = CULC_ALPHA;
			Alpha = 0.0;
			Tl = (128-127) << (SIZEALPHATBL_BITS - 7);
			Xr_el = ELMIN;
			Xr_step = 0;
			Mul = 1.0;
			Dt3 = 1.0;
			MulDt3 = Mul * Dt3;
			Ame = 0;
			
			AI = (-1);
			
			StatTbl_limit[ATACK] = 0;
			StatTbl_limit[DECAY] = D1LTBL[0];
			StatTbl_limit[SUSTAIN] = 63;
			StatTbl_limit[SUSTAIN_MAX] = 63;
			StatTbl_limit[RELEASE] = 63;
			StatTbl_limit[RELEASE_MAX] = 63;
			
			StatTbl_and[SUSTAIN_MAX] = 129;
			StatTbl_cmp[SUSTAIN_MAX] = 64;
			StatTbl_add[SUSTAIN_MAX] = 0;
			
			StatTbl_and[RELEASE_MAX] = 129;
			StatTbl_cmp[RELEASE_MAX] = 64;
			StatTbl_add[RELEASE_MAX] = 0;
			
			Xr_stat = RELEASE_MAX;
			Xr_and = StatTbl_and[Xr_stat];
			Xr_cmp = StatTbl_cmp[Xr_stat];
			Xr_add = StatTbl_add[Xr_stat];
			Xr_limit = StatTbl_limit[Xr_stat];
			
			CulcArStep();
			CulcD1rStep();
			CulcD2rStep();
			CulcRrStep();
			CulcPitch();
			CulcDt1Pitch();
		}
		
		public function InitSamprate():void {
			LfoPitch = CULC_DELTA_T;
			
			CulcArStep();
			CulcD1rStep();
			CulcD2rStep();
			CulcRrStep();
			CulcPitch();
			CulcDt1Pitch();
		}
		
		public function CulcArStep():void {
			if (Ar != 0) {
				var ks:int = (Ar<<1)+(Kc>>(5-Ks));
				if (ks > 63) ks = 63;
				StatTbl_and[ATACK] = XRTBL_and[ks];
				StatTbl_cmp[ATACK] = XRTBL_and[ks]>>1;
				if (ks < 62) {
					StatTbl_add[ATACK] = XRTBL_add[ks];
				} else {
					StatTbl_add[ATACK] = 4096;
				}
			} else {
				StatTbl_and[ATACK] = 129;
				StatTbl_cmp[ATACK] = 64;
				StatTbl_add[ATACK] = 0;
			}
			if (Xr_stat == ATACK) {
				Xr_and = StatTbl_and[Xr_stat];
				Xr_cmp = StatTbl_cmp[Xr_stat];
				Xr_add = StatTbl_add[Xr_stat];
			}
		}
		
		public function CulcD1rStep():void {
			if (D1r != 0) {
				var ks:int = (D1r<<1)+(Kc>>(5-Ks));
				if (ks > 63) ks = 63;
				StatTbl_and[DECAY] = XRTBL_and[ks];
				StatTbl_cmp[DECAY] = XRTBL_and[ks]>>1;
				StatTbl_add[DECAY] = XRTBL_add[ks];
			} else {
				StatTbl_and[DECAY] = 129;
				StatTbl_cmp[DECAY] = 64;
				StatTbl_add[DECAY] = 0;
			}
			if (Xr_stat == DECAY) {
				Xr_and = StatTbl_and[Xr_stat];
				Xr_cmp = StatTbl_cmp[Xr_stat];
				Xr_add = StatTbl_add[Xr_stat];
			}
		}
		
		public function CulcD2rStep():void {
			if (D2r != 0) {
				var ks:int = (D2r<<1)+(Kc>>(5-Ks));
				if (ks > 63) ks = 63;
				StatTbl_and[SUSTAIN] = XRTBL_and[ks];
				StatTbl_cmp[SUSTAIN] = XRTBL_and[ks]>>1;
				StatTbl_add[SUSTAIN] = XRTBL_add[ks];
			} else {
				StatTbl_and[SUSTAIN] = 129;
				StatTbl_cmp[SUSTAIN] = 64;
				StatTbl_add[SUSTAIN] = 0;
			}
			if (Xr_stat == SUSTAIN) {
				Xr_and = StatTbl_and[Xr_stat];
				Xr_cmp = StatTbl_cmp[Xr_stat];
				Xr_add = StatTbl_add[Xr_stat];
			}
		}
		
		public function CulcRrStep():void {
			var ks:int = (Rr<<2)+2+(Kc>>(5-Ks));
			if (ks > 63) ks = 63;
			StatTbl_and[RELEASE] = XRTBL_and[ks];
			StatTbl_cmp[RELEASE] = XRTBL_and[ks]>>1;
			StatTbl_add[RELEASE] = XRTBL_add[ks];
			if (Xr_stat == RELEASE) {
				Xr_and = StatTbl_and[Xr_stat];
				Xr_cmp = StatTbl_cmp[Xr_stat];
				Xr_add = StatTbl_add[Xr_stat];
			}
		}
		
		public function CulcPitch():void {
			Pitch = (Note<<6)+Kf+Dt2;
		}
		
		public function CulcDt1Pitch():void {
			Dt1Pitch = DT1TBL[(Kc & 0xFC)+(Dt1 & 3)];
			if ((Dt1 & 0x04) != 0) {
				Dt1Pitch = Dt1Pitch * (-1.0);
			}
			Dt1Pitch = Dt1Pitch * Mul;
		}
		
		public function SetFL(n:Number, bias:Number):void {
			if (n <= 0.0) {
				Fl = 0.0;
			}
			else {
				//7->2^(-2), 6->2^(-3), 5->2^(-4), 4->2^(-5), 3->2^(-6), 2->2^(-7), 1->2^(-8), 0->0
				Fl = bias * Math.pow(2.0, Number(n - 9.0));
			}
		}
		
		// 新周波数設定。Note/KeyCodeの分離。KeyCodeはKeyScaling設定目的に使用
		public function SetExKCKF(noteNum:int, keyCD:int, keyFR:int):void {
			Note = noteNum;			//o0cサポートのため直接入力
			Kc = keyCD & 127;		//for key scaling: o0cはo0c+同様のkey scalingとする
			++Kc;
			Kf = keyFR & 63;
			CulcPitch();
			CulcDt1Pitch();
			LfoPitch = CULC_DELTA_T;
			CulcArStep();
			CulcD1rStep();
			CulcD2rStep();
			CulcRrStep();
		}
		
		public function SetDT1(n:int):void {
			Dt1 = n & 7;
			CulcDt1Pitch();
			LfoPitch = CULC_DELTA_T;
		}
		
		public function SetMUL(n:Number):void {
			if (n <= 0.0) {
				Mul = 0.5;
			}
			else {
				Mul = n;
			}
			MulDt3 = Mul * Dt3;
			CulcDt1Pitch();
			LfoPitch = CULC_DELTA_T;
		}
		
		public function SetTL(n:int):void {
			Tl = (128 - (n & 127)) << (SIZEALPHATBL_BITS - 7);
			LfoLevel = CULC_ALPHA;
		}
		
		public function SetKS(n:int):void {
			Ks = n & 3;
			CulcArStep();
			CulcD1rStep();
			CulcD2rStep();
			CulcRrStep();
		}
		
		public function SetAR(n:int):void {
			Ar = n & 31;
			CulcArStep();
		}
		
		public function SetAME(n:int):void {
			Ame = 0;
			if (n != 0) {
				Ame = -1;
			}
		}
		
		public function SetD1R(n:int):void {
			D1r = n & 31;
			CulcD1rStep();
		}
		
		public function SetDT2(n:int):void {
			Dt2 = DT2TBL[(n & 3)];
			CulcPitch();
			LfoPitch = CULC_DELTA_T;
		}
		
		public function SetDT3(n:Number):void {
			Dt3 = n;
			MulDt3 = Mul * Dt3;
			LfoPitch = CULC_DELTA_T;
		}
		
		public function SetD2R(n:int):void {
			D2r = n & 31;
			CulcD2rStep();
		}
		
		public function SetD1L(n:int):void {
			StatTbl_limit[DECAY] = D1LTBL[(n & 15)];
			if (Xr_stat == DECAY) {
				Xr_limit = StatTbl_limit[DECAY];
			}
		}
		
		public function SetRR(n:int):void {
			Rr = n & 15;
			CulcRrStep();
		}
		
		public function SetAI(n:int):void {
			var i:int = n;
			if (i <   0) i = (-1);
			if (i > 128) i =  128;
			if (i >= 0) {
				AI = i << (SIZEALPHATBL_BITS - 7);
			}
			else {
				AI = i;
			}
		}
		
		public function ResetFBbuf():void {
			Out2Fb = 0.0;
			Inp_last = 0.0;
		}
		
		public function ResetPhase(phase:Number):void {
			T = phase * MASKPHASE;
			RefreshPhase();
			ResetFBbuf();
		}
		
		public function RefreshPhase():void {
			T = T % MASKPHASE;				//繰り上がり部分のみ対処
		}
		
		public function KeyON():void {
			if (Xr_stat >= RELEASE) {
				// KEYON
				// ResetPhase();	//上位層の管理に任せる
				
				if (AI >= 0) {
					Xr_el = AI;
				}
				
				if (Xr_el == 0) {
					Xr_stat = DECAY;
					Xr_and = StatTbl_and[Xr_stat];
					Xr_cmp = StatTbl_cmp[Xr_stat];
					Xr_add = StatTbl_add[Xr_stat];
					Xr_limit = StatTbl_limit[Xr_stat];
					if ((Xr_el>>EL2DL) == Xr_limit) {
						Xr_stat = NEXTSTAT[Xr_stat];
						Xr_and = StatTbl_and[Xr_stat];
						Xr_cmp = StatTbl_cmp[Xr_stat];
						Xr_add = StatTbl_add[Xr_stat];
						Xr_limit = StatTbl_limit[Xr_stat];
					}
				} else {
					Xr_stat = ATACK;
					Xr_and = StatTbl_and[Xr_stat];
					Xr_cmp = StatTbl_cmp[Xr_stat];
					Xr_add = StatTbl_add[Xr_stat];
					Xr_limit = StatTbl_limit[Xr_stat];
				}
			}
		}
		
		public function KeyOFF():void {
			Xr_stat = RELEASE;
			Xr_and = StatTbl_and[Xr_stat];
			Xr_cmp = StatTbl_cmp[Xr_stat];
			Xr_add = StatTbl_add[Xr_stat];
			Xr_limit = StatTbl_limit[Xr_stat];
			if ((Xr_el>>EL2DL) >= 63) {
				Xr_el = ELMIN;
				Xr_stat = MAXSTAT[Xr_stat];
				Xr_and = StatTbl_and[Xr_stat];
				Xr_cmp = StatTbl_cmp[Xr_stat];
				Xr_add = StatTbl_add[Xr_stat];
				Xr_limit = StatTbl_limit[Xr_stat];
			}
		}
		
		public function Envelope(env_counter:int):void {
			if ((env_counter&Xr_and) == Xr_cmp) {
				
				if (Xr_stat == ATACK) {
					// ATACK
					Xr_step += Xr_add;
					Xr_el += (((~Xr_el)*(Xr_step>>3)) >> EL2DL);
					LfoLevel = CULC_ALPHA;
					Xr_step &= 7;
					
					if (Xr_el < ELATROUND) {
						Xr_el = 0;
						Xr_stat = DECAY;
						Xr_and = StatTbl_and[Xr_stat];
						Xr_cmp = StatTbl_cmp[Xr_stat];
						Xr_add = StatTbl_add[Xr_stat];
						Xr_limit = StatTbl_limit[Xr_stat];
						if ((Xr_el>>EL2DL) == Xr_limit) {
							Xr_stat = NEXTSTAT[Xr_stat];
							Xr_and = StatTbl_and[Xr_stat];
							Xr_cmp = StatTbl_cmp[Xr_stat];
							Xr_add = StatTbl_add[Xr_stat];
							Xr_limit = StatTbl_limit[Xr_stat];
						}
					}
					
				} else {
					// DECAY, SUSTAIN, RELEASE
					Xr_step += Xr_add;
					Xr_el += (Xr_step>>3);
					LfoLevel = CULC_ALPHA;
					Xr_step &= 7;
					
					var e:int = (Xr_el>>EL2DL);
					if (e == 63) {
						Xr_el = ELMIN;
						Xr_stat = MAXSTAT[Xr_stat];
						Xr_and = StatTbl_and[Xr_stat];
						Xr_cmp = StatTbl_cmp[Xr_stat];
						Xr_add = StatTbl_add[Xr_stat];
						Xr_limit = StatTbl_limit[Xr_stat];
					} else if (e == Xr_limit) {
						Xr_stat = NEXTSTAT[Xr_stat];
						Xr_and = StatTbl_and[Xr_stat];
						Xr_cmp = StatTbl_cmp[Xr_stat];
						Xr_add = StatTbl_add[Xr_stat];
						Xr_limit = StatTbl_limit[Xr_stat];
					}
				}
				
			}
		}
		
		public function OutputS(lfopitch:int, lfolevel:int):void {
			if (LfoPitch != lfopitch) {
				//DeltaT = ((STEPTBL[Pitch+lfopitch]+Dt1Pitch)*Mul)>>1;
				//DeltaT = ((STEPTBL[Pitch+lfopitch]+Dt1Pitch)*Mul)>>(6+1);
				//Pitch+lfopitchの範囲制限はテーブル領域の拡大にて代用（要テーブルサイズ確認）
				DeltaT = ( (STEPTBL[Pitch+lfopitch] * MulDt3) + Dt1Pitch );
				LfoPitch = lfopitch;
			}
			//T = (T + DeltaT) & MASKPHASE;
			T = (T + DeltaT);			//Tのフェーズマスクは簡略化のため位相リセット時のみ行う
			
			var lfolevelame:int = lfolevel & Ame;
			if (LfoLevel != lfolevelame) {
				Alpha = ALPHATBL[ALPHAZERO + Tl - int(Xr_el) - lfolevelame];
				LfoLevel = lfolevelame;
			}
			//var o:int = (Alpha) * SINTBL[(((T+Out2Fb+inp)>>PRECISION_BITS))&(SIZESINTBL-1)];
			var p:Number;
			var o:Number;
			p = T + Out2Fb + inp;
			if (p >= 0) {
				p = p % MASKPHASE;
			}
			else {
				p = p % MASKPHASE;				//ここでのpは負数で得られる
				p = MASKPHASE + p;
			}
			o = (Alpha) * SINTBL[int(p)];
			
			
			//	var o2:int = (o+Inp_last) >> 1;
			//	Out2Fb = (o+o) >> Fl;
			Out2Fb = (o + Inp_last) * Fl;
			Inp_last = o;
			
			out = o;
			
		}
		
		public function isPlaying():Boolean {
			if (Xr_stat >= RELEASE_MAX) {
				return false;
			}
			else {
				return true;
			}
		}
		
	}
}