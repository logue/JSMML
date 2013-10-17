package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscillatorL {
		public static const SINE:int       = 0;
		public static const BEND:int       = 1;
		public static const TRIANGLE:int   = 2;
		public static const PULSE:int      = 3;
		public static const NOISE_W:int    = 4;
		public static const TABLE:int      = 5;
		public static const NONL_BEND:int  = 6;
		public static const MAX:int        = 7;

		protected static var s_init:int = 0;
		protected var m_osc:Vector.<MOscModL>;
		protected var m_form:int;

		public function MOscillatorL() {
			boot();
			m_osc = new Vector.<MOscModL>(MAX);
			m_osc.fixed = true;
			m_osc[SINE]       = new MOscLSine();
			m_osc[BEND]       = new MOscLBend();
			m_osc[TRIANGLE]   = new MOscLTri();
			m_osc[PULSE]      = new MOscLPulse();
			m_osc[NOISE_W]    = new MOscLNoiseW();
			m_osc[TABLE]      = new MOscLTable();
			m_osc[NONL_BEND]  = new MOscLBendNL();
			setForm(SINE);
		}
		public static function boot():void {
			if (s_init) return;
			MOscLSine.boot();
			MOscLBend.boot();
			MOscLTri.boot();
			MOscLPulse.boot();
			MOscLNoiseW.boot();
			MOscLTable.boot();
			MOscLBendNL.boot();
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
