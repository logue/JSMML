package com.flmml {
	import __AS3__.vec.Vector;

	/**
	 * FM sound generator 'OPMS' LFO unit
	 * @author LinearDrive
	 */
	public class MOscOPMSlfo {
		private static var s_init:int = 0;
		private static var SIZELFOTBL:int = 512;			// 2^9;
		private static var SIZELFOTBL_BITS:int = 9;
		private static var LFOPRECISION:int = 4096;			// 2^12;
		private static var N_CH:int = 8;
		private static const PMSMUL:Vector.<int> = Vector.<int>([ 0,1,2,4,8,16,32,32 ]);
		private static const PMSSHL:Vector.<int> = Vector.<int>([ 0,0,0,0,0, 0, 1, 2 ]);
		private static var PmTbl0:Vector.<int>;
		private static var PmTbl2:Vector.<int>;
		private static var AmTbl0:Vector.<int>;
		private static var AmTbl2:Vector.<int>;
		
		private var Pmsmul:int;					// 0, 1, 2, 4, 8, 16, 32, 32
		private var Pmsshl:int;					// 0, 0, 0, 0, 0,  0,  1,  2
		private var Ams:int;					// 左シフト回数 31(0), 0(1), 1(2), 2(3)
		private var PmdPmsmul:int;				// Pmd*Pmsmul[]
		private var Pmd:int;
		private var Amd:int;
		
		private var LfoStartingFlag:int;		// 0:LFO停止中  1:LFO動作中
		private var LfoOverFlow:int;			// LFO tのオーバーフロー値
		private var LfoTime:int;				// LFO専用 t
		private var LfoTimeAdd:int;				// LFO専用Δt
		private var LfoIdx:int;					// LFOテーブルへのインデックス値
		private var LfoSmallCounter:int;		// LFO周期微調整カウンタ (0〜15の値をとる)
		private var LfoSmallCounterStep:int;	// LFO周期微調整カウンタ用ステップ値 (16〜31)
		private var Lfrq:int;					// LFO周波数設定値 LFRQ
		private var LfoWaveForm:int;			// LFO wave form
		
		private var PmTblValue:int;
		private var AmTblValue:int;
		private var PmValue:int;
		private var AmValue:int;
		
		public function MOscOPMSlfo() {
			boot();
			
			Pmsmul = 0;
			Pmsshl = 0;
			Ams = 31;
			PmdPmsmul = 0;
			
			PmValue = 0;
			AmValue = 0;
				
			Pmd = 0;
			Amd = 0;
			
			LfoStartingFlag = 0;
			LfoOverFlow = 0;
			LfoTime = 0;
			LfoTimeAdd = 0;
			LfoIdx = 0;
			LfoSmallCounter = 0;
			LfoSmallCounterStep = 0;
			Lfrq = 0;
			LfoWaveForm = 0;
			
			PmTblValue = 0;
			AmTblValue = 255;
		}
		
		public static function boot():void {
			if (s_init != 0) return;
			
			//スタティック属性の初期化処理
			var i:int;
			PmTbl0 = new Vector.<int>(SIZELFOTBL);
			PmTbl2 = new Vector.<int>(SIZELFOTBL);
			AmTbl0 = new Vector.<int>(SIZELFOTBL);
			AmTbl2 = new Vector.<int>(SIZELFOTBL);
			// PM Wave Form 0,3
			for (i=0; i<=127; ++i) {
				PmTbl0[i] = i;
				PmTbl0[i+128] = i-127;
				PmTbl0[i+256] = i;
				PmTbl0[i+384] = i-127;
			}
			// AM Wave Form 0,3
			for (i=0; i<=255; ++i) {
				AmTbl0[i] = 255-i;
				AmTbl0[i+256] = 255-i;
			}
			
			// PM Wave Form 2
			for (i=0; i<=127; ++i) {
				PmTbl2[i] = i;
				PmTbl2[i+128] = 127-i;
				PmTbl2[i+256] = -i;
				PmTbl2[i+384] = i-127;
			}
			// AM Wave Form 2
			for (i=0; i<=255; ++i) {
				AmTbl2[i] = 255-i;
				AmTbl2[i+256] = i;
			}
			
			s_init = 1;
		}
		
		public function Init(n:int):void {
			InitSamprate(n);
			
			LfoSmallCounter = 0;
			
			SetLFRQ(0);
			SetPMDAMD(0);
			SetPMDAMD(128+0);
			SetWaveForm(0);
			SetPMSAMS(0);
			LfoReset();
			LfoStart();
		}
		public function InitSamprate(n:int):void {
			LfoTimeAdd = LFOPRECISION * n / MOscOPMS.s_Samprate;
		}
		
		public function LfoReset():void {
			LfoStartingFlag = 0;
			
			//	LfoTime はリセットされない！！
			LfoIdx = 0;
			
			CulcTblValue();
			CulcAllPmValue();
			CulcAllAmValue();
		}
		public function LfoStart():void {
			LfoStartingFlag = 1;
		}
		public function SetLFRQ(n:int):void {
			Lfrq = n & 255;
			
			LfoSmallCounterStep = 16+(Lfrq&15);
			var shift:int = 15-(Lfrq>>4);
			if (shift == 0) {
				shift = 1;
				LfoSmallCounterStep <<= 1;
			}
			LfoOverFlow = (8<<shift) * LFOPRECISION;
			
			//	LfoTime はリセットされる
			LfoTime = 0;
		}
		public function SetPMDAMD(n:int):void {
			if ((n & 0x80) != 0) {
				Pmd = n&0x7F;
				PmdPmsmul = Pmd * Pmsmul;
				CulcAllPmValue();
			} else {
				Amd = n&0x7F;
				CulcAllAmValue();
			}
		}
		public function SetWaveForm(n:int):void {
			LfoWaveForm = n&3;
			
			CulcTblValue();
			CulcAllPmValue();
			CulcAllAmValue();
		}
		public function SetPMSAMS(n:int):void {
			var pms:int = (n>>4)&7;
			Pmsmul = PMSMUL[pms];
			Pmsshl = PMSSHL[pms];
			PmdPmsmul = Pmd*Pmsmul;
			CulcPmValue();
			
			Ams = ((n&3)-1) & 31;
			CulcAmValue();
		}
		
		public function Update():void {
			if (LfoStartingFlag == 0) {
				return;
			}
			
			var idxadd:int;
			LfoTime += LfoTimeAdd;
			if (LfoTime >= LfoOverFlow) {
				LfoTime = 0;
				LfoSmallCounter += LfoSmallCounterStep;
				switch (LfoWaveForm) {
				case 0:
					idxadd = LfoSmallCounter>>4;
					LfoIdx = (LfoIdx+idxadd) & (SIZELFOTBL-1);
					PmTblValue = PmTbl0[LfoIdx];
					AmTblValue = AmTbl0[LfoIdx];
					break;
				case 1:
					idxadd = LfoSmallCounter>>4;
					LfoIdx = (LfoIdx+idxadd) & (SIZELFOTBL-1);
					if ((LfoIdx&(SIZELFOTBL/2-1)) < SIZELFOTBL/4) {
						PmTblValue = 128;
						AmTblValue = 256;
					} else {
						PmTblValue = -128;
						AmTblValue = 0;
					}
					break;
				case 2:
					idxadd = LfoSmallCounter>>4;
					LfoIdx = (LfoIdx+idxadd+idxadd) & (SIZELFOTBL-1);
					PmTblValue = PmTbl2[LfoIdx];
					AmTblValue = AmTbl2[LfoIdx];
					break;
				case 3:
					LfoIdx = int( Math.random() * Number(SIZELFOTBL-1) );
					PmTblValue = PmTbl0[LfoIdx];
					AmTblValue = AmTbl0[LfoIdx];
					break;
				}
				LfoSmallCounter &= 15;
				
				CulcAllPmValue();
				CulcAllAmValue();
			}
		}
		
		public function GetPmValue():int {
			return PmValue;
		}
		public function GetAmValue():int {
			return AmValue;
		}
		
		public function CulcTblValue():void {
			switch (LfoWaveForm) {
			case 0:
				PmTblValue = PmTbl0[LfoIdx];
				AmTblValue = AmTbl0[LfoIdx];
				break;
			case 1:
				if ((LfoIdx&(SIZELFOTBL/2-1)) < SIZELFOTBL/4) {
					PmTblValue = 128;
					AmTblValue = 256;
				} else {
					PmTblValue = -128;
					AmTblValue = 0;
				}
				break;
			case 2:
				PmTblValue = PmTbl2[LfoIdx];
				AmTblValue = AmTbl2[LfoIdx];
				break;
			case 3:
				PmTblValue = PmTbl0[LfoIdx];
				AmTblValue = AmTbl0[LfoIdx];
				break;
			}
		}
		public function CulcPmValue():void {
			if (PmTblValue >= 0) {
				PmValue = ((PmTblValue*PmdPmsmul)>>(7+5))<<Pmsshl;
			} else {
				PmValue = -( (((-PmTblValue)*PmdPmsmul)>>(7+5))<<Pmsshl );
			}
		}
		public function CulcAmValue():void {
			AmValue = (((AmTblValue*Amd)>>(7-4))<<Ams)&(int(0x7FFFFFFF));		//7-4の-4はPRECISION_BITSの拡張分
		}
		public function CulcAllPmValue():void {
			//単チャネルモデルの為
			CulcPmValue();
		}
		public function CulcAllAmValue():void {
			//単チャネルモデルの為
			CulcAmValue();
		}
		public function ResetPhase():void {
			LfoTime = 0;
			LfoSmallCounter = 0;
			LfoIdx = 0;
		}
	}
}