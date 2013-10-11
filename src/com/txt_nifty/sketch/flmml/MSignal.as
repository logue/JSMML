package com.txt_nifty.sketch.flmml {
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class MSignal {
		protected var m_id:int;
		protected var m_msArr:Array;  // milli seconds
		protected var m_gtArr:Array;  // global ticks
		protected var m_evArr:Array;  // event
		protected var m_ptr:int;
		protected var m_timer:Timer;
		protected var m_func:Function;
        protected var m_preTime:Number;

		public function MSignal(id:int, maxEachBuffer:int = 60) {
			m_id = id;
			m_msArr = new Array(maxEachBuffer);
			m_msArr[0] = -1;
			m_gtArr = new Array(maxEachBuffer);
			m_evArr = new Array(maxEachBuffer);
			m_ptr = 0;
			m_timer = new Timer(1,1);
			m_func = null;
		}

		public function setFunction(func:Function):void {
			m_func = func;
		}

		public function add(ms:int, gt:int, ev:int):void {
			m_msArr[m_ptr] = ms;
			m_gtArr[m_ptr] = gt;
			m_evArr[m_ptr] = ev;
			m_ptr++;
			//trace(m_id+"add"+ms+","+gt+","+ev);
		}

		public function terminate():void {
			add(-1, 0, 0);
		}

		public function reset():void {
            // flush
            m_timer.reset();
            if (m_func != null) {
                while(m_msArr[m_ptr] >= 0) {
                    //trace("id:"+m_id+" ns:"+m_msArr[m_ptr]+" ptr:"+m_ptr+" gt:"+m_gtArr[m_ptr]+"(flush)");
                    m_func(m_gtArr[m_ptr], m_evArr[m_ptr]);
                    m_ptr++;
                }
            }
            // reset
			m_ptr = 0;
			m_msArr[0] = -1;
		}

		public function start():void {
            m_preTime = new Date().getTime();
			m_ptr = 0;
			next();
		}

		protected function onSignal(timerEvent:TimerEvent):void {
            //trace("id:"+m_id+" ns:"+m_msArr[m_ptr]+" ptr:"+m_ptr+" gt:"+m_gtArr[m_ptr]);
			if (m_func != null) m_func(m_gtArr[m_ptr], m_evArr[m_ptr]);
            var time:Number = new Date().getTime();
            var over:Number = (time - m_preTime) - m_msArr[m_ptr];
            m_preTime = time;
			m_ptr++;
            if (m_ptr < m_gtArr.length) {
                // adjust
                var i:int = m_ptr;
                while (over > 0 && m_msArr[i] >= 0) {
                    if (m_msArr[i] >= over) {
                        m_msArr[i] -= over;
                        break;
                    }
                    else {
                        over -= m_msArr[i];
                        m_msArr[i] = 0;
                    }
                    i++;
                }
                next();
            }
		}

		protected function next():void {
			var ns:int = m_msArr[m_ptr];
			if (ns > 0) {
				m_timer.reset();
				m_timer.delay = ns;
				m_timer.repeatCount = 1;
				m_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onSignal);
				m_timer.start();
			}
			else if (ns == 0) {
				onSignal(null);
			}
		}
	}
}
