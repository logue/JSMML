package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

	// Many-Point Envelope
	// 高速化のためにサンプルごとに音量を加算/減算する形に。
	// Numberの仮数部は52bitもあるからそんなに誤差とかは気にならないはず。
	public class MEnvelope {
		private var m_envelopePoint:MEnvelopePoint;
		private var m_envelopeLastPoint:MEnvelopePoint;
		private var m_currentPoint:MEnvelopePoint;
		private var m_releaseTime:Number;
		private var m_currentVal:Number;
		private var m_releaseStep:Number;
		private var m_releasing:Boolean;
		private var m_step:Number;
		private var m_playing:Boolean;
		private var m_counter:int;
		private var m_timeInSamples:int;
        protected static var s_init:int = 0;
        protected static var s_volumeMap:Vector.<Vector.<Number>>;
        protected static var s_volumeLen:int;
		
		// 以前のバージョンとの互換性のためにADSRで初期化
		public function MEnvelope(attack:Number, decay:Number, sustain:Number, release:Number) {
			setAttack(attack);
			addPoint(decay, sustain);
			setRelease(release);
			m_playing = false;
			m_currentVal = 0;
			m_releasing = true;
			m_releaseStep = 0;
		}

        public static function boot():void {
            if (!s_init) {
                var i:int;
                s_volumeLen = 256; // MEnvelopeのエンベロープは256段階であることに注意する。
				s_volumeMap = new Vector.<Vector.<Number>>(3);
				for (i = 0; i < 3; i++) {
					s_volumeMap[i] = new Vector.<Number>(s_volumeLen);
					s_volumeMap[i][0] = 0.0;
				}
                for (i = 1; i < s_volumeLen; i++) {
					s_volumeMap[0][i] = i / 255.0;
                    s_volumeMap[1][i] = Math.pow(10.0, (i-255.0)*(48.0/(255.0*20.0))); // min:-48db
                    s_volumeMap[2][i] = Math.pow(10.0, (i-255.0)*(96.0/(255.0*20.0))); // min:-96db
                }				
                s_init = 1;
            }
        }
        
        public function setAttack(attack:Number):void {
            m_envelopePoint = m_envelopeLastPoint = new MEnvelopePoint();
            m_envelopePoint.time = 0;
            m_envelopePoint.level = 0;
            addPoint(attack, 1.0);
        }
        public function setRelease(release:Number):void {
			m_releaseTime = ((release > 0) ? release : (1.0 / 127.0)) * MSequencer.RATE44100;
			// 現在のボリュームなどを設定
			if(m_playing && !m_releasing){
				m_counter = m_timeInSamples;
				m_currentPoint = m_envelopePoint;
				while(m_currentPoint.next != null && m_counter >= m_currentPoint.next.time){
					m_currentPoint = m_currentPoint.next;
					m_counter -= m_currentPoint.time;
				}
				if(m_currentPoint.next == null){
					m_currentVal = m_currentPoint.level;
				}else{
					m_step = (m_currentPoint.next.level - m_currentPoint.level) / m_currentPoint.next.time;
					m_currentVal = m_currentPoint.level + (m_step * m_counter);
				}
			}
        }
        public function addPoint(time:Number, level:Number):void {
        	var point:MEnvelopePoint = new MEnvelopePoint();
        	point.time = time * MSequencer.RATE44100;
        	point.level = level;
        	m_envelopeLastPoint.next = point;
        	m_envelopeLastPoint = point;
        }
		
		public function triggerEnvelope(zeroStart:int):void {
			m_playing = true;
			m_releasing = false;
			m_currentPoint = m_envelopePoint;
			m_currentVal = m_currentPoint.level = (zeroStart) ? 0 : m_currentVal;
			m_step = (1.0 - m_currentVal) / m_currentPoint.next.time;
			m_timeInSamples = m_counter = 0;
		}
		
		public function releaseEnvelope():void {
			m_releasing = true;
			m_releaseStep = (m_currentVal / m_releaseTime);
		}
		
		public function soundOff():void {
			releaseEnvelope();
			m_playing = false;
		}
		
		public function getNextAmplitudeLinear():Number {
			if(!m_playing) return 0;
			
			if(!m_releasing){
				if(m_currentPoint.next == null){	// sustain phase
					m_currentVal = m_currentPoint.level;
				}else{
					var processed:Boolean = false;
					while(m_counter >= m_currentPoint.next.time){
						m_counter = 0;
						m_currentPoint = m_currentPoint.next;
						if(m_currentPoint.next == null){
							m_currentVal = m_currentPoint.level;
							processed = true;
							break;
						}else{
							m_step = (m_currentPoint.next.level - m_currentPoint.level) / m_currentPoint.next.time;
							m_currentVal = m_currentPoint.level;
							processed = true;
						}
					}
					if(!processed){
						m_currentVal += m_step;
					}
					m_counter++;
				}
			}else{
				m_currentVal -= m_releaseStep; //release phase
			}
			if(m_currentVal <= 0 && m_releasing){
				m_playing = false;
                m_currentVal = 0;
			}
			m_timeInSamples++;
			return m_currentVal;
		}
        public function ampSamplesLinear(samples:Vector.<Number>, start:int, end:int, velocity:Number):void {
            var i:int, amplitude:Number = m_currentVal * velocity;
            for(i = start; i < end; i++){
                if(!m_playing){
                	samples[i] = 0;
                	continue;
                }

				if(!m_releasing){
					if(m_currentPoint.next == null){	// sustain phase
						// m_currentVal = m_currentPoint.level;
					}else{
						var processed:Boolean = false;
						while(m_counter >= m_currentPoint.next.time){
							m_counter = 0;
							m_currentPoint = m_currentPoint.next;
							if(m_currentPoint.next == null){
								m_currentVal = m_currentPoint.level;
								processed = true;
								break;
							}else{
								m_step = (m_currentPoint.next.level - m_currentPoint.level) / m_currentPoint.next.time;
								m_currentVal = m_currentPoint.level;
								processed = true;
							}
						}
						if(!processed){
							m_currentVal += m_step;
						}
						amplitude = m_currentVal * velocity;
						m_counter++;
					}
				}else{
					m_currentVal -= m_releaseStep; //release phase
					amplitude = m_currentVal * velocity;
				}
				if(m_currentVal <= 0 && m_releasing){
					m_playing = false;
	                amplitude = m_currentVal = 0;
				}
				m_timeInSamples++;
                samples[i] *= amplitude;
            }
        }
        public function ampSamplesNonLinear(samples:Vector.<Number>, start:int, end:int, velocity:Number, volMode:int):void {
            var i:int;
            for(i = start; i < end; i++){
                if(!m_playing){
                	samples[i] = 0;
                	continue;
                }

				if(!m_releasing){
					if(m_currentPoint.next == null){	// sustain phase
						m_currentVal = m_currentPoint.level;
					}else{
						var processed:Boolean = false;
						while(m_counter >= m_currentPoint.next.time){
							m_counter = 0;
							m_currentPoint = m_currentPoint.next;
							if(m_currentPoint.next == null){
								m_currentVal = m_currentPoint.level;
								processed = true;
								break;
							}else{
								m_step = (m_currentPoint.next.level - m_currentPoint.level) / m_currentPoint.next.time;
								m_currentVal = m_currentPoint.level;
								processed = true;
							}
						}
						if(!processed){
							m_currentVal += m_step;
						}
						m_counter++;
					}
				}else{
					m_currentVal -= m_releaseStep; //release phase
				}
				if(m_currentVal <= 0 && m_releasing){
					m_playing = false;
	                m_currentVal = 0;
				}
				m_timeInSamples++;
				var cv:int = (m_currentVal * 255) >> 0;
				if (cv > 255) {
					cv = 0;	// 0にするのは過去バージョンを再現するため。
				}
                samples[i] *= s_volumeMap[volMode][cv] * velocity;
            }
        }
        public function isPlaying():Boolean {
            return m_playing;
        }
		public function isReleasing():Boolean {
			return m_releasing;
		}
	}
}
