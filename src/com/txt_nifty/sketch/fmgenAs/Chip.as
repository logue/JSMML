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
	internal class Chip
	{
		private var ratio_:int = 0;
		public  var aml_:int = 0; // ←
        public  var pml_:int = 0; // ←最 適化のためにpublicにしてしまう
        public  var pmv_:int = 0; // ←
		private var multable_:Vector.<Vector.<int>> = JaggArray.I2(4, 16);
	
		private static const dt2lv:Vector.<Number> = Vector.<Number>([
			1.0, 1.414, 1.581, 1.732
		]);
		
		public function Chip() {
			MakeTable();
		}
		
		public function SetRatio(ratio:int):void {
            if (ratio_ != ratio) {
                ratio_ = ratio;
                MakeTable();
            }
        }
        public function SetAML(l:int):void {
            aml_ = l & (FM.FM_LFOENTS - 1);
        }
        public function SetPML(l:int):void {
            pml_ = l & (FM.FM_LFOENTS - 1);
        }
        public function SetPMV(pmv:int):void {
            pmv_ = pmv;
        }
		
        public function GetMulValue(dt2:int, mul:int):int {
			return multable_[dt2][mul]; 
		}
        public function GetAML():int {
			return aml_; 
		}
        public function GetPML():int { 
			return pml_; 
		}
        public function GetPMV():int { 
			return pmv_; 
		}
        public function GetRatio():int {
			return ratio_; 
		}		
		
        private function MakeTable():void {
            var h:int, l:int;

            // PG Part
            for (h = 0; h < 4; h++) {
                var rr:Number = dt2lv[h] * Number(ratio_) / (1 << (2 + FM.FM_RATIOBITS - FM.FM_PGBITS));
                for (l = 0; l < 16; l++) {
                    var mul:int = (l != 0) ? l * 2 : 1;
                    multable_[h][l] = (int)(mul * rr);
                }
            }
        }		
		
        /*
         * End Class Definition
         */		
	}

}