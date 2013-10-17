package com.flmml 
{
	public class MMLArgEnv {
		public var idnum:int       = 0;
		public var pt_mode:int     = 0;
		public var rt_mode:Boolean = true;
		public var rate:Number     = 0.0;
		public var level:Number    = 0.0;

		public function MMLArgEnv(id:int) {
			idnum = id;
		}
	}
}