package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    public class MChannel implements IChannel {
    	private static const LFO_TARGET_PITCH:int     = 0;
    	private static const LFO_TARGET_AMPLITUDE:int = 1;
    	private static const LFO_TARGET_CUTOFF:int    = 2;
    	private static const LFO_TARGET_PWM:int       = 3;
    	private static const LFO_TARGET_FM:int        = 4;
    	private static const LFO_TARGET_PANPOT:int    = 5;
    	
        private var m_noteNo:int;
        private var m_detune:int;
        private var m_freqNo:int;
        private var m_envelope1:MEnvelope;     // for VCO
        private var m_envelope2:MEnvelope;     // for VCF
        private var m_oscSet1:MOscillator;     // for original wave
        private var m_oscMod1:MOscMod;
        private var m_oscSet2:MOscillator;     // for Pitch LFO
        private var m_oscMod2:MOscMod;
        private var m_osc2Connect:int;
        private var m_osc2Sign:Number;
        private var m_filter:MFilter;
        private var m_filterConnect:int;
        private var m_formant:MFormant;
        private var m_expression:Number;       // expression (max:1.0)
        private var m_velocity:Number;         // velocity (max:1.0)
        private var m_ampLevel:Number;         // amplifier level (max:1.0)
        private var m_pan:Number;				// left 0.0 - 1.0 right
        private var m_onCounter:int;
        private var m_lfoDelay:int;
        private var m_lfoDepth:Number;
        private var m_lfoEnd:int;
        private var m_lfoTarget:int;
        private var m_lpfAmt:Number;
        private var m_lpfFrq:Number;
        private var m_lpfRes:Number;
        private var m_pulseWidth:Number;
        private var m_volMode:int;
        private var m_inSens:Number;
        private var m_inPipe:int;
        private var m_outMode:int;
        private var m_outPipe:int;
        private var m_ringSens:Number;
        private var m_ringPipe:int;
        private var m_syncMode:int;
        private var m_syncPipe:int;

		private var m_portDepth:Number;
		private var m_portDepthAdd:Number;
		private var m_portamento:int;
		private var m_portRate:Number;
		private var m_lastFreqNo:int;
		
		private var m_slaveVoice:Boolean;	// 従属ボイスか？
        private var m_voiceid:Number;		// ボイスID
		

        public    static var PITCH_RESOLUTION:int = 100;
        protected static var s_init:int = 0;
        protected static var s_frequencyMap:Vector.<Number> = new Vector.<Number>(128 * PITCH_RESOLUTION);
        protected static var s_frequencyLen:int;
        protected static var s_volumeMap:Vector.<Vector.<Number>>;
        protected static var s_volumeLen:int;
        protected static var s_samples:Vector.<Number>;            // mono
        protected static var s_pipeArr:Vector.<Vector.<Number>>;
        protected static var s_syncSources:Vector.<Vector.<Boolean>>;
        protected static var s_lfoDelta:int = 245;

        public function MChannel() {
            m_noteNo = 0;
            m_detune = 0;
            m_freqNo = 0;
            m_envelope1 = new MEnvelope(0.0, 60.0/127.0, 30.0/127.0, 1.0/127.0);
            m_envelope2 = new MEnvelope(0.0, 30.0/127.0, 0.0, 1.0);
            m_oscSet1 = new MOscillator();
            m_oscMod1 = m_oscSet1.getCurrent();
            m_oscSet2 = new MOscillator();
            m_oscSet2.asLFO();
            m_oscSet2.setForm(MOscillator.SINE);
            m_oscMod2 = m_oscSet2.getCurrent();
            m_osc2Connect = 0;
            m_filter = new MFilter();
            m_filterConnect = 0;
            m_formant = new MFormant();
            m_volMode  = 0;
            setExpression(127);
            setVelocity(100);
            setPan(64);
            m_onCounter = 0;
            m_lfoDelay = 0;
            m_lfoDepth = 0.0;
            m_lfoEnd   = 0;
            m_lpfAmt   = 0;
            m_lpfFrq   = 0;
            m_lpfRes   = 0;
            m_pulseWidth = 0.5;
            setInput(0, 0);
            setOutput(0, 0);
            setRing(0, 0);
            setSync(0, 0);
			m_portDepth = 0;
			m_portDepthAdd = 0;
			m_lastFreqNo = 4800;
			m_portamento = 0;
			m_portRate = 0;
			m_voiceid  = 0;
			m_slaveVoice = false;
        }
        public static function boot(numSamples:int):void {
            if (!s_init) {
                var i:int;
                s_frequencyLen = s_frequencyMap.length;
                for(i = 0; i < s_frequencyLen; i++) {
                    s_frequencyMap[i] = 440.0 * Math.pow(2.0, (i-69*PITCH_RESOLUTION)/(12.0*PITCH_RESOLUTION));
                }
                s_volumeLen = 128;
				s_volumeMap = new Vector.<Vector.<Number>>(3)
				for (i = 0; i < 3; i++) {
					s_volumeMap[i] = new Vector.<Number>(s_volumeLen);
					s_volumeMap[i][0] = 0.0;
				}
                for (i = 1; i < s_volumeLen; i++) {
					s_volumeMap[0][i] = i / 127.0;
                    s_volumeMap[1][i] = Math.pow(10.0, (i-127.0)*(48.0/(127.0*20.0))); // min:-48db
                    s_volumeMap[2][i] = Math.pow(10.0, (i-127.0)*(96.0/(127.0*20.0))); // min:-96db
                    //trace(i+","+s_volumeMap[i]);
                }
                s_init = 1;
            }
            s_samples = new Vector.<Number>(numSamples);
            s_samples.fixed = true;
        }
        public static function createPipes(num:int):void {
            s_pipeArr = new Vector.<Vector.<Number>>(num);
            for (var i:int = 0; i < num; i++) {
                s_pipeArr[i] = new Vector.<Number>(s_samples.length);
                for (var j:int = 0; j < s_samples.length; j++) {
                    s_pipeArr[i][j] = 0;
                }
            }
        }
        public static function createSyncSources(num:int):void {
        	s_syncSources = new Vector.<Vector.<Boolean>>(num);
        	for (var i:int = 0; i < num; i++) {
        		s_syncSources[i] = new Vector.<Boolean>(s_samples.length);
        		for (var j:int = 0; j < s_samples.length; j++) {
        			s_syncSources[i][j] = false;
        		}
        	}
        }
        public static function getFrequency(freqNo:int):Number {
            freqNo = (freqNo < 0) ? 0 : (freqNo >= s_frequencyLen) ? s_frequencyLen-1 : freqNo;
            return s_frequencyMap[freqNo];
        }
        public function setExpression(ex:int):void {
            m_expression = s_volumeMap[m_volMode][ex];
            m_ampLevel = m_velocity * m_expression;
            ((MOscOPM)(m_oscSet1.getMod(MOscillator.OPM))).setExpression(m_expression); // ０～１．０の値
        }
        public function setVelocity(velocity:int):void {
            m_velocity = s_volumeMap[m_volMode][velocity];
            m_ampLevel = m_velocity * m_expression;
            ((MOscOPM)(m_oscSet1.getMod(MOscillator.OPM))).setVelocity(velocity); // ０～１２７の値
        }
        public function setNoteNo(noteNo:int, tie:Boolean = true):void {
            m_noteNo = noteNo;
            m_freqNo = m_noteNo * PITCH_RESOLUTION + m_detune;
            m_oscMod1.setFrequency(getFrequency(m_freqNo));

			if (m_portamento == 1) {
				if (!tie) {
					m_portDepth = m_lastFreqNo - m_freqNo;
				}
				else {
					m_portDepth += (m_lastFreqNo - m_freqNo);
				}
				m_portDepthAdd = (m_portDepth < 0) ? m_portRate : m_portRate * -1;
			}
			m_lastFreqNo = m_freqNo;
		}
        public function setDetune(detune:int):void {
            m_detune = detune;
            m_freqNo = m_noteNo * PITCH_RESOLUTION + m_detune;
            m_oscMod1.setFrequency(getFrequency(m_freqNo));
        }
		public function getNoteNo():int {
			return m_noteNo;
		}
		public function isPlaying():Boolean {
			if (m_oscSet1.getForm() == MOscillator.OPM) {
				return ((MOscOPM)(m_oscSet1.getCurrent())).IsPlaying();
			}
			else {
				return m_envelope1.isPlaying();
			}
		}
		public function getId():Number {
			return m_voiceid;
		}
		public function getVoiceCount():int {
			return isPlaying() ? 1 : 0;
		}
		public function setSlaveVoice(f:Boolean):void {
			m_slaveVoice = f;
		}
        public function noteOnWidthId(noteNo:int, velocity:int, id:Number):void {
			m_voiceid = id;
			noteOn(noteNo, velocity);
		}
        public function noteOn(noteNo:int, velocity:int):void {
            setNoteNo(noteNo, false);
            m_envelope1.triggerEnvelope(0);
            m_envelope2.triggerEnvelope(1);
            m_oscMod1.resetPhase();
            m_oscMod2.resetPhase();
            m_filter.reset();
            setVelocity(velocity);
            m_onCounter = 0;

        	var modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE));
        	modPulse.setPWM(m_pulseWidth);
			
            m_oscSet1.getMod(MOscillator.FC_NOISE  ).setNoteNo(m_noteNo);
            m_oscSet1.getMod(MOscillator.GB_NOISE  ).setNoteNo(m_noteNo);
            m_oscSet1.getMod(MOscillator.GB_S_NOISE).setNoteNo(m_noteNo);
            m_oscSet1.getMod(MOscillator.FC_DPCM   ).setNoteNo(m_noteNo);
            m_oscSet1.getMod(MOscillator.OPM       ).setNoteNo(m_noteNo);			
        }
        public function noteOff(noteNo:int):void {
            if (noteNo < 0 || noteNo == m_noteNo) {
				m_envelope1.releaseEnvelope();
				m_envelope2.releaseEnvelope();
				((MOscOPM)(m_oscSet1.getMod(MOscillator.OPM))).noteOff();
			}
        }
		public function setSoundOff():void {
			m_envelope1.soundOff();
			m_envelope2.soundOff();
		}
        public function close():void {
            noteOff(m_noteNo);
            m_filter.setSwitch(0);
        }
        public function setNoiseFreq(frequency:Number):void {
            var modNoise:MOscNoise = (MOscNoise)(m_oscSet1.getMod(MOscillator.NOISE));
            modNoise.setNoiseFreq(1.0 - frequency * (1.0 / 128.0));
        }
        public function setForm(form:int, subform:int):void {
            m_oscMod1 = m_oscSet1.setForm(form);
			m_oscMod1.setWaveNo(subform);
        }
        public function setEnvelope1Atk(attack:int):void {
        	m_envelope1.setAttack(attack * (1.0 / 127.0));
        }
        public function setEnvelope1Point(time:int, level:int):void {
        	m_envelope1.addPoint(time * (1.0 / 127.0), level * (1.0 / 127.0));
        }
        public function setEnvelope1Rel(release:int):void {
        	m_envelope1.setRelease(release * (1.0 / 127.0));
        }
        public function setEnvelope2Atk(attack:int):void {
        	m_envelope2.setAttack(attack * (1.0 / 127.0));
        }
        public function setEnvelope2Point(time:int, level:int):void {
        	m_envelope2.addPoint(time * (1.0 / 127.0), level * (1.0 / 127.0));
        }
        public function setEnvelope2Rel(release:int):void {
        	m_envelope2.setRelease(release * (1.0 / 127.0));
        }
        public function setPWM(pwm:int):void {
            if (m_oscSet1.getForm() != MOscillator.FC_PULSE) {
                var modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE));
				if (pwm < 0) {
					modPulse.setMIX(1);
					pwm *= -1;
				}
				else {
					modPulse.setMIX(0);
				}
                m_pulseWidth = pwm * 0.01;
                modPulse.setPWM(m_pulseWidth);
            }
            else {
                var modFcPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.FC_PULSE));
				if (pwm < 0) pwm *= -1;		// 以前との互換のため
                modFcPulse.setPWM(0.125 * Number(pwm));
            }
        }
        public function setPan(pan:int):void {
            // left 1 - 64 - 127 right
            // master_vol = (0.25 * 2)
            m_pan = (pan - 1) * (0.5 / 63.0);
            if (m_pan < 0) m_pan = 0;
        }
        public function setFormant(vowel:int):void {
            if (vowel >= 0) m_formant.setVowel(vowel);
            else m_formant.disable();
        }
        public function setLFOFMSF(form:int, subform:int):void {
            m_oscMod2 = m_oscSet2.setForm((form >= 0) ? form - 1 : -form - 1);
			m_oscMod2.setWaveNo(subform);
            m_osc2Sign = (form >= 0) ? 1.0 : -1.0;
            if (form < 0) form = -form;
            form--;
            if (form >= MOscillator.MAX) m_osc2Connect = 0;
//          if (form == MOscillator.GB_WAVE)
//              (MOscGbWave)(m_oscSet2.getMod(MOscillator.GB_WAVE)).setWaveNo(subform);
//          if (form == MOscillator.FC_DPCM)
//              (MOscFcDpcm)(m_oscSet2.getMod(MOscillator.FC_DPCM)).setWaveNo(subform);
//          if (form == MOscillator.WAVE)
//              (MOscWave)(m_oscSet2.getMod(MOscillator.WAVE)).setWaveNo(subform);
//          if (form == MOscillator.SINE)
//              (MOscSine)(m_oscSet2.getMod(MOscillator.SINE)).setWaveNo(subform);
        }
        public function setLFODPWD(depth:int, freq:Number):void {
            m_lfoDepth = depth;
            m_osc2Connect = (depth == 0) ? 0 : 1;
            m_oscMod2.setFrequency(freq);
            m_oscMod2.resetPhase();
            (MOscNoise)(m_oscSet2.getMod(MOscillator.NOISE)).setNoiseFreq(freq/MSequencer.RATE44100);
        }
        public function setLFODLTM(delay:int, time:int):void {
            m_lfoDelay = delay;
            m_lfoEnd = (time > 0) ? m_lfoDelay + time : 0;
        }
        public function setLFOTarget(target:int):void {
        	m_lfoTarget = target;
        }
        public function setLpfSwtAmt(swt:int, amt:int):void {
            if (-3 < swt && swt < 3 && swt != m_filterConnect) {
                m_filterConnect = swt;
                m_filter.setSwitch(swt);
            }
            m_lpfAmt = ((amt < -127) ? -127 : (amt < 127) ? amt : 127) * PITCH_RESOLUTION;
        }
        public function setLpfFrqRes(frq:int, res:int):void {
            if (frq < 0) frq = 0;
            if (frq > 127) frq = 127;
            m_lpfFrq = frq * PITCH_RESOLUTION;
            m_lpfRes = res * (1.0 / 127.0);
            if (m_lpfRes < 0.0) m_lpfRes = 0.0;
            if (m_lpfRes > 1.0) m_lpfRes = 1.0;
        }
        public function setVolMode(m:int):void {
			switch (m) {
			case 0:
			case 1:
			case 2: 
				m_volMode = m; 
				break;
			}
        }
        public function setInput(i:int, p:int):void {
            m_inSens = (1<<(i-1)) * (1.0 / 8.0) * MOscMod.PHASE_LEN;
            m_inPipe = p;
        }
        public function setOutput(o:int, p:int):void {
            m_outMode = o;
            m_outPipe = p;
        }
        public function setRing(s:int, p:int):void {
        	m_ringSens = (1 << (s - 1)) / 8.0;
        	m_ringPipe = p;
        }
        public function setSync(m:int, p:int):void {
        	m_syncMode = m;
        	m_syncPipe = p;
        }
		public function setPortamento(depth:int, len:Number):void {
			m_portamento = 0;
			m_portDepth = depth;
			m_portDepthAdd = (Number(m_portDepth) / len) * -1;
		}
		public function setMidiPort(mode:int):void {
			m_portamento = mode;
			m_portDepth = 0;
		}
		public function setMidiPortRate(rate:Number):void {
			m_portRate = rate;
		}
		public function setPortBase(base:int):void {
			m_lastFreqNo = base;
		}
		public function setVoiceLimit(voiceLimit:int) : void {
			// 無視
		}		
        public function setHwLfo(data:int):void {
            var w:int   = (data>>27) & 0x03;
            var f:int   = (data>>19) & 0xFF;
            var pmd:int = (data>>12) & 0x7F;
            var amd:int = (data>> 5) & 0x7F;
            var pms:int = (data>> 2) & 0x07;
            var ams:int = (data>> 0) & 0x03;
            var fm:MOscOPM = ((MOscOPM)(m_oscSet1.getMod(MOscillator.OPM)));
            fm.setWF(w);
            fm.setLFRQ(f);
            fm.setPMD(pmd);
            fm.setAMD(amd);
            fm.setPMSAMS(pms, ams);
        }		
		public function reset():void {
			// 基本
			setSoundOff();
		    m_pulseWidth	= 0.5;	
            m_voiceid       = 0;			
			setForm(0, 0);
			setDetune(0);
			setExpression(127);
			setVelocity(100);
			setPan(64);
			setVolMode(0);
			setNoiseFreq(0.0);
			// LFO
			setLFOFMSF(0, 0);
		    m_osc2Connect	= 0;
			m_onCounter		= 0;
			m_lfoTarget		= 0;
		    m_lfoDelay 		= 0;
		    m_lfoDepth 		= 0.0;
		    m_lfoEnd   		= 0;
			// フィルタ
			setLpfSwtAmt(0, 0);
			setLpfFrqRes(0, 0);
			setFormant(-1);
			// パイプ
			setInput(0, 0);
			setOutput(0, 0);
			setRing(0, 0);
			setSync(0, 0);
			// ポルタメント
		    m_portDepth     = 0;
		    m_portDepthAdd  = 0;
		    m_lastFreqNo    = 4800;
		    m_portamento    = 0;
		    m_portRate      = 0;
		}
		public function clearOutPipe(max:int, start:int, delta:int):void {
			var end:int = start + delta;
			if (end >= max) end = max;
			if (m_outMode == 1) {
				for(var i:int = start; i < end; i++) {
					s_pipeArr[m_outPipe][i] = 0.0;
				}				
			}
		}
        protected function getNextCutoff():Number {
            var cut:Number = m_lpfFrq + m_lpfAmt * m_envelope2.getNextAmplitudeLinear();
            cut = getFrequency(cut) * m_oscMod1.getFrequency() * (2.0 * Math.PI / (MSequencer.RATE44100 * 440.0));
            if (cut < (1.0/127.0)) cut = 0.0;
            return cut;
        }
        public function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void {
            var end:int = start + delta;
            var trackBuffer:Vector.<Number> = s_samples, sens:Number, pipe:Vector.<Number>;
            var amplitude:Number, rightAmplitude:Number;
            var playing:Boolean = isPlaying(), tmpFlag:Boolean;
            var vol:Number, lpffrq:int, pan:Number, depth:Number;
            var i:int, j:int, s:int, e:int;
            if (end >= max) end = max;
            var key:Number = getFrequency(m_freqNo);
            if(m_outMode == 1 && m_slaveVoice == false){
            	// @o1 が指定されていれば直接パイプに音声を書き込む
            	trackBuffer = s_pipeArr[m_outPipe];
            }
            if (playing) {
				if (m_portDepth == 0) {
					if(m_inSens >= 0.000001){
						if(m_osc2Connect == 0){
							getSamplesF__(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesFP_(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesFW_(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_FM){
							getSamplesFF_(trackBuffer, start, end);
						}else{
							getSamplesF__(trackBuffer, start, end);
						}
					}else if(m_syncMode == 2){
						if(m_osc2Connect == 0){
							getSamplesI__(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesIP_(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesIW_(trackBuffer, start, end);
						}else{
							getSamplesI__(trackBuffer, start, end);
						}
					}else if(m_syncMode == 1){
						if(m_osc2Connect == 0){
							getSamplesO__(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesOP_(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesOW_(trackBuffer, start, end);
						}else{
							getSamplesO__(trackBuffer, start, end);
						}
					}else{
						if(m_osc2Connect == 0){
							getSamples___(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamples_P_(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamples_W_(trackBuffer, start, end);
						}else{
							getSamples___(trackBuffer, start, end);
						}
					}
				}
				else {
					if(m_inSens >= 0.000001){
						if(m_osc2Connect == 0){
							getSamplesF_P(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesFPP(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesFWP(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_FM){
							getSamplesFFP(trackBuffer, start, end);
						}else{
							getSamplesF_P(trackBuffer, start, end);
						}
					}else if(m_syncMode == 2){
						if(m_osc2Connect == 0){
							getSamplesI_P(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesIPP(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesIWP(trackBuffer, start, end);
						}else{
							getSamplesI_P(trackBuffer, start, end);
						}
					}else if(m_syncMode == 1){
						if(m_osc2Connect == 0){
							getSamplesO_P(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamplesOPP(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamplesOWP(trackBuffer, start, end);
						}else{
							getSamplesO_P(trackBuffer, start, end);
						}
					}else{
						if(m_osc2Connect == 0){
							getSamples__P(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PITCH){
							getSamples_PP(trackBuffer, start, end);
						}else if(m_lfoTarget == LFO_TARGET_PWM){
							getSamples_WP(trackBuffer, start, end);
						}else{
							getSamples__P(trackBuffer, start, end);
						}
					}
				}
            }
			if (m_oscSet1.getForm() != MOscillator.OPM) {
				if(m_volMode == 0){
					m_envelope1.ampSamplesLinear(trackBuffer, start, end, m_ampLevel);
				}else{
					m_envelope1.ampSamplesNonLinear(trackBuffer, start, end, m_ampLevel, m_volMode);
				}
            }
            if(m_lfoTarget == LFO_TARGET_AMPLITUDE && m_osc2Connect != 0){	// with Amplitude LFO
                depth = m_osc2Sign * m_lfoDepth / 127.0;
                s = start;
                for(i = start; i < end; i++) {
                    vol = 1.0;
                    if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                        vol += m_oscMod2.getNextSample() * depth;
                    }
                    if(vol < 0){
                    	vol = 0;
                    }
					trackBuffer[i] *= vol;
                    m_onCounter++;
                }
            }
            if(playing && (m_ringSens >= 0.000001)){ // with ring
            	pipe = s_pipeArr[m_ringPipe];
            	sens = m_ringSens;
            	for(i = start; i < end; i++){
					trackBuffer[i] *= pipe[i] * sens;
				}
            }
            
            // フォルマントフィルタを経由した後の音声が無音であればスキップ
            tmpFlag = playing;
            playing = playing || m_formant.checkToSilence();
            if(playing != tmpFlag){
                for(i = start; i < end; i++) trackBuffer[i] = 0;
            }
            if(playing){
                m_formant.run(trackBuffer, start, end);
            }

            // フィルタを経由した後の音声が無音であればスキップ
            tmpFlag = playing;
            playing = playing || m_filter.checkToSilence();
            if(playing != tmpFlag){
                for(i = start; i < end; i++) trackBuffer[i] = 0;
            }
            if(playing){
            	if(m_lfoTarget == LFO_TARGET_CUTOFF && m_osc2Connect != 0){	// with Filter LFO
            	    depth = m_osc2Sign * m_lfoDepth;
	                s = start;
	                do {
	                    e = s + s_lfoDelta;
	                    if (e > end) e = end;
	                    lpffrq = m_lpfFrq;
	                    if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
	                        lpffrq += m_oscMod2.getNextSample() * depth;
	                        m_oscMod2.addPhase(e - s - 1);
	                    }
	                    if(lpffrq < 0.0){
	                    	lpffrq = 0.0;
	                    }else if(lpffrq > 127.0 * PITCH_RESOLUTION){
	                    	lpffrq = 127.0 * PITCH_RESOLUTION;
	                    }
		            	m_filter.run(s_samples, s, e, m_envelope2, lpffrq, m_lpfAmt, m_lpfRes, key);
	                    m_onCounter += e - s;
	                    s = e;
	                } while(s < end);
            	}else{
                    m_filter.run(trackBuffer, start, end, m_envelope2, m_lpfFrq, m_lpfAmt, m_lpfRes, key);
                }
            }
            
            if(playing){
                switch(m_outMode) {
                case 0:
                    //trace("output audio");
                    if(m_lfoTarget == LFO_TARGET_PANPOT && m_osc2Connect != 0){ // with Panpot LFO
                        depth = m_osc2Sign * m_lfoDepth * (1.0 / 127.0);
                        for(i = start; i < end; i++) {
                            j = i + i;
                            pan = m_pan + m_oscMod2.getNextSample() * depth;
                            if(pan < 0){
                                pan = 0;
                            }else if(pan > 1.0){
                                pan = 1.0;
                            }
                            amplitude = trackBuffer[i] * 0.5;
                            rightAmplitude = amplitude * pan;
                            samples[j] += amplitude - rightAmplitude;
                            j++;
                            samples[j] += rightAmplitude;
                        }
                    }else{
                        for(i = start; i < end; i++) {
                            j = i + i;
                            amplitude = trackBuffer[i] * 0.5;
                            rightAmplitude = amplitude * m_pan;
                            samples[j] += amplitude - rightAmplitude;
                            j++;
                            samples[j] += rightAmplitude;
                        }
                    }
                    break;
                case 1: // overwrite
                /* リングモジュレータと音量LFOの同時使用時に問題が出てたようなので
                   一旦戻します。 2010.09.22 tekisuke */
                    //trace("output "+m_outPipe);
                    pipe = s_pipeArr[m_outPipe];
					if (m_slaveVoice == false) {
						for(i = start; i < end; i++) {
							pipe[i]  = trackBuffer[i];
						}
					}
					else {
						for(i = start; i < end; i++) {
							pipe[i] += trackBuffer[i];
						}
					}
                    break;
                case 2: // add
                    pipe = s_pipeArr[m_outPipe];
                    for(i = start; i < end; i++) {
                        pipe[i] += trackBuffer[i];
                    }
                    break;
                }
            }else if(m_outMode == 1){
                pipe = s_pipeArr[m_outPipe];
				if (m_slaveVoice == false) {
					for(i = start; i < end; i++) {
						pipe[i] = 0.0;
					}
				}
            }
        }
        
        // 波形生成部の関数群
        // [pipe] := [_:なし], [F:FM入力], [I:Sync入力], [O:Sync出力]
        // [lfo]  := [_:なし], [P:音程], [W:パルス幅], [F:FM入力レベル]
		// [pro.] := [_:なし], [p:ポルタメント]
        // private function getSamples[pipe][lfo](samples:Vector.<Number>, start:int, end:int):void
        
        // パイプ処理なし, LFOなし, ポルタメントなし
        private function getSamples___(samples:Vector.<Number>, start:int, end:int):void {
			m_oscMod1.getSamples(samples, start, end);
        }
        // パイプ処理なし, 音程LFO, ポルタメントなし
        private function getSamples_P_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth;
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamples(samples, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // パイプ処理なし, パルス幅(@3)LFO, ポルタメントなし
        private function getSamples_W_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE));
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                	pwm = 0;
                }else if(pwm > 100.0){
                	pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamples(samples, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // FM入力, LFOなし, ポルタメントなし
        private function getSamplesF__(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, sens:Number = m_inSens, pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            // rev.35879 以前の挙動にあわせるため
            m_oscMod1.setFrequency(getFrequency(m_freqNo) >> 0);
            for(i = start; i < end; i++) {
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
            }
        }
        // FM入力, 音程LFO, ポルタメントなし
        private function getSamplesFP_(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, freqNo:int, sens:Number = m_inSens, depth:Number = m_osc2Sign * m_lfoDepth,
                pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            for(i = start; i < end; i++) {
                freqNo = m_freqNo;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // FM入力, パルス幅(@3)LFO, ポルタメントなし
        private function getSamplesFW_(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                sens:Number = m_inSens, pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            // rev.35879 以前の挙動にあわせるため
            m_oscMod1.setFrequency(getFrequency(m_freqNo) >> 0);
            for(i = start; i < end; i++) {
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // FM入力, FM入力レベル, ポルタメントなし
        private function getSamplesFF_(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, freqNo:int, sens:Number, depth:Number = m_osc2Sign * m_lfoDepth * (1.0 / 127.0),
                pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            // rev.35879 以前の挙動にあわせるため
            m_oscMod1.setFrequency(getFrequency(m_freqNo) >> 0);
            for(i = start; i < end; i++) {
                sens = m_inSens;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    sens *= m_oscMod2.getNextSample() * depth;
                }
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // Sync入力, LFOなし, ポルタメントなし
        private function getSamplesI__(samples:Vector.<Number>, start:int, end:int):void {
            m_oscMod1.getSamplesWithSyncIn(samples, s_syncSources[m_syncPipe], start, end);
        }
        // Sync入力, 音程LFO, ポルタメントなし
        private function getSamplesIP_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncIn(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // Sync入力, パルス幅(@3)LFO, ポルタメントなし
        private function getSamplesIW_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamplesWithSyncIn(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // Sync出力, LFOなし, ポルタメントなし
        private function getSamplesO__(samples:Vector.<Number>, start:int, end:int):void {
            m_oscMod1.getSamplesWithSyncOut(samples, s_syncSources[m_syncPipe], start, end);
        }
        // Sync出力, 音程LFO, ポルタメントなし
        private function getSamplesOP_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncOut(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // Sync出力, パルス幅(@3)LFO, ポルタメントなし
        private function getSamplesOW_(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamplesWithSyncOut(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }

		/*** ここから下がポルタメントありの場合 ***/
		
        // パイプ処理なし, LFOなし, ポルタメントあり
        private function getSamples__P(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int;
			do {
				e = s + s_lfoDelta;
				if (e > end) e = end;
				freqNo = m_freqNo
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamples(samples, s, e);
                s = e;
			} while (s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
        }
        // パイプ処理なし, 音程LFO, ポルタメントあり
        private function getSamples_PP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth;
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
				if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
					freqNo += m_oscMod2.getNextSample() * depth;
					m_oscMod2.addPhase(e - s - 1);
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamples(samples, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // パイプ処理なし, パルス幅(@3)LFO, ポルタメントあり
        private function getSamples_WP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01, freqNo:Number,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE));
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;

				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
				m_oscMod1.setFrequency(getFrequency(freqNo));

                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                	pwm = 0;
                }else if(pwm > 100.0){
                	pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamples(samples, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
        }
        // FM入力, LFOなし, ポルタメントあり
        private function getSamplesF_P(samples:Vector.<Number>, start:int, end:int):void {
            var freqNo:int, i:int, sens:Number = m_inSens, pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            for (i = start; i < end; i++) {
				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += m_portDepthAdd;
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
				m_oscMod1.setFrequency(getFrequency(freqNo));
				samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
			}
        }
        // FM入力, 音程LFO, ポルタメントあり
        private function getSamplesFPP(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, freqNo:int, sens:Number = m_inSens, depth:Number = m_osc2Sign * m_lfoDepth,
                pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            for(i = start; i < end; i++) {
				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += m_portDepthAdd;
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // FM入力, パルス幅(@3)LFO, ポルタメントあり
        private function getSamplesFWP(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, freqNo:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                sens:Number = m_inSens, pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            for (i = start; i < end; i++) {
				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += m_portDepthAdd;
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
				m_oscMod1.setFrequency(getFrequency(freqNo));
				pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // FM入力, FM入力レベル, ポルタメントあり
        private function getSamplesFFP(samples:Vector.<Number>, start:int, end:int):void {
            var i:int, freqNo:int, sens:Number, depth:Number = m_osc2Sign * m_lfoDepth * (1.0 / 127.0),
                pipe:Vector.<Number> = s_pipeArr[m_inPipe];
            for (i = start; i < end; i++) {
				freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += m_portDepthAdd;
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
				m_oscMod1.setFrequency(getFrequency(freqNo));
                sens = m_inSens;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    sens *= m_oscMod2.getNextSample() * depth;
                }
                samples[i] = m_oscMod1.getNextSampleOfs(pipe[i] * sens);
                m_onCounter++;
            }
        }
        // Sync入力, LFOなし, ポルタメントあり
        private function getSamplesI_P(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncIn(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while (s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
		}
        // Sync入力, 音程LFO, ポルタメントあり
        private function getSamplesIPP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncIn(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // Sync入力, パルス幅(@3)LFO, ポルタメントあり
        private function getSamplesIWP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamplesWithSyncIn(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
        }
        // Sync出力, LFOなし, ポルタメントあり
        private function getSamplesO_P(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncOut(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
        }
        // Sync出力, 音程LFO, ポルタメントあり
        private function getSamplesOPP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, depth:Number = m_osc2Sign * m_lfoDepth,
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    freqNo += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                m_oscMod1.setFrequency(getFrequency(freqNo));
                m_oscMod1.getSamplesWithSyncOut(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
        }
        // Sync出力, パルス幅(@3)LFO, ポルタメントあり
        private function getSamplesOWP(samples:Vector.<Number>, start:int, end:int):void {
            var s:int = start, e:int, freqNo:int, pwm:Number, depth:Number = m_osc2Sign * m_lfoDepth * 0.01,
                modPulse:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)),
                syncLine:Vector.<Boolean> = s_syncSources[m_syncPipe];
            do {
                e = s + s_lfoDelta;
                if (e > end) e = end;
                freqNo = m_freqNo;
				if (m_portDepth != 0) {
					freqNo += m_portDepth;
					m_portDepth += (m_portDepthAdd * (e - s - 1));
					if (m_portDepth * m_portDepthAdd > 0) m_portDepth = 0;
				}
                m_oscMod1.setFrequency(getFrequency(freqNo));
                pwm = m_pulseWidth;
                if (m_onCounter >= m_lfoDelay && (m_lfoEnd == 0 || m_onCounter < m_lfoEnd)) {
                    pwm += m_oscMod2.getNextSample() * depth;
                    m_oscMod2.addPhase(e - s - 1);
                }
                if(pwm < 0){
                    pwm = 0;
                }else if(pwm > 100.0){
                    pwm = 100.0;
                }
                modPulse.setPWM(pwm);
                m_oscMod1.getSamplesWithSyncOut(samples, syncLine, s, e);
                m_onCounter += e - s;
                s = e;
            } while(s < end)
			if (m_portDepth == 0) {
                m_oscMod1.setFrequency(getFrequency(m_freqNo));
			}
        }
	}
}
