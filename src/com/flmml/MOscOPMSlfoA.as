package com.flmml {
	import __AS3__.vec.Vector;
	
	/**
	 * FM sound generator 'OPMS' LFO unit [mode OPNA]
	 * @author LinearDrive
	 */
	public class MOscOPMSlfoA {
		private static var s_init:int = 0;
		private static const SIZELFOTBL:int = 512;			// 2^9;
		private static const SIZELFOTBL_BITS:int = 9;
		private static const LFOPRECISION:int = 4096;			// 2^12;
		private static const PMSMUL:Vector.<int> = Vector.<int>([ 0,2,4,6,8,12,25,50 ]);	//0,2,4,6,8,12,25,50
		private static const AMSMUL:Vector.<int> = Vector.<int>([ 0,15,63,126 ]);			//0,15,63,126
		private static const FRQSTEP:Vector.<int> = Vector.<int>([ 109,78,72,68,63,45,9,6 ]);
		private static var PmTbl:Vector.<int>;
		private static var AmTbl:Vector.<int>;
		private static const AMSADJ:int = (MOscOPMSop.SIZEALPHATBL_BITS - 10);	//元々10bitからのSIZEALPHATBL_BITS拡張分を補正
		
		private var Pmsmul:int;				// PMSMUL[]
		private var Amsmul:int;				// AMSMUL[]
		private var LfoStartingFlag:int;	// 0:LFO停止中  1:LFO動作中
		private var LfoIdx:int;				// LFOテーブルへのインデックス値
		private var Lfrq:int;				// LFO周波数設定値 LFRQ
		private var LfoStep:int;
		private var LfoStepRate:int;
		private var LfoStepRateAdj:Number;
		private var PmTblValue:int;
		private var AmTblValue:int;
		private var PmValue:int;
		private var AmValue:int;
		private var SyncMode:Boolean;
		
		public function MOscOPMSlfoA() {
			boot();
			
			Pmsmul = 0;
			Amsmul = 0;
			
			PmValue = 0;
			AmValue = 0;
			
			LfoStartingFlag = 0;
			LfoIdx = 0;
			Lfrq = 0;
			LfoStep = 0;
			LfoStepRate = 0;
			LfoStepRateAdj = 1.0;
			
			PmTblValue = 0;
			AmTblValue = 256;
			
			SyncMode = false;
		}
		
		public static function boot():void {
			if (s_init != 0) return;
			
			//スタティック属性の初期化処理
			var i:int;
			PmTbl = new Vector.<int>(SIZELFOTBL);
			AmTbl = new Vector.<int>(SIZELFOTBL);
			
			// PM Wave Form OPNA
			for (i=0; i<=255; ++i) {
				PmTbl[i] = Math.floor( Math.sin(2.0 * Math.PI * Number(i) / 512.0) * 128.0 );
				PmTbl[i + 256] = PmTbl[i] * (-1.0);
			}
			// AM Wave Form OPNA
			for (i=0; i<=511; ++i) {
				AmTbl[i] = Math.round( (Math.cos(2.0 * Math.PI * Number(i) / 512.0) + 1.0) * 128.0 );
			}
			
			s_init = 1;
		}
		
		public function Init(n:Number):void {
			InitSamprate(n);
			
			SetLFRQ(0);
			SetAMSPMS(0);
			SetSYNC(false);
			LfoReset();
			LfoStart();
		}
		public function InitSamprate(n:Number):void {
			LfoStepRateAdj = (n / MOscOPMS.s_SamprateN);
			SetLFRQ(Lfrq);
		}
		
		public function LfoReset():void {
			LfoStartingFlag = 0;
			
			LfoIdx = 0;
			LfoStep = 0;
			
			CulcTblValue();
			CulcPmValue();
			CulcAmValue();
		}
		public function LfoStart():void {
			LfoStartingFlag = 1;
		}
		public function SetLFRQ(n:int):void {
			Lfrq = n&7;
			LfoStepRate = int( Number(LFOPRECISION)
								* LfoStepRateAdj
								* (Number(SIZELFOTBL) / Number(FRQSTEP[Lfrq] * 128))
							);
			LfoStep = 0;
		}
		public function SetAMSPMS(n:int):void {
			Pmsmul = PMSMUL[n&7];
			Amsmul = AMSMUL[(n>>4)&3];
			CulcPmValue();
			CulcAmValue();
		}
		public function SetSYNC(n:Boolean):void {
			SyncMode = n;
		}
		
		public function Update():void {
			var refresh:Boolean = false;
			if (LfoStartingFlag == 0) {
				return;
			}
			LfoStep += LfoStepRate;
			while (LfoStep >= LFOPRECISION) {
				LfoStep -= LFOPRECISION;
				LfoIdx++;
				refresh = true;
			}
			if (refresh == true) {
				LfoIdx &= (SIZELFOTBL-1);
				PmTblValue = PmTbl[LfoIdx];
				AmTblValue = AmTbl[LfoIdx];
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
			PmTblValue = PmTbl[LfoIdx];
			AmTblValue = AmTbl[LfoIdx];
		}
		public function CulcPmValue():void {
			PmValue = (PmTblValue*Pmsmul)/(128);
		}
		public function CulcAmValue():void {
			AmValue = ((AmTblValue*Amsmul)/(256))<<AMSADJ;
		}
		public function ResetPhase():void {
			LfoStep = 0;
			LfoIdx = 0;
		}
	}
}