package com.flmml {
	import __AS3__.vec.Vector;
	
	import flash.errors.MemoryError;

	public class MTrack {
		public static const TEMPO_TRACK:int = 0;
		public static const FIRST_TRACK:int = 1;
		public static const DEFAULT_BPM:Number = 120.0;
		public static var s_infiniteRepeatF:Boolean = false;
		public static var s_IRRequestLastTrack:int = 0;
		public  var m_signalInterval:int;
		public  var m_IRCheckStrictlyF:Boolean;	//テンポトラックで、先頭以外にも複数ポイントでテンポ指定を行う場合に厳密チェック要求を行う。
		public  var m_IRepeatF:Boolean;
		public  var m_IRepeatPt:int;
		public  var m_IRepeatGt:uint;
		public  var m_IRepeatGtReq:uint;
		public  var m_IRepeatStOct:int;		//無限リピートエントリ時のオクターブ値（デバッグ表示用）
		public  var m_IRepeatEdOct:int;		//無限リピート有効時のトラック終端オクターブ値（デバッグ表示用）
		private var m_bpm:Number;         // beat per minute
		private var m_spt:Number;         // samples per tick
		private var m_ch:IChannel;        // channel (instrument)
		private var m_needle:Number       // delta time
		private var m_gate_rate:Number;   // default gate time rate (max:1.0)
		private var m_gate_ticks1:int;    // gate time 1 (ticks)
		private var m_gate_ticks2:int;    // gate time 2 (ticks)
		private var m_events:Array;       //
		private var m_pointer:int;        // current event no.
		private var m_delta:uint;
		private var m_isEnd:int;
		private var m_globalTick:uint;
		private var m_signalCnt:int;
		private var m_pitchReso:int;
		private var m_totalMSec:uint;
		private var m_noteOnPos:uint;
		private var m_noteOffPos:uint;
		private var m_delayCountReq:int;
		private var m_polyFound:Boolean;
		private var m_chordBegin:uint;
		private var m_chordEnd:uint;
		private var m_chordMode:Boolean;

		public function MTrack() {
			m_isEnd              = 0;
			m_ch                 = new MChannel();
			m_needle             = 0.0;
			m_polyFound          = false;
			playTempo(DEFAULT_BPM);
			recGateRate(1.0/1.0);				//デフォルトはゲート無し。
			recGateTicks1(0);					//デフォルトはゲート無し。
			recGateTicks2(0);					//デフォルトはゲート無し。
			m_events             = new Array();
			m_pointer = 0;
			m_delta = 0;
			m_globalTick = 0;
			m_signalInterval = (int(MML.s_tickUnit))/16;	// (quater note)/4
			m_signalCnt = 0;
			m_pitchReso = MChannel.DEFAULT_P_RESO;
			m_totalMSec = 0;
			m_chordBegin = 0;
			m_chordEnd = 0;
			m_chordMode = false;
			m_IRCheckStrictlyF = false;
			m_IRepeatF  = false;
			m_IRepeatGtReq = 0;
			m_IRepeatPt = -1;
			m_IRepeatGt = 0;
			m_noteOnPos = 0;
			m_noteOffPos = uint.MAX_VALUE;
			m_delayCountReq = 0;
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
			for (var n:Number = Number(start); n < Number(end);) {
				// exec events
				var exec:int = 0;
				var eLen:int = m_events.length;
				var stat:int;
				var tickpos:uint;
				var e:MEvent;
				var delta:Number;
				do {
					exec = 0;
					if (m_pointer < eLen) {
						e = m_events[m_pointer];
						delta = Number(e.getDelta()) * m_spt;
						if (m_needle >= delta) {
							//trace(n+"/mpt:"+m_pointer+"/global:"+(int)(m_globalTick/m_spt)+"/status:"+e.getStatus()+"/delta:"+delta+"-"+e.getDelta()+"/noteNo:"+e.getNoteNo());
							exec = 1;
							stat = e.getStatus();
							tickpos = e.getTick();
							switch(stat) {
							case MStatus.EOT:
								m_isEnd = 1;
								break;
							case MStatus.NOP:
								break;
							case MStatus.TEMPO:
								playTempo(e.getTempo());
								break;
							case MStatus.REST:
								break;
							case MStatus.NOTE_ON:
								m_ch.setEnvTimeUnit(m_spt);
								m_ch.setLfoResolution(m_spt);
								m_noteOnPos = tickpos;
								m_ch.noteOn(e.getNoteNo(), (m_noteOnPos - m_noteOffPos));
								break;
							case MStatus.NOTE_OFF:
								m_ch.setEnvTimeUnit(m_spt);
								m_ch.setLfoResolution(m_spt);
								m_noteOffPos = tickpos;
								m_ch.noteOff(e.getNoteNo());
								break;
							case MStatus.NOTE:
								m_ch.setLfoResolution(m_spt);
								m_ch.setNoteNo(e.getNoteNo());
								break;
							case MStatus.DETUNE:
								var dtrate:int = e.getDetuneRate();
								if ((dtrate >= 10) && (dtrate <= 1000)) m_pitchReso = dtrate;
								m_ch.setDetune(e.getDetune(), e.getDetuneRate());
								break;
							case MStatus.MIXING_VOL:
								m_ch.setMixingVolume(e.getMixingVolume());
								break;
							case MStatus.VOL_MODE:
								m_ch.setVolMode(e.getVolModeMAX(), e.getVolModeRate(), e.getVolModeVzMD());
								break;
							case MStatus.VOLUME:
								m_ch.setVolume(e.getVolume());
								break;
							case MStatus.EXPRESSION:
								m_ch.setExpression(e.getExpression());
								break;
							case MStatus.PAN:
								m_ch.setPan(e.getPan());
								break;
							case MStatus.PAN_LEGACY:
								m_ch.setPanLegacy(e.getPanLegacy());
								break;
							case MStatus.FORM:
								m_ch.setForm(e.getForm(), e.getFormSub());
								break;
							case MStatus.SUBFORM:
								m_ch.setSubForm(e.getSubForm());
								break;
							case MStatus.PHASE_R_MODE:
								m_ch.setPhaseRMode(e.getPhaseRMode(), e.getPhaseRModePH());
								break;
							case MStatus.ENVELOPE:
								var evAttackM:Boolean = (e.getEnvelopeRattackM() == 1) ? true : false;
								m_ch.setEnvelope(e.getEnvelopePdest(), e.getEnvelopeRlvRoundM(), evAttackM, e.getEnvelopeLinitLv(), e.getEnvelopeApoints());
								break;
							case MStatus.LFO:
								m_ch.setLFO(e.getLFOtarget(), e.getLFOparams(), m_spt);
								break;
							case MStatus.LFO_RESTART:
								m_ch.setLFOrestart(e.getLFOrestartTarget());
								break;
							case MStatus.LPF:
								m_ch.setLPF(e.getLPFswt(), e.getLPFparams());
								break;
							case MStatus.FORMANT:
								m_ch.setFormant(e.getVowel());
								break;
							case MStatus.PWM:
								m_ch.setPWM(e.getPWM(), e.getPWMmode());
								break;
							case MStatus.OPM_HW_LFO:
								m_ch.setOPMHwLfo(e.getOPMHwLfoData());
								break;
							case MStatus.Y_CONTROL:
								m_ch.setYControl(e.getYCtrlMod(), e.getYCtrlFunc(), e.getYCtrlParam());
								break;
							case MStatus.PORTAMENTO:
								m_ch.setPortamento(e.getPorDepth() * m_pitchReso, e.getPorLen() * m_spt);
								break;
							case MStatus.MIDIPORT:
								m_ch.setMidiPort(e.getMidiPort());
								break;
							case MStatus.MIDIPORTRATE:
								var rate:Number = e.getMidiPortRate();
								m_ch.setMidiPortRate((8 - (rate * 7.99 / 128)) / rate);
								break;
							case MStatus.BASENOTE:
								m_ch.setPortBase(e.getPortBase() * m_pitchReso);
								break;
							case MStatus.POLY:
								m_ch.setVoiceLimit(e.getVoiceCount());
								break;
							case MStatus.EFF_FADE:
								m_ch.setFade(e.getFadeTime(), Number(e.getFadeRange()), e.getFadeMode());
								break;
							case MStatus.EFF_DELAY:
								m_ch.setDelay(e.getDelayCount(), e.getDelayLevel());
								break;
							case MStatus.REPEAT_ENTRY:
								//conduct()後にTEMPOと同系列で処理。シーケンス中はＮＯＰ。
								break;
							case MStatus.JUMP_TO_REPT:
								//当コマンドはconduct()後に生成される。
								//ジャンプ処理そのものは下記if節で行う。通常のm_pointerインクリメントと排他制御するため。
								if (tickpos == m_noteOffPos) m_noteOffPos = m_IRepeatGt;		//波形生成の位相リセット機能のモード２対策
								break;
							case MStatus.CLOSE:
								m_ch.close();
								break;
							case MStatus.SOUND_OFF:
								m_ch.setSoundOff();
								break;
							case MStatus.RESET_ALL:
								m_ch.reset();
								break;
							default:
								break;
							}
							m_needle -= delta;
							if (stat != MStatus.JUMP_TO_REPT) {
								m_pointer++;
							}
							else {
								m_pointer = m_IRepeatPt;
								m_globalTick = m_IRepeatGt;
							}
						}
					}
				} while(exec);

				// create a short wave
				var dn:Number;
				if (m_pointer < eLen) {
					e = m_events[m_pointer];
					delta = Number(e.getDelta()) * m_spt;
					dn = Math.ceil(delta - m_needle);
					if ((n + dn) >= Number(end)) dn = Number(end) - n;
					m_needle += dn;
					//trace("n:" + n + "/dn:" + dn);
					if (signal == null) m_ch.getSamples(samples, end, int(n), int(dn));
					n += dn;
				}
				else {
					break;
				}

				// periodic signal
				if (signal != null) {
					m_signalCnt += dn;
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

		public function seek(delta:uint):void {
			m_delta += delta;
			m_globalTick += delta;
			m_chordEnd = Math.max(m_chordEnd, m_globalTick);
		}
		
		public function seekChordStart():void {
			m_globalTick = m_chordBegin;
		}

		public function recDelta(e:MEvent):void {
			e.setDelta(int(m_delta));
			m_delta = 0;
		}

		public function recNote(noteNo:int, len:int, keyon:int = 1, keyoff:int = 1):void {
			var e0:MEvent = makeEvent();
			if (keyon != 0) {
				e0.setNoteOn(noteNo);
			}
			else {
				e0.setNote(noteNo);
			}
			pushEvent(e0);
			if (keyoff != 0) {
				var gate:int;
				if (m_gate_ticks1 == 0) {
					gate = int(Math.round(Number(len) * m_gate_rate)) - m_gate_ticks2;
				}
				else {
					gate = m_gate_ticks1 - m_gate_ticks2;
				}
				if (gate < 1) gate = 1;
				if (gate > len) gate = len;
				seek(uint(gate));
				recNoteOff(noteNo);
				seek(uint(len - gate));
				if (m_chordMode) {
					seekChordStart();
				}
			}
			else {
				seek(uint(len));
			}
		}

		public function recNoteOff(noteNo:int):void {
			var e:MEvent = makeEvent();
			e.setNoteOff(noteNo);
			pushEvent(e);
		}

		public function recRest(len:int):void {
			seek(uint(len));
			if (m_chordMode) {
				m_chordBegin += uint(len);
			}
			// 休符セット後のm_delta値で、意図的にイベントの区切りをつける。（無限リピートにおけるエントリ対策）
			var e:MEvent = makeEvent();
			e.setREST();
			pushEvent(e);
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
			var len:int = int(Number(msec) * 44100.0 / (m_spt * 1000.0));
			seek(uint(len));
		}

		// 挿入先が同時間の場合、前に挿入する。トラック毎の無限リピートエントリマーキング用
		protected function recGlobalRP(globalTick:uint, e:MEvent):void {
			var n:int = m_events.length;
			var preGlobalTick:uint = 0;
			for (var i:int = 0; i < n; i++) {
				var en:MEvent = m_events[i];
				var nextTick:uint = preGlobalTick + uint(en.getDelta());
				if (nextTick > globalTick || (nextTick == globalTick && en.getStatus() != MStatus.NOTE_OFF)) {
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

		// 挿入先が同時間の場合、前に挿入する。トラック毎のテンポコマンド用。
		protected function recGlobal(globalTick:uint, e:MEvent):void {
			var n:int = m_events.length;
			var preGlobalTick:uint = 0;
			for (var i:int = 0; i < n; i++) {
				var en:MEvent = m_events[i];
				var nextTick:uint = preGlobalTick + uint(en.getDelta());
				var s:int = en.getStatus();
				if ( nextTick > globalTick || (nextTick == globalTick && s != MStatus.NOTE_OFF && s != MStatus.REPEAT_ENTRY && s != MStatus.TEMPO) ) {
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
			for (var i:int = 0; i < n; i++) {
				var en:MEvent = m_events[i];
				var nextTick:uint = preGlobalTick + uint(en.getDelta());
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
			e.setDelta(int(m_delta));
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

		public function recRepeatEntry(globalTick:uint):void {
			var e:MEvent = new MEvent(globalTick); // makeEvent()は使用してはならない
			e.setRepeatEntry();
			recGlobalRP(globalTick, e);
			/*
			 * 無限リピートエントリは、テンポ同様、テンポ専用の内部トラックに登録し、conduct()処理後に精査する。
			 */
		}

		public function recJumpToRept():void {
			var e:MEvent = makeEvent();
			e.setJumpToRept();
			pushEvent(e);
			/*
			 * 無限リピートのジャンプ先はconduct()処理後、MMLクラスからm_IRepeatPtにセットされる。
			 */
		}

		public function recEOT():void {
			var e:MEvent = makeEvent();
			e.setEOT();
			pushEvent(e);
		}

		public function recNOP():void {
			var e:MEvent = makeEvent();
			e.setNOP();
			pushEvent(e);
		}

		public function recNOPforIRepeat(globalTick:uint):void {
			var e:MEvent = new MEvent(globalTick);			// makeEvent()は使用してはならない
			e.setNOP();
			recGlobalRP(globalTick, e);
			/*
			 * NOPでゲートタイム等のdeltaを吸収し、リピートエントリポイントのdeltaが０になるようにする。
			 */
		}

		public function recGateRate(gate:Number):void {
			m_gate_rate = gate;
		}

		public function recGateTicks1(gate1:int):void {
			if (gate1 < 0) gate1 = 0;
			m_gate_ticks1 = gate1;
		}

		public function recGateTicks2(gate2:int):void {
			if (gate2 < 0) gate2 = 0;
			m_gate_ticks2 = gate2;
		}

		public function recDetune(d:int, r:int):void {
			var e:MEvent = makeEvent();
			e.setDetune(d,r);
			pushEvent(e);
		}

		public function recMixingVolume(m_vol:Number):void {
			var e:MEvent = makeEvent();
			e.setMixingVolume(m_vol);
			pushEvent(e);
		}

		public function recVolMode(max:int, rate:Number, mode:int): void {
			var e:MEvent = makeEvent();
			e.setVolMode(max, rate, mode);
			pushEvent(e);
		}

		public function recVolume(vol:int):void {
			var e:MEvent = makeEvent();
			e.setVolume(vol);
			pushEvent(e);
		}

		public function recExpression(ex:int):void {
			var e:MEvent = makeEvent();
			e.setExpression(ex);
			pushEvent(e);
		}

		public function recPan(pan:Number):void {
			var e:MEvent = makeEvent();
			e.setPan(pan);
			pushEvent(e);
		}

		public function recPanLegacy(lgPan:int):void {
			var e:MEvent = makeEvent();
			e.setPanLegacy(lgPan);
			pushEvent(e);
		}

		public function recForm(form:int, sub:int):void {
			var e:MEvent = makeEvent();
			e.setForm(form, sub);
			pushEvent(e);
		}

		public function recSubForm(sub:int):void {
			var e:MEvent = makeEvent();
			e.setSubForm(sub);
			pushEvent(e);
		}

		public function recPhaseRMode(m:int, ph:Number):void {
			var e:MEvent = makeEvent();
			e.setPhaseRMode(m, ph);
			pushEvent(e);
		}

		public function recEnvelope(evDest:int, LvRdMode:int, atkMode:Boolean, initLv:Number, evPoints:Array):void {
			var e:MEvent = makeEvent();
			var i:int;
			var pt:int;
			var pVal:int;
			var rVal:int;
			var lVal:Number;
			pVal = evDest;
			rVal = (((atkMode) ? 1 : 0) << 8) | (LvRdMode & 0x0ff);
			lVal = initLv;
			e.setEnvelope(pVal, rVal, lVal, evPoints);
			pushEvent(e);
		}

		public function recDampOffEnvelope():void {
			var e:MEvent = makeEvent();
			e.setSoundOff();
			pushEvent(e);
		}

		public function recLFO(target:int, paramA:Array):void {
			var e:MEvent = makeEvent();
			e.setLFO(target, paramA);
			pushEvent(e);
		}

		public function recLFOrestart(target:int):void {
			var e:MEvent = makeEvent();
			e.setLFOrestart(target);
			pushEvent(e);
		}

		public function recLPF(swt:int, paramA:Array):void {
			var e:MEvent = makeEvent();
			e.setLPF(swt, paramA);
			pushEvent(e);
		}

		public function recFormant(vowel:int):void {
			var e:MEvent = makeEvent();
			e.setFormant(vowel);
			pushEvent(e);
		}

		public function recPWM(pwm:Number, mode:int):void {
			var e:MEvent = makeEvent();
			e.setPWM(pwm, mode);
			pushEvent(e);
		}

		public function recOPMHwLfo(wf:int, freq:int, pmd:int, amd:int, pms:int, ams:int, syn:int):void {
			var e:MEvent = makeEvent();
			var params:int;
			params = ((wf & 3) << 28) | ((freq & 0x0ff) << 20) | ((pmd & 0x7f) << 13) | ((amd & 0x7f) << 6) | ((pms & 7) << 3) | ((ams & 3) << 1) | (syn & 1);
			e.setOPMHwLfo(params);
			pushEvent(e);
		}

		public function recYControl(m:int, f:int, n:Number):void {
			var e:MEvent = makeEvent();
			e.setYControl(m,f,n);
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

		public function recFade(time:Number, range:int, mode:int):void {
			var e:MEvent = makeEvent();
			e.setFade(time, range, mode);
			pushEvent(e);
		}

		public function recDelay(cnt:int, lv:Number):void {
			var e:MEvent = makeEvent();
			e.setDelay(cnt, lv);
			pushEvent(e);
		}

		public function recClose():void {
			var e:MEvent = makeEvent();
			e.setClose();
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

		//conduct()は、テンポトラックのインスタンスでのみ実行する
		public function conduct(trackArr:Vector.<MTrack>):void {
			var ni:int = m_events.length;
			var nj:int = trackArr.length;
			var globalTick:uint = 0;
			var globalSample:Number = 0.0;
			var spt:Number = calcSpt(DEFAULT_BPM);
			var i:int, j:int;
			var e:MEvent;
			for(i = 0; i < ni; i++) {
				e = m_events[i];
				globalTick += uint(e.getDelta());
				globalSample += (Number(e.getDelta()) * spt);
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
			var maxGlobalTick:uint = 0;
			if (m_IRepeatF == false) {
				for (j = FIRST_TRACK; j < nj; j++) {
					if (maxGlobalTick < trackArr[j].getRecGlobalTick()) {
						maxGlobalTick = trackArr[j].getRecGlobalTick();
					}
				}
			}
			else {
				maxGlobalTick = trackArr[s_IRRequestLastTrack].getRecGlobalTick();
			}

			var catchupGlobalTick:uint;
			catchupGlobalTick = (maxGlobalTick >= globalTick) ? globalTick : maxGlobalTick;		//必ず(maxGlobalTick >= globalTick)であるはずだが念のため
			m_delta = maxGlobalTick - catchupGlobalTick;
			m_globalTick = maxGlobalTick;

			e = makeEvent();
			e.setNOP();
			recGlobal(maxGlobalTick, e);
			globalSample += (Number(maxGlobalTick - globalTick) * spt);

			var totalMSecond:Number;
			totalMSecond = (globalSample * 1000.0) / 44100.0;
			if (totalMSecond < Number(uint.MAX_VALUE)) {
				m_totalMSec = uint(totalMSecond);
			}
			else {
				m_totalMSec = uint.MAX_VALUE;
			}

			// MMLクラスのpost processにて、各トラックの終端処理を行う
		}

		// calc number of samples per tick
		private function calcSpt(bpm:Number):Number {
			var tps:Number = (bpm * (MML.s_tickUnit / 4.0)) / 60.0; // ticks per second (quater note = (MML.s_tickUnit/4.0)ticks)
			return 44100.0 / tps;              // samples per tick
		}

		// set tempo
		private function playTempo(bpm:Number):void {
			var n:Number;
			m_bpm = bpm;
			m_spt = calcSpt(bpm);
			//trace("spt:"+m_spt)
		}

		public function getTotalMSec():uint {
			return m_totalMSec;
		}

		public function addTotalMSec(msec:uint):void {
			m_totalMSec += msec;
		}

		public function getTotalTimeStr():String {
			if (s_infiniteRepeatF == true) {
				return "infinity";
			}
			else {
				var sec:Number = Math.ceil(Number(m_totalMSec) / 1000.0);
				if (sec >= 86400.0) return "over24h";
				var shour:String = "0" + String(int(sec / 3600.0));
				var smin:String  = "0" + String(int((sec / 60.0) % 60.0));
				var ssec:String  = "0" + String(int(sec % 60.0));
				return shour.substr(shour.length - 2, 2) + ":" + smin.substr(smin.length - 2, 2) + ":" + ssec.substr(ssec.length - 2, 2);
			}
		}

		//作成済みイベントのdelta累計を報告
		public function reportTotalTicks():uint {
			var len:int;
			var totalticks:uint;
			len = m_events.length;
			totalticks = 0;
			for (var i:int = 0; i < len; i++) {
				totalticks += uint((MEvent)(m_events[i]).getDelta());
			}
			return totalticks;
		}

		//無限リピートポインタ取得
		public function getIRepeatPointer(globalticks:uint):int {
			var len:int;
			var reptentryPointer:int = -1;
			var nowGt:uint;
			var getf:Boolean;
			var e:MEvent;

			len = m_events.length;
			getf = false;

			for (var i:int = 0; i < len; i++) {
				e = m_events[i];
				nowGt = e.getTick();
				if (nowGt == globalticks && e.getStatus() == MStatus.REPEAT_ENTRY) {
					reptentryPointer = i;
					getf = true;
				}
				else if (nowGt > globalticks) {
					//ジャンプ先取得できず。
					reptentryPointer = -1;
					break;
				}
				if (getf == true) break;
			}

			return reptentryPointer;
		}

		// ディレイエフェクトの有効化
		public function enableDelayEffectBuffer(reqbuf:int):void {
			if (reqbuf < MML.DEF_MIN_DELAY_CT) {
				m_delayCountReq = 0;
			}
			else if (reqbuf > MML.DEF_MAX_DELAY_CT) {
				m_delayCountReq = 0;
			}
			else {
				m_delayCountReq = reqbuf;
			}
			m_ch.allocDelayBuffer(reqbuf);
		}

		// 発声数取得
		public function getVoiceCount():int {
			return m_ch.getVoiceCount();
		}
		
		// モノモードへ移行 (再生開始前に行うこと)
		public function usingMono():void {
			m_ch = new MChannel();
			m_ch.allocDelayBuffer(m_delayCountReq);
		}
		
		// ポリモードへ移行 (再生開始前に行うこと)
		public function usingPoly(maxVoice:int):void {
			m_ch = new MPolyChannel(maxVoice);
			m_ch.allocDelayBuffer(m_delayCountReq);
		}
		
		// ポリ命令を１回でも使ったか？
		public function findPoly():Boolean {
			return m_polyFound;
		}
	}
}
