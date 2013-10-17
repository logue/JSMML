package com.flmml {
	import flash.events.Event;

	public class MMLEvent extends Event {
		public static const SIGNAL:String = 'signal';
		public static const COMPLETE:String = "complete";
		public static const COMPILE_COMPLETE:String  = 'compileComplete';
		public static const BUFFERING:String = 'buffering';
		public var globalTick:uint;
		public var id:int;
		public var progress:int;

		public function MMLEvent(aType:String, aBubbles:Boolean = false, aCancelable:Boolean = false, aGlobalTick:int = 0, aId:int = 0, aProgress:int = 0) {
			super(aType, aBubbles, aCancelable);
			globalTick = aGlobalTick;
			id = aId;
			progress = aProgress;
		}
		public override function clone():Event {
			return new MMLEvent(type, bubbles, cancelable, globalTick, id);
		}
	}
}
