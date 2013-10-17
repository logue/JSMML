package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscillatorLA {
		public static const SINE:int       = 0;
		public static const SAW:int        = 1;
		public static const TRIANGLE:int   = 2;
		public static const PULSE:int      = 3;
		public static const NOISE_W:int    = 4;
		public static const TABLE:int      = 5;
		public static const MAX:int        = 6;

		protected static var s_init:int = 0;
		protected var m_osc:Vector.<MOscModL>;
		protected var m_form:int;

		public function MOscillatorLA() {
			boot();
			m_osc = new Vector.<MOscModL>(MAX);
			m_osc.fixed = true;
			m_osc[SINE]       = new MOscLSineA();
			m_osc[SAW]        = new MOscLSawA();
			m_osc[TRIANGLE]   = new MOscLTriA();
			m_osc[PULSE]      = new MOscLPulseA();
			m_osc[NOISE_W]    = new MOscLNoiseWA();
			m_osc[TABLE]      = new MOscLTable();
			setForm(SINE);
		}
		public static function boot():void {
			if (s_init) return;
			MOscLSineA.boot();
			MOscLSawA.boot();
			MOscLTriA.boot();
			MOscLPulseA.boot();
			MOscLNoiseWA.boot();
			MOscLTable.boot();
			s_init = 1;
		}
		public function setForm(form:int):MOscModL {
			var i:int = form;
			if (i < 0) i = 0;
			if (i >= MAX) i = MAX - 1;
			m_form = i;
			return getMod(m_form);
		}
		public function getForm():int {
			return m_form;
		}
		public function getCurrent():MOscModL {
			return getMod(m_form);
		}
		public function getMod(form:int):MOscModL {
			var i:int = form;
			if (i < 0) i = 0;
			if (i >= MAX) i = MAX - 1;
			return m_osc[i];
		}
	}
}
