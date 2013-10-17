package com.flmml
{
	public class MEnvelopePoint {
		public var idnum:int = 0;
		public var index:int = 0;
		public var r_mode:Boolean = true;
		public var rate:Number = 0.0;
		public var time:Number = 0.0;				//エンベロープシーケンス中ポイントをまたぐ時、毎回rateからtimeとm_stepを算出
		public var level:Number = 0.0;
		public var next:MEnvelopePoint = null;

		public function MEnvelopePoint(id:int) {
			idnum = id;
		}
	}
}
