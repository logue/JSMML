package com.flmml {
	import __AS3__.vec.Vector;

	/**
	 * FM sound generator 'OPMS' LFO unit [mode OPM]
	 * @author LinearDrive
	 */
	public class MOscOPMSlfo {
		private static var s_init:int = 0;
		private static const SIZELFOTBL:int = 512;			// 2^9;
		private static const SIZELFOTBL_BITS:int = 9;
		private static const LFOPRECISION:int = 4096;			// 2^12;
		private static const PMSMUL:Vector.<int> = Vector.<int>([ 0,4,7,13,32,64,256,512 ]);
		private static const AMSMUL:Vector.<int> = Vector.<int>([ 0,255,510,1020 ]);
		private static const AMSADJ:int = (MOscOPMSop.SIZEALPHATBL_BITS - 10);	//元々10bitからのSIZEALPHATBL_BITS拡張分を補正
		private static var PmTbl0:Vector.<int>;
		private static var PmTbl2:Vector.<int>;
		private static var AmTbl0:Vector.<int>;
		private static var AmTbl2:Vector.<int>;
		
		private var Pmsmul:int;					// 0,4,7,13,32,64,256,512
		private var Amsmul:int;					// 0,255,510,1020
		private var PmdPmsmul:int;				// Pmd*Pmsmul[]
		private var AmdAmsmul:int;				// Amd*Amsmul[]
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
		private var SyncMode:Boolean;
		
		private var seed:uint;
		
		public function MOscOPMSlfo() {
			boot();
			
			Pmd = 0;
			Amd = 0;
			Pmsmul = 0;
			Amsmul = 0;
			PmdPmsmul = 0;
			AmdAmsmul = 0;
			
			PmValue = 0;
			AmValue = 0;
			
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
			AmTblValue = 256;
			
			SyncMode = false;
			seed = 1;
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
				PmTbl0[i+128] = i-128;
				PmTbl0[i+256] = i;
				PmTbl0[i+384] = i-128;
			}
			// AM Wave Form 0,3
			for (i=0; i<=255; ++i) {
				AmTbl0[i] = 256-i;
				AmTbl0[i+256] = 256-i;
			}
			
			// PM Wave Form 2
			for (i=0; i<=127; ++i) {
				PmTbl2[i] = i;
				PmTbl2[i+128] = 128-i;
				PmTbl2[i+256] = -i;
				PmTbl2[i+384] = i-128;
			}
			// AM Wave Form 2
			for (i=0; i<=255; ++i) {
				AmTbl2[i] = 256-i;
				AmTbl2[i+256] = i;
			}
			
			s_init = 1;
		}
		
		public function Init(n:Number):void {
			InitSamprate(n);
			
			LfoSmallCounter = 0;
			
			SetLFRQ(0);
			SetPMDAMD(0);
			SetPMDAMD(128+0);
			SetWaveForm(0);
			SetPMSAMS(0);
			SetSYNC(false);
			LfoReset();
			LfoStart();
		}
		public function InitSamprate(n:Number):void {
			LfoTimeAdd = int(Number(LFOPRECISION) * (n / MOscOPMS.s_SamprateN));
		}
		
		public function LfoReset():void {
			LfoStartingFlag = 0;
			
			//	LfoTime はリセットされない！！
			LfoIdx = 0;
			
			CulcTblValue();
			CulcPmValue();
			CulcAmValue();
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
			LfoOverFlow = 8 * (1<<shift) * LFOPRECISION;
			
			//	LfoTime はリセットされる
			LfoTime = 0;
		}
		public function SetPMDAMD(n:int):void {
			if ((n & 0x80) != 0) {
				Pmd = n&0x7F;
				PmdPmsmul = Pmd * Pmsmul;
				CulcPmValue();
			} else {
				Amd = n&0x7F;
				AmdAmsmul = Amd * Amsmul;
				CulcAmValue();
			}
		}
		public function SetWaveForm(n:int):void {
			LfoWaveForm = n&3;
			
			CulcTblValue();
			CulcPmValue();
			CulcAmValue();
		}
		public function SetPMSAMS(n:int):void {
			var pms:int = (n>>4)&7;
			Pmsmul = PMSMUL[pms];
			PmdPmsmul = Pmd*Pmsmul;
			CulcPmValue();
			
			Amsmul = AMSMUL[n&3];
			AmdAmsmul = Amd*Amsmul;
			CulcAmValue();
		}
		public function SetSYNC(n:Boolean):void {
			SyncMode = n;
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
					LfoIdx = int( (irnd() >> (32 - SIZELFOTBL_BITS)) & 0x1ff );
					PmTblValue = PmTbl0[LfoIdx];
					AmTblValue = AmTbl0[LfoIdx];
					break;
				}
				LfoSmallCounter &= 15;
				
				CulcPmValue();
				CulcAmValue();
			}
		}
		
		public function GetPmValue():int {
			return PmValue;
		}
		public function GetAmValue():int {
			return AmValue;
		}
		public function GetSyncMode():Boolean {
			return SyncMode;
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
			PmValue = (PmTblValue*PmdPmsmul)/(16256);				//16256=127*128
		}
		public function CulcAmValue():void {
			AmValue = ((AmTblValue*AmdAmsmul)/(32512))<<AMSADJ;		//32512=127*256
		}
		public function ResetPhase():void {
			LfoTime = 0;
			LfoSmallCounter = 0;
			LfoIdx = 0;
		}
		private function irnd():uint {
			seed = (seed * 1566083941) + 1;
			return seed;
		}
	}
}