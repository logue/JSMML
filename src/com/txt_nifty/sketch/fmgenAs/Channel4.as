// ---------------------------------------------------------------------------
//	FM Sound Generator - Core Unit
//	Copyright (C) cisc 1998, 2003.
//	Copyright (C) 2011 ALOE. All rights reserved.
// ---------------------------------------------------------------------------
package com.txt_nifty.sketch.fmgenAs 
{
    import __AS3__.vec.Vector;
	/**
	 * ...
	 * @author ALOE
	 */
	internal class Channel4
	{
		// 高速化のために全部internalで公開('A`)
		internal var fb:int;
		internal var buf:Vector.<int> = new Vector.<int>(4,true);
		internal var pms:Vector.<int>;
        internal var ix :Vector.<int> = new Vector.<int>(3,true);
        internal var ox :Vector.<int> = new Vector.<int>(3,true);
		internal var algo_:int;
		internal var chip_:Chip;		
		
		internal var op:Vector.<Operator> = Vector.<Operator>([
			new Operator(),
			new Operator(),
			new Operator(),
			new Operator(),
		]);
		
        private static const fbtable:Vector.<int> = Vector.<int>([
            31, 7, 6, 5, 4, 3, 2, 1 
        ]);		
		
        private static const kftable:Vector.<int> = Vector.<int>([
            65536, 65595, 65654, 65713, 65773, 65832, 65891, 65951, 
            66010, 66070, 66130, 66189, 66249, 66309, 66369, 66429, 
            66489, 66549, 66609, 66669, 66729, 66789, 66850, 66910, 
            66971, 67031, 67092, 67152, 67213, 67273, 67334, 67395, 
            67456, 67517, 67578, 67639, 67700, 67761, 67822, 67883, 
            67945, 68006, 68067, 68129, 68190, 68252, 68314, 68375, 
            68437, 68499, 68561, 68623, 68685, 68747, 68809, 68871, 
            68933, 68995, 69057, 69120, 69182, 69245, 69307, 69370, 
        ]);

        private static const kctable:Vector.<int> = Vector.<int>([ 
	        5197, 5506, 5833, 6180, 6180, 6547, 6937, 7349, 
	        7349, 7786, 8249, 8740, 8740, 9259, 9810, 10394, 
        ]);

	    private static const iotable:Array = [
		    [ 0, 1, 1, 2, 2, 3 ],	[ 1, 0, 0, 1, 1, 2 ],
		    [ 1, 1, 1, 0, 0, 2 ],	[ 0, 1, 2, 1, 1, 2 ],
		    [ 0, 1, 2, 2, 2, 1 ],	[ 0, 1, 0, 1, 0, 1 ],
		    [ 0, 1, 2, 1, 2, 1 ],	[ 1, 0, 1, 0, 1, 0 ],
	    ];
		
        public function Channel4() {
            SetAlgorithm(0);
            pms = FM.pmtable[0][0];
        }

        //	オペレータの種類 (LFO) を設定
        public function SetType(type:int/*OpType*/):void {
            for (var i:int = 0; i < 4; i++) op[i].type_ = type;
        }

        //	セルフ・フィードバックレートの設定 (0-7)
        public function SetFB(feedback:int):void {
            fb = fbtable[feedback];
        }

        //	OPNA 系 LFO の設定
        public function SetMS(ms:int):void {
            op[0].SetMS(ms);
            op[1].SetMS(ms);
            op[2].SetMS(ms);
            op[3].SetMS(ms);
        }

        //	チャンネル・マスク
        public function Mute(m:Boolean):void {
	        for (var i:int=0; i<4; i++) op[i].Mute(m);
        }

        //	内部パラメータを再計算
        public function Refresh():void {
	        for (var i:int=0; i<4; i++) op[i].Refresh();
        }

        public function SetChip(chip:Chip):void {
	        chip_ = chip;
	        for (var i:int=0; i<4; i++) op[i].SetChip(chip);
        }

        // リセット
        public function Reset():void {
            op[0].Reset();
            op[1].Reset();
            op[2].Reset();
            op[3].Reset();
        }

        //	Calc の用意
        public function Prepare():int {
            op[0].Prepare();
            op[1].Prepare();
            op[2].Prepare();
            op[3].Prepare();

            pms = FM.pmtable[op[0].type_][op[0].ms_ & 7];
            var key:int = (op[0].IsOn() || op[1].IsOn() || op[2].IsOn() || op[3].IsOn()) ? 1 : 0;
            var lfo:int = (op[0].ms_ & (op[0].amon_ || op[1].amon_ || op[2].amon_ || op[3].amon_ ? 0x37 : 7)) !=0 ? 2 : 0;
            return key | lfo;
        }

        //	F-Number/BLOCK を設定
        public function SetFNum(f:int):void {
            for (var i:int = 0; i < 4; i++) op[i].SetFNum(f);
        }

        //	KC/KF を設定
        public function SetKCKF(kc:int, kf:int):void {
	        var oct:int = 19 - ((kc >> 4) & 7);
	        var kcv:int = kctable[kc & 0x0f];
	        kcv = (kcv + 2) / 4 * 4;
	        var dp:int = kcv * kftable[kf & 0x3f];
	        dp >>= 16 + 3;
	        dp <<= 16 + 3;
	        dp >>= oct;	
	        var bn:int = (kc >> 2) & 31;
	        op[0].SetDPBN(dp, bn);
	        op[1].SetDPBN(dp, bn);
	        op[2].SetDPBN(dp, bn);
	        op[3].SetDPBN(dp, bn);
        }

        //	キー制御
        public function KeyControl(key:int):void {
	        if ((key & 0x1) != 0) op[0].KeyOn(); else op[0].KeyOff();
	        if ((key & 0x2) != 0) op[1].KeyOn(); else op[1].KeyOff();
	        if ((key & 0x4) != 0) op[2].KeyOn(); else op[2].KeyOff();
	        if ((key & 0x8) != 0) op[3].KeyOn(); else op[3].KeyOff();
        }

		//	アルゴリズムを設定
		public function SetAlgorithm(algo:int):void {
			ix[0] = iotable[algo][0];
			ox[0] = iotable[algo][1];
			ix[1] = iotable[algo][2];
			ox[1] = iotable[algo][3];
			ix[2] = iotable[algo][4];
			ox[2] = iotable[algo][5];
			op[0].ResetFB();
			algo_ = algo;
		}
		
		//	アルゴリズムを取得
		public function GetAlgorithm():int {
			return algo_;
		}

       	//  合成
	    public function Calc():int {
		    var r:int = 0;
		    switch (algo_) {
		    case 0:
			    op[2].Calc(op[1].Out());
			    op[1].Calc(op[0].Out());
			    r = op[3].Calc(op[2].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 1:
			    op[2].Calc(op[0].Out() + op[1].Out());
			    op[1].Calc(0);
			    r = op[3].Calc(op[2].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 2:
			    op[2].Calc(op[1].Out());
			    op[1].Calc(0);
			    r = op[3].Calc(op[0].Out() + op[2].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 3:
			    op[2].Calc(0);
			    op[1].Calc(op[0].Out());
			    r = op[3].Calc(op[1].Out() + op[2].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 4:
			    op[2].Calc(0);
			    r = op[1].Calc(op[0].Out());
			    r += op[3].Calc(op[2].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 5:
			    r =  op[2].Calc(op[0].Out());
			    r += op[1].Calc(op[0].Out());
			    r += op[3].Calc(op[0].Out());
			    op[0].CalcFB(fb);
			    break;
		    case 6:
			    r  = op[2].Calc(0);
			    r += op[1].Calc(op[0].Out());
			    r += op[3].Calc(0);
			    op[0].CalcFB(fb);
			    break;
		    case 7:
			    r  = op[2].Calc(0);
			    r += op[1].Calc(0);
			    r += op[3].Calc(0);
			    r += op[0].CalcFB(fb);
			    break;
		    }
		    return r;
	    }

        //  合成
        public function CalcL():int {
	        chip_.SetPMV(pms[chip_.GetPML()]);

	        var r:int = 0;
	        switch (algo_) {
	        case 0:
		        op[2].CalcL(op[1].Out());
		        op[1].CalcL(op[0].Out());
		        r = op[3].CalcL(op[2].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 1:
		        op[2].CalcL(op[0].Out() + op[1].Out());
		        op[1].CalcL(0);
		        r = op[3].CalcL(op[2].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 2:
		        op[2].CalcL(op[1].Out());
		        op[1].CalcL(0);
		        r = op[3].CalcL(op[0].Out() + op[2].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 3:
		        op[2].CalcL(0);
		        op[1].CalcL(op[0].Out());
		        r = op[3].CalcL(op[1].Out() + op[2].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 4:
		        op[2].CalcL(0);
		        r = op[1].CalcL(op[0].Out());
		        r += op[3].CalcL(op[2].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 5:
		        r =  op[2].CalcL(op[0].Out());
		        r += op[1].CalcL(op[0].Out());
		        r += op[3].CalcL(op[0].Out());
		        op[0].CalcFBL(fb);
		        break;
	        case 6:
		        r  = op[2].CalcL(0);
		        r += op[1].CalcL(op[0].Out());
		        r += op[3].CalcL(0);
		        op[0].CalcFBL(fb);
		        break;
	        case 7:
		        r  = op[2].CalcL(0);
		        r += op[1].CalcL(0);
		        r += op[3].CalcL(0);
		        r += op[0].CalcFBL(fb);
		        break;
	        }
	        return r;
        }

        //  合成
        public function CalcN(noise:int):int {
	        buf[1] = buf[2] = buf[3] = 0;
	        buf[0] = op[0].Out(); op[0].CalcFB(fb);
	        buf[ox[0]] += op[1].Calc(buf[ix[0]]);
	        buf[ox[1]] += op[2].Calc(buf[ix[1]]);
	        var o:int = op[3].Out();
	        op[3].CalcN(noise);
	        return buf[ox[2]] + o;
        }

        //  合成
        public function CalcLN(noise:int):int {
	        chip_.SetPMV(pms[chip_.GetPML()]);
	        buf[1] = buf[2] = buf[3] = 0;
	        buf[0] = op[0].Out(); op[0].CalcFBL(fb); 
	        buf[ox[0]] += op[1].CalcL(buf[ix[0]]);
	        buf[ox[1]] += op[2].CalcL(buf[ix[1]]);
	        var o:int = op[3].Out();
	        op[3].CalcN(noise);
	        return buf[ox[2]] + o;
        }

        /*
         * End Class Definition
         */
		
	}

}