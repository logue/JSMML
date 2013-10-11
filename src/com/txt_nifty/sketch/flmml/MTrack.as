package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;
	import flash.errors.MemoryError;

    public class MTrack {
        public static const TEMPO_TRACK:int = 0;
        public static const FIRST_TRACK:int = 1;
        public static const DEFAULT_BPM:int = 120;
        private var m_bpm:Number;         // beat per minute
        private var m_spt:Number;         // samples per tick
        private var m_ch:IChannel;        // channel (instrument)
        private var m_needle:Number       // delta time
        private var m_volume:int;         // default volume    (max:127)
        private var m_gate:Number;        // default gate time (max:1.0)
        private var m_gate2:int;          // gate time 2
        private var m_events:Array;       //
        private var m_pointer:int;        // current event no.
        private var m_delta:int;
        private var m_isEnd:int;
        private var m_globalTick:uint;
        private var m_signalCnt:int;
        private var m_lfoWidth:Number;
        private var m_totalMSec:uint;
        public  var m_signalInterval:int;
		private var m_polyFound:Boolean;
		private var m_chordBegin:uint;
		private var m_chordEnd:uint;
		private var m_chordMode:Boolean;

        public function MTrack() {
            m_isEnd              = 0;
            m_ch                 = new MChannel();
            m_needle             = 0.0;
			m_polyFound			 = false;
            playTempo(DEFAULT_BPM);
            m_volume             = 100;
            recGate(15.0/16.0);
            recGate2(0);
            m_events             = new Array();
            m_pointer = 0;
            m_delta = 0;
            m_globalTick = 0;
            m_signalInterval = 96/4; // (quater note = 96ticks)
            m_signalCnt = 0;
            m_lfoWidth = 0.0;
            m_totalMSec = 0;
			m_chordBegin = 0;
			m_chordEnd = 0;
			m_chordMode = false;
        }

        public function getNumEvents():int {
            return m_events.length;
        }

        public function onSampleData(samples:Vector.<Number>, start:int, end:int, signal:MSignal = null):void {
            if (isEnd()) return;
            var startCnt:int = m_signalCnt;
            if (signal != null) signal.reset();
            // first signal
            if (m_globalTick == 0 && signal != null) {
                signal.add(0, 0, 0);
            }
            for (var i:int = start; i < end;) {
                // exec events
                var exec:int = 0;
                var eLen:int = m_events.length;
                var e:MEvent;
                var delta:Number;
                do {
                    exec = 0;
                    if (m_pointer < eLen) {
                        e = m_events[m_pointer];
                        delta = e.getDelta() * m_spt;
                        if (m_needle >= delta) {
                            //trace(m_pointer+"/global:"+(int)(m_globalTick/m_spt)+"/status:"+e.getStatus()+"/delta:"+delta+"-"+e.getDelta()+"/noteNo:"+e.getNoteNo());
                            exec = 1;
                            switch(e.getStatus()) {
                            case MStatus.NOTE_ON:
                                m_ch.noteOn(e.getNoteNo(), e.getVelocity());
                                break;
                            case MStatus.NOTE_OFF:
                                m_ch.noteOff(e.getNoteNo());
                                break;
                            case MStatus.NOTE:
                                m_ch.setNoteNo(e.getNoteNo());
                                break;
                            case MStatus.VOLUME:
                                break;
                            case MStatus.TEMPO:
                                playTempo(e.getTempo());
                                break;
                            case MStatus.FORM:
                                m_ch.setForm(e.getForm(), e.getSubForm());
                                break;
                            case MStatus.ENVELOPE1_ATK:
                            	m_ch.setEnvelope1Atk(e.getEnvelopeA());
                            	break;
                            case MStatus.ENVELOPE1_ADD:
                            	m_ch.setEnvelope1Point(e.getEnvelopeT(), e.getEnvelopeL());
                            	break;
                            case MStatus.ENVELOPE1_REL:
                            	m_ch.setEnvelope1Rel(e.getEnvelopeR());
                            	break;
                            case MStatus.ENVELOPE2_ATK:
                            	m_ch.setEnvelope2Atk(e.getEnvelopeA());
                            	break;
                            case MStatus.ENVELOPE2_ADD:
                            	m_ch.setEnvelope2Point(e.getEnvelopeT(), e.getEnvelopeL());
                            	break;
                            case MStatus.ENVELOPE2_REL:
                            	m_ch.setEnvelope2Rel(e.getEnvelopeR());
                            	break;
                            case MStatus.NOISE_FREQ:
                                m_ch.setNoiseFreq(e.getNoiseFreq());
                                break;
                            case MStatus.PWM:
                                m_ch.setPWM(e.getPWM());
                                break;
                            case MStatus.PAN:
                                m_ch.setPan(e.getPan());
                                break;
                            case MStatus.FORMANT:
                                m_ch.setFormant(e.getVowel());
                                break;
                            case MStatus.DETUNE:
                                m_ch.setDetune(e.getDetune());
                                break;
                            case MStatus.LFO_FMSF:
                                m_ch.setLFOFMSF(e.getLFOForm(), e.getLFOSubForm());
                                break;
                            case MStatus.LFO_DPWD:
                                m_lfoWidth = e.getLFOWidth() * m_spt;
                                m_ch.setLFODPWD(e.getLFODepth(), 44100.0 / m_lfoWidth);
                                break;
                            case MStatus.LFO_DLTM:
                                m_ch.setLFODLTM(e.getLFODelay() * m_spt, e.getLFOTime() * m_lfoWidth);
                                break;
                            case MStatus.LFO_TARGET:
                                m_ch.setLFOTarget(e.getLFOTarget());
                                break;
                            case MStatus.LPF_SWTAMT:
                                m_ch.setLpfSwtAmt(e.getLPFSwt(), e.getLPFAmt());
                                break;
                            case MStatus.LPF_FRQRES:
                                m_ch.setLpfFrqRes(e.getLPFFrq(), e.getLPFRes());
                                break;
                            case MStatus.VOL_MODE:
                                m_ch.setVolMode(e.getVolMode());
                                break;
                            case MStatus.INPUT:
                                m_ch.setInput(e.getInputSens(), e.getInputPipe());
                                break;
                            case MStatus.OUTPUT:
                                m_ch.setOutput(e.getOutputMode(), e.getOutputPipe());
                                break;
                            case MStatus.EXPRESSION:
                                m_ch.setExpression(e.getExpression());
                                break;
                            case MStatus.RINGMODULATE:
                                m_ch.setRing(e.getRingSens(), e.getRingInput());
                                break;
                            case MStatus.SYNC:
                                m_ch.setSync(e.getSyncMode(), e.getSyncPipe());
                                break;
							case MStatus.PORTAMENTO:
								m_ch.setPortamento(e.getPorDepth() * 100, e.getPorLen() * m_spt);
								break;
							case MStatus.MIDIPORT:
								m_ch.setMidiPort(e.getMidiPort());
								break;
							case MStatus.MIDIPORTRATE:
								var rate:Number = e.getMidiPortRate();
								m_ch.setMidiPortRate((8 - (rate * 7.99 / 128)) / rate);
								break;
							case MStatus.BASENOTE:
								m_ch.setPortBase(e.getPortBase() * 100);
								break;
							case MStatus.POLY:
								m_ch.setVoiceLimit(e.getVoiceCount());
								break;
							case MStatus.HW_LFO:
								m_ch.setHwLfo(e.getHwLfoData());								
								break;
							case MStatus.SOUND_OFF:
								m_ch.setSoundOff();
								break;
							case MStatus.RESET_ALL:
								m_ch.reset();
								break;								
                            case MStatus.CLOSE:
                                m_ch.close();
                                break;
                            case MStatus.EOT:
                                m_isEnd = 1;
                                break;
                            case MStatus.NOP:
                                break;
                            default:
                                break;
                            }
                            m_needle -= delta;
                            m_pointer++;
                        }
                    }
                } while(exec);

                // create a short wave
                var di:int;
                if (m_pointer < eLen) {
                    e = m_events[m_pointer];
                    delta = e.getDelta() * m_spt;
                    di = Math.ceil(delta - m_needle);
                    if (i + di >= end) di = end - i;
                    m_needle += di;
                    if (signal == null) m_ch.getSamples(samples, end, i, di);
                    i += di;
                }
                else {
                    break;
                }

                // periodic signal
                if (signal != null) {
                    m_signalCnt += di;
                    var intervalSample:int = int(m_signalInterval * m_spt);
                    if (intervalSample > 0) {
                        while (m_signalCnt >= intervalSample) {
                            m_globalTick += m_signalInterval;
                            signal.add(int((intervalSample - startCnt) * (1000.0/44100.0)), m_globalTick, 0);
                            m_signalCnt -= intervalSample;
                            startCnt = 0;
                        }
                    }
                }
            }
            if (signal != null) signal.terminate();
        }

        public function seek(delta:int):void {
            m_delta += delta;
            m_globalTick += delta;
			m_chordEnd = Math.max(m_chordEnd, m_globalTick);
        }
		
		public function seekChordStart():void {
            m_globalTick = m_chordBegin;
		}

        public function recDelta(e:MEvent):void {
            e.setDelta(m_delta);
            m_delta = 0;
        }

        public function recNote(noteNo:int, len:int, vel:int, keyon:int = 1, keyoff:int = 1):void {
            var e0:MEvent = makeEvent();
            if (keyon) {
                e0.setNoteOn(noteNo, vel);
            }
            else {
                e0.setNote(noteNo);
            }
            pushEvent(e0);
            if (keyoff) {
                var gate:int;
                gate = (int)(len * m_gate) - m_gate2;
                if (gate <= 0) gate = 0;
                seek(gate);
				recNoteOff(noteNo, vel);
                seek(len - gate);
				if (m_chordMode) {
					seekChordStart();
				}
            }
            else {
                seek(len);
            }
        }
		
		public function recNoteOff(noteNo:int, vel:int):void {
			var e:MEvent = makeEvent();
			e.setNoteOff(noteNo, vel);
			pushEvent(e);
		}

        public function recRest(len:int):void {
            seek(len);
			if (m_chordMode) {
				m_chordBegin += len;
			}
        }
		
		public function recChordStart():void {
			if (m_chordMode == false) {
				m_chordMode = true;
				m_chordBegin = m_globalTick;
			}
		}
		
		public function recChordEnd():void {
			if (m_chordMode) {
				if (m_events.length > 0) {
					m_delta = m_chordEnd - m_events[m_events.length-1].getTick();
				}
				else {
					m_delta = 0;
				}
				m_globalTick = m_chordEnd;
				m_chordMode = false;
			}
		}
		
        public function recRestMSec(msec:int):void {
            var len:int = msec * 44100 / (m_spt * 1000);
            seek(len);
        }

        public function recVolume(vol:int):void {
            var e:MEvent = makeEvent();
            e.setVolume(vol);
            pushEvent(e);
        }

		// 挿入先が同時間の場合、前に挿入する。ただし、挿入先がテンポコマンドの場合を除く。
        protected function recGlobal(globalTick:uint, e:MEvent):void {
            var n:int = m_events.length;
            var preGlobalTick:uint = 0;
            var tmpArr:Array = new Array();
            for(var i:int; i < n; i++) {
                var en:MEvent = m_events[i];
                var nextTick:uint = preGlobalTick + en.getDelta();
                if (nextTick > globalTick || (nextTick == globalTick && en.getStatus() != MStatus.TEMPO)) {
                    en.setDelta(nextTick - globalTick);
                    e.setDelta(globalTick - preGlobalTick);
                    m_events.splice(i, 0, e);
                    //trace("e(TEMPO"+e.getTempo()+") delta="+(globalTick-preGlobalTick));
                    return;
                }
                preGlobalTick = nextTick;
            }
            e.setDelta(globalTick-preGlobalTick);
            m_events.push(e);
            //trace("e(TEMPO"+e.getTempo()+") delta="+(globalTick-preGlobalTick));
        }
			
		// 挿入先が同時間の場合、後に挿入する。
        protected function insertEvent(e:MEvent):void {
            var n:int = m_events.length;
            var preGlobalTick:uint = 0;
			var globalTick:uint = e.getTick();
            var tmpArr:Array = new Array();
            for(var i:int; i < n; i++) {
                var en:MEvent = m_events[i];
                var nextTick:uint = preGlobalTick + en.getDelta();
                if (nextTick > globalTick) {
                    en.setDelta(nextTick - globalTick);
                    e.setDelta(globalTick - preGlobalTick);
                    m_events.splice(i, 0, e);
                    return;
                }
                preGlobalTick = nextTick;
            }
            e.setDelta(globalTick-preGlobalTick);
            m_events.push(e);
        }		
		
		// 新規イベントインスタンスを得る
		protected function makeEvent():MEvent {
			var e:MEvent = new MEvent(m_globalTick);
			e.setDelta(m_delta);
			m_delta = 0;
			return e;
		}
		
		// イベントを適切に追加する
		protected function pushEvent(e:MEvent):void {
			if (m_chordMode == false) {
				m_events.push(e);
			}
			else {
				insertEvent(e);
			}
		}

        public function recTempo(globalTick:uint, tempo:Number):void {
            var e:MEvent = new MEvent(globalTick); // makeEvent()は使用してはならない
            e.setTempo(tempo);
            recGlobal(globalTick, e);
        }

        public function recEOT():void {
            var e:MEvent = makeEvent();
            e.setEOT();
            pushEvent(e);
        }

        public function recGate(gate:Number):void {
            m_gate = gate;
        }

        public function recGate2(gate2:int):void {
            if (gate2 < 0) gate2 = 0;
            m_gate2 = gate2;
        }

        public function recForm(form:int, sub:int):void {
            var e:MEvent = makeEvent();
            e.setForm(form, sub);
            pushEvent(e);
        }

        public function recEnvelope(env:int, attack:int, times:Vector.<int>, levels:Vector.<int>, release:int):void {
            var e:MEvent = makeEvent();
            if (env == 1) e.setEnvelope1Atk(attack); else e.setEnvelope2Atk(attack);
            pushEvent(e);
            for(var i:int = 0, pts:int = times.length; i < pts; i++){
            	e = makeEvent();
          		if (env == 1) e.setEnvelope1Point(times[i], levels[i]); else e.setEnvelope2Point(times[i], levels[i]);
            	pushEvent(e);
            }
            e = makeEvent();
            if (env == 1) e.setEnvelope1Rel(release); else e.setEnvelope2Rel(release);
            pushEvent(e);
        }

        public function recNoiseFreq(freq:int):void {
            var e:MEvent = makeEvent();
            e.setNoiseFreq(freq);
            pushEvent(e);
        }

        public function recPWM(pwm:int):void {
            var e:MEvent = makeEvent();
            e.setPWM(pwm);
            pushEvent(e);
        }

        public function recPan(pan:int):void {
            var e:MEvent = makeEvent();
            e.setPan(pan);
            pushEvent(e);
        }

        public function recFormant(vowel:int):void {
            var e:MEvent = makeEvent();
            e.setFormant(vowel);
            pushEvent(e);
        }

        public function recDetune(d:int):void {
            var e:MEvent = makeEvent();
            e.setDetune(d);
            pushEvent(e);
        }

        public function recLFO(depth:int, width:int, form:int, subform:int, delay:int, time:int, target:int):void {
            var e:MEvent = makeEvent();
            e.setLFOFMSF(form, subform);
            pushEvent(e);
            e = makeEvent();
            e.setLFODPWD(depth, width);
            pushEvent(e);
            e = makeEvent();
            e.setLFODLTM(delay, time);
            pushEvent(e);
            e = makeEvent();
            e.setLFOTarget(target);
            pushEvent(e);
        }

        public function recLPF(swt:int, amt:int, frq:int, res:int):void {
            var e:MEvent = makeEvent();
            e.setLPFSWTAMT(swt, amt);
            pushEvent(e);
            e = makeEvent();
            e.setLPFFRQRES(frq, res);
            pushEvent(e);
        }

        public function recVolMode(m:int): void {
            var e:MEvent = makeEvent();
            e.setVolMode(m);
            pushEvent(e);
        }

        public function recInput(sens:int, pipe:int):void {
            var e:MEvent = makeEvent();
            e.setInput(sens, pipe);
            pushEvent(e);
        }

        public function recOutput(mode:int, pipe:int):void {
            var e:MEvent = makeEvent();
            e.setOutput(mode, pipe);
            pushEvent(e);
        }

        public function recExpression(ex:int):void {
            var e:MEvent = makeEvent();
            e.setExpression(ex);
            pushEvent(e);
        }
        
        public function recRing(sens:int, pipe:int):void {
        	var e:MEvent = makeEvent();
        	e.setRing(sens, pipe);
        	pushEvent(e);
        }
        
        public function recSync(mode:int, pipe:int):void {
        	var e:MEvent = makeEvent();
        	e.setSync(mode, pipe);
        	pushEvent(e);
        }

        public function recClose():void {
            var e:MEvent = makeEvent();
            e.setClose();
            pushEvent(e);
        }

		public function recPortamento(depth:int, len:int):void {
            var e:MEvent = makeEvent();
            e.setPortamento(depth, len);
            pushEvent(e);
		}
		
		public function recMidiPort(mode:int):void {
			var e:MEvent = makeEvent();
			e.setMidiPort(mode);
			pushEvent(e);
		}
		
		public function recMidiPortRate(rate:int):void {
			var e:MEvent = makeEvent();
			e.setMidiPortRate(rate);
			pushEvent(e);
		}

		public function recPortBase(base:int):void {
			var e:MEvent = makeEvent();
			e.setPortBase(base);
			pushEvent(e);
		}
		
		public function recPoly(voiceCount:int):void {
			var e:MEvent = makeEvent();
			e.setPoly(voiceCount);
			pushEvent(e);
			m_polyFound = true;
		}
		
        public function recHwLfo(w:int, f:int, pmd:int, amd:int, pms:int, ams:int, syn:int):void {
            var e:MEvent = makeEvent();
            e.setHwLfo(w, f, pmd, amd, pms, ams, syn);
            pushEvent(e);
        }		

        public function isEnd():int {
            return m_isEnd;
        }

        public function getRecGlobalTick():uint {
            return m_globalTick;
        }

        public function seekTop():void {
            m_globalTick = 0;
        }

        public function conduct(trackArr:Array):void {
            var ni:int = m_events.length;
            var nj:int = trackArr.length;
            var globalTick:uint = 0;
            var globalSample:uint = 0;
            var spt:Number = calcSpt(DEFAULT_BPM);
            var i:int, j:int;
            var e:MEvent;
            for(i = 0; i < ni; i++) {
                e = m_events[i];
                globalTick += e.getDelta();
                globalSample += e.getDelta() * spt;
                switch(e.getStatus()) {
                case MStatus.TEMPO:
                    spt = calcSpt(e.getTempo());
                    for (j = FIRST_TRACK; j < nj; j++) {
                        trackArr[j].recTempo(globalTick, e.getTempo());
                    }
                    break;
                default:
                    break;
                }
            }
            var maxGlobalTick:int = 0;
            for (j = FIRST_TRACK; j < nj; j++) {
                if (maxGlobalTick < trackArr[j].getRecGlobalTick()) maxGlobalTick = trackArr[j].getRecGlobalTick();
            }
            e = makeEvent();
            e.setClose();
            recGlobal(maxGlobalTick, e);
            globalSample += (maxGlobalTick - globalTick) * spt;

            recRestMSec(3000);
            recEOT();
            globalSample += 3 * 44100;

            m_totalMSec = globalSample*1000/44100;
        }
        // calc number of samples per tick
        private function calcSpt(bpm:Number):Number {
            var tps:Number = bpm * 96.0 / 60.0; // ticks per second (quater note = 96ticks)
            return 44100.0 / tps;              // samples per tick
        }
        // set tempo
        private function playTempo(bpm:Number):void {
            m_bpm = bpm;
            m_spt = calcSpt(bpm);
            //trace("spt:"+m_spt)
        }
        public function getTotalMSec():uint {
            return m_totalMSec;
        }
        public function getTotalTimeStr():String {
            var sec:int = Math.ceil(Number(m_totalMSec) / 1000);
            var smin:String = "0" + int(sec / 60);
            var ssec:String = "0" + (sec % 60);
            return smin.substr(smin.length-2, 2) + ":" + ssec.substr(ssec.length-2, 2);
        }
		
        // 発声数取得
        public function getVoiceCount():int {
            return m_ch.getVoiceCount();
        }
		
        // モノモードへ移行 (再生開始前に行うこと)
        public function usingMono():void {
            m_ch = new MChannel();
        }
		
        // ポリモードへ移行 (再生開始前に行うこと)
        public function usingPoly(maxVoice:int):void {
            m_ch = new MPolyChannel(maxVoice);
        }		
		
		// ポリ命令を１回でも使ったか？
		public function findPoly():Boolean {
			return m_polyFound;
		}
    }
}
