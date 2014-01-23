package com.flmml 
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
		protected var m_vmode_max:int;			// 音量値の最大
		protected var m_vmode_index:int;		// 現在の音量
		protected var m_vmode_rate:Number;		// 最大音量からの減衰レート（０のとき線形、正のときｄＢ）
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
			m_form       = MOscillator.PULSE;
			m_subform    = 0;
			m_voiceId    = 0;
			m_voiceLimit = voiceLimit;
			m_lastVoice  = null;
			m_voiceLen   = m_voices.length;
		}

		public function getVoiceLength():int {
			return m_voiceLen;
		}

		public function getVoiceMod(index:int):MChannel {
			var i:int = index;
			if (i < 0) i = (-1);
			if (i >= m_voiceLen) i = (-1);
			if (i != (-1)) {
				return m_voices[i];
			}
			else {
				return null;
			}
		}

		public function noteOn(noteNo:int,pdif:uint):void {
			var i:int;
			var vo:MChannel = null;
			var vi:int;
			
			// ボイススロットに空きがあるようだ
			if (getVoiceCount() <= m_voiceLimit) {
				for (i = 0; i < m_voiceLen; i++) {
					if (m_voices[i].isPlaying() == false) {
						vo = m_voices[i];
						vi = i;
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
						vi = i;
					}
				}
			}
			// 発音する
			vo.setForm(m_form, m_subform);
			vo.noteOnWidthId(noteNo, m_voiceId++, pdif);
			m_lastVoice = vo;
		}

		public function noteOff(noteNo:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) {
				if (m_voices[i].getNoteNo() == noteNo) {
					m_voices[i].noteOff(noteNo);
				}
			}
		}

		public function setNoteNo(noteNo:int, tie:Boolean = true):void {
			if (m_lastVoice != null && m_lastVoice.isPlaying()) {
				m_lastVoice.setNoteNo(noteNo, tie);
			}
		}

		public function setDetune(detune:int, rate:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setDetune(detune, rate);
		}

		public function setEnvTimeUnit(spt:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvTimeUnit(spt);
		}

		public function setLfoResolution(spt:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLfoResolution(spt);
		}

		public function setMixingVolume(m_vol:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setMixingVolume(m_vol);
		}

		public function setVolMode(max:int, rate:Number, mode:int):void {
			// ノートオン時に適用する
			//暫定
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setVolMode(max, rate, mode);
		}

		public function setVolume(vol:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setVolume(vol);
		}

		public function setPan(pan:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPan(pan);
		}

		public function setPanLegacy(lgPan:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPanLegacy(lgPan);
		}

		public function setForm(form:int, subform:int):void {
			// ノートオン時に適用する
			m_form    = form;
			m_subform = subform;
		}

		public function setSubForm(subform:int):void {
			// ノートオン時に適用する
			m_subform = subform;
		}

		public function setPhaseRMode(mode:int, phase:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPhaseRMode(mode, phase);
		}

		public function setEnvelope(dest:int, lvRd_mode:int, atk_mode:Boolean, initlevel:Number, evPoints:Array):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setEnvelope(dest, lvRd_mode, atk_mode, initlevel, evPoints);
		}

		public function setLFO(target:int, paramA:Array, spt:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFO(target, paramA, spt);
		}

		public function setLFOrestart(target:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLFOrestart(target);
		}

		public function setLPF(swt:int, paramA:Array):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setLPF(swt, paramA);
		}

		public function setFormant(vowel:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setFormant(vowel);
		}

		public function setPWM(pwm:Number, mode:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPWM(pwm, mode);
		}

		public function setOPMHwLfo(data:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setOPMHwLfo(data);
		}

		public function setYControl(m:int, f:int, n:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setYControl(m,f,n);
		}

		public function setPortamento(depth:int, len:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPortamento(depth, len);
		}

		public function setMidiPort(mode:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setMidiPort(mode);
		}

		public function setMidiPortRate(rate:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setMidiPortRate(rate);
		}

		public function setPortBase(portBase:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setPortBase(portBase);
		}

		public function getVoiceCount():int {
			var i:int;
			var c:int = 0;
			for (i = 0; i < m_voiceLen; i++) {
				c += m_voices[i].getVoiceCount();
			}
			return c;
		}

		public function setVoiceLimit(voiceLimit:int):void {
			m_voiceLimit = Math.max(1, Math.min(voiceLimit, m_voiceLen));
		}

		public function setFade(time:Number, range:Number, mode:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setFade(time, range, mode);
		}

		public function allocDelayBuffer(reqbuf:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].allocDelayBuffer(reqbuf);
		}
		public function setDelay(cnt:int, lv:Number):void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setDelay(cnt, lv);
		}

		public function close():void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].close();
		}

		public function setSoundOff():void {
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setSoundOff();
		}

		public function reset():void {
			m_form      = 0;
			m_subform   = 0;
			m_voiceId   = 0;
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].reset();
		}

		public function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) {
				if (m_voices[i].isPlaying()) {
					m_voices[i].getSamples(samples, max, start, delta);
				}
			}
		}

		/*
		 * End Class Definition
		 */
	}

}