// ---------------------------------------------------------------------------
//	FM sound generator common timer module
//	Copyright (C) cisc 1998, 2000.
//	Copyright (C) 2011 ALOE. All rights reserved.
// ---------------------------------------------------------------------------
package com.txt_nifty.sketch.fmgenAs 
{
    import __AS3__.vec.Vector;
	/**
	 * ...
	 * @author ALOE
	 */
	public class Timer
	{
		private var regta:Vector.<int> = new Vector.<int>(2);
		private var	timera:int, timera_count:int;
		private var	timerb:int, timerb_count:int;
		private var	timer_step:int;		
		
		protected var status:int;
		protected var regtc:int;
		
		public function Reset():void {
			timera_count = 0;
			timerb_count = 0;
		}

        public function Count(us:int):Boolean {
            var f:Boolean = false;

            if (timera_count != 0) {
                timera_count -= us << 16;
                if (timera_count <= 0) {
                    f = true;
                    TimerA();

                    while (timera_count <= 0)
                        timera_count += timera;

                    if ((regtc & 4) != 0)
                        SetStatus(1);
                }
            }
            if (timerb_count != 0) {
                timerb_count -= us << 12;
                if (timerb_count <= 0) {
                    f = true;
                    while (timerb_count <= 0)
                        timerb_count += timerb;

                    if ((regtc & 8) != 0)
                        SetStatus(2);
                }
            }

            return f;
        }		
	
        public function GetNextEvent():int {
	        var ta:int = ((timera_count + 0xffff) >> 16) - 1;
	        var tb:int = ((timerb_count +  0xfff) >> 12) - 1;
        	return (ta < tb ? ta : tb) + 1;
        }		
		
		protected /*abstract*/ function SetStatus(bit:int):void   { }
		protected /*abstract*/ function ResetStatus(bit:int):void { }	
		
        protected function SetTimerBase(clock:int):void {
            timer_step = (int)(1000000.0 * 65536 / clock);
        }

        protected function SetTimerA(addr:int, data:int):void {
	        var tmp:int;
	        regta[addr & 1] = (int)(data);
	        tmp = (regta[0] << 2) + (regta[1] & 3);
	        timera = (1024-tmp) * timer_step;
        }

        protected function SetTimerB(data:int):void {
            timerb = (256 - data) * timer_step;
        }

        protected function SetTimerControl(data:int):void {
	        var tmp:int = regtc ^ data;
	        regtc = (int)(data);
        	
	        if ((data & 0x10) != 0) 
		        ResetStatus(1);
	        if ((data & 0x20) != 0)
		        ResetStatus(2);

	        if ((tmp & 0x01) != 0)
		        timera_count = ((data & 1) != 0) ? timera : 0;
	        if ((tmp & 0x02) != 0)
		        timerb_count = ((data & 2) != 0) ? timerb : 0;
        }		
		
        protected /*abstract*/ function TimerA():void { }		
		
        /*
         * End Class Definition
         */		
	}

}