package com.txt_nifty.sketch.flmml 
{
    import __AS3__.vec.Vector;
	
	/**
	 * ...
	 * @author ALOE
	 */
	public class MPolyChannel implements IChannel
	{
		protected var m_form:int;
		protected var m_subform:int;
		protected var m_volMode:int;
		protected var m_voiceId:Number;
		protected var m_lastVoice:MChannel;
		protected var m_voiceLimit:int;
		protected var m_voices:Vector.<MChannel>;
		protected var m_voiceLen:int;
		
		public function MPolyChannel(voiceLimit:int) {
			m_voices = new Vector.<MChannel>(voiceLimit);
			for (var i:int = 0; i < m_voices.length; i++) {
				m_voices[i] = new MChannel();
			}
			m_form      	= MOscillator.FC_PULSE;
			m_subform   	= 0;
			m_voiceId   	= 0;
			m_volMode   	= 0;
		    m_voiceLimit	= voiceLimit;
			m_lastVoice 	= null;
			m_voiceLen      = m_voices.length;
		}
	
        public function setExpression(ex:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setExpression(ex);
        }

        public function setVelocity(velocity:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setVelocity(velocity);
        }

        public function setNoteNo(noteNo:int, tie:Boolean = true) : void {
            if (m_lastVoice != null && m_lastVoice.isPlaying()) {
                m_lastVoice.setNoteNo(noteNo, tie);
            }
        }

        public function setDetune(detune:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setDetune(detune);
        }

        public function getVoiceCount() : int {
            var i:int;
            var c:int = 0;
            for (i = 0; i < m_voiceLen; i++) {
				c += m_voices[i].getVoiceCount();
			}
            return c;
        }

        public function noteOn(noteNo:int, velocity:int) : void {
            var i:int;
            var vo:MChannel = null;
			
			// ボイススロットに空きがあるようだ
			if (getVoiceCount() <= m_voiceLimit) {
				for (i = 0; i < m_voiceLen; i++) {
					if (m_voices[i].isPlaying() == false) {
						vo = m_voices[i];
						break;
					}
				}				
			}
            // やっぱ埋まってたので一番古いボイスを探す
            if (vo == null) {
                var minId:Number = Number.MAX_VALUE;
                for (i = 0; i < m_voiceLen; i++) {
                    if (minId > m_voices[i].getId()) {
                        minId = m_voices[i].getId();
                        vo = m_voices[i];
                    }
                }
            }
			// 発音する
            vo.setForm(m_form, m_subform);
            vo.setVolMode(m_volMode);
            vo.noteOnWidthId(noteNo, velocity, m_voiceId++);
            m_lastVoice = vo;
        }

        public function noteOff(noteNo:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) {
                if (m_voices[i].getNoteNo() == noteNo) {
                    m_voices[i].noteOff(noteNo);
                }
            }
        }

        public function setSoundOff() : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setSoundOff();
        }

        public function close() : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].close();
        }

        public function setNoiseFreq(frequency:Number) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setNoiseFreq(frequency);
        }

        public function setForm(form:int, subform:int) : void {
            // ノートオン時に適用する
            m_form    = form;
            m_subform = subform;
        }

        public function setEnvelope1Atk(attack:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope1Atk(attack);
        }

        public function setEnvelope1Point(time:int, level:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope1Point(time, level);
        }

        public function setEnvelope1Rel(release:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope1Rel(release);
        }

        public function setEnvelope2Atk(attack:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope2Atk(attack);
        }

        public function setEnvelope2Point(time:int, level:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope2Point(time, level);
        }

        public function setEnvelope2Rel(release:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope2Rel(release);
        }

        public function setPWM(pwm:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPWM(pwm);
        }

        public function setPan(pan:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPan(pan);
        }

        public function setFormant(vowel:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setFormant(vowel);
        }

        public function setLFOFMSF(form:int, subform:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFOFMSF(form, subform);
        }

        public function setLFODPWD(depth:int, freq:Number) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFODPWD(depth, freq);
        }

        public function setLFODLTM(delay:int, time:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFODLTM(delay, time);
        }

        public function setLFOTarget(target:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFOTarget(target);
        }

        public function setLpfSwtAmt(swt:int, amt:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLpfSwtAmt(swt, amt);
        }

        public function setLpfFrqRes(frq:int, res:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLpfFrqRes(frq, res);
        }

        public function setVolMode(m:int) : void {
            // ノートオン時に適用する
            m_volMode = m;
        }

        public function setInput(ii:int, p:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setInput(ii, p);
        }

        public function setOutput(oo:int, p:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setOutput(oo, p);
        }

        public function setRing(s:int, p:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setRing(s, p);
        }

        public function setSync(m:int, p:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setSync(m, p);
        }

        public function setPortamento(depth:int, len:Number) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPortamento(depth, len);
        }

        public function setMidiPort(mode:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setMidiPort(mode);
        }

        public function setMidiPortRate(rate:Number) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setMidiPortRate(rate);
        }

        public function setPortBase(portBase:int) : void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPortBase(portBase);
        }
		
		public function setVoiceLimit(voiceLimit:int) : void {
			m_voiceLimit = Math.max(1, Math.min(voiceLimit, m_voiceLen));
		}
		
		public function setHwLfo(data:int):void {
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setHwLfo(data);
		}

        public function reset() : void {
			m_form      = 0;
			m_subform   = 0;
			m_voiceId   = 0;
			m_volMode   = 0;			
            for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].reset();
        }

        public function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int) : void {
            var slave:Boolean = false;
            for (var i:int = 0; i < m_voiceLen; i++) {
                if (m_voices[i].isPlaying()) {
                    m_voices[i].setSlaveVoice(slave);
                    m_voices[i].getSamples(samples, max, start, delta);
                    slave = true;
                }
            }
            if (slave == false) {
                m_voices[0].clearOutPipe(max, start, delta);
            }
        }	
		
        /*
         * End Class Definition
         */		
	}

}