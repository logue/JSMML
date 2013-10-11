package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MOscPulse extends MOscMod {
        protected var m_pwm:int;
		protected var m_mix:int;
		protected var m_modNoise:MOscNoise;

        public function MOscPulse() {
            boot();
            super();
            setPWM(0.5);
			setMIX(0);
        }
        public static function boot():void {
        }
        public override function getNextSample():Number {
            var val:Number = (m_phase < m_pwm) ? 1.0 : (m_mix ? m_modNoise.getNextSample() : -1.0);
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getNextSampleOfs(ofs:int):Number {
            var val:Number = (((m_phase + ofs) & PHASE_MSK) < m_pwm) ? 1.0 : (m_mix ? m_modNoise.getNextSampleOfs(ofs) : -1.0);
            m_phase = (m_phase + m_freqShift) & PHASE_MSK;
            return val;
        }
        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            var i:int;
			if (m_mix) { // MIXモード
				for (i = start; i < end; i++) {
					samples[i] = (m_phase < m_pwm) ? 1.0 : m_modNoise.getNextSample();
					m_phase = (m_phase + m_freqShift) & PHASE_MSK;
				}
			}
			else { // 通常の矩形波
				for (i = start; i < end; i++) {
					samples[i] = (m_phase < m_pwm) ? 1.0 : -1.0;
					m_phase = (m_phase + m_freqShift) & PHASE_MSK;
				}
			}
        }
        public override function getSamplesWithSyncIn(samples:Vector.<Number>, syncin:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
            if (m_mix) { // MIXモード
			    for(i = start; i < end; i++) {
				    if(syncin[i]) resetPhase();
                    samples[i] = (m_phase < m_pwm) ? 1.0 : m_modNoise.getNextSample();
                    m_phase = (m_phase + m_freqShift) & PHASE_MSK;
                }
            }
            else { // 通常の矩形波
			    for(i = start; i < end; i++) {
				    if(syncin[i]) resetPhase();
                    samples[i] = (m_phase < m_pwm) ? 1.0 : -1.0;
                    m_phase = (m_phase + m_freqShift) & PHASE_MSK;
                }
            }
        }
        public override function getSamplesWithSyncOut(samples:Vector.<Number>, syncout:Vector.<Boolean>, start:int, end:int):void {
			var i:int;
            if (m_mix) { // MIXモード
			    for (i = start; i < end; i++) {
                    samples[i] = (m_phase < m_pwm) ? 1.0 : m_modNoise.getNextSample();
                    m_phase += m_freqShift;
                    syncout[i] = (m_phase > PHASE_MSK);
                    m_phase &= PHASE_MSK;
			    }
            }
            else { // 通常の矩形波
			    for (i = start; i < end; i++) {
                    samples[i] = (m_phase < m_pwm) ? 1.0 : -1.0;
                    m_phase += m_freqShift;
                    syncout[i] = (m_phase > PHASE_MSK);
                    m_phase &= PHASE_MSK;
			    }
            }
        }
        public function setPWM(pwm:Number):void {
            m_pwm = pwm * PHASE_LEN;
        }
		public function setMIX(mix:int):void {		
			m_mix = mix;
		}
		public function setNoise(noise:MOscNoise):void {
			m_modNoise = noise;
		}
    }
}
