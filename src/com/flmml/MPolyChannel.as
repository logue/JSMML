package com.flmml 
{
	import __AS3__.vec.Vector;
	
	public class MPolyChannel implements IChannel
	{
		protected var m_voices:Vector.<MChannel>;		// ポリフォニック音声トラック
		protected var m_voiceLen:int;					// m_voices確保個数
		protected var m_voiceLimit:int;					// m_voices確保個数のうち、使用する個数
		protected var m_voiceId:int;					// ノートオンの都度更新するID。最も古い m_voices を特定するため。
		protected var m_lastVoice:MChannel;				// 最後にノートオンした m_voicesトラック。
		
		protected var m_nowSeqId:int;
		protected var m_mstSeqId:Vector.<int>;			// マスターシーケンスID
		protected var m_voiSeqId:Vector.<Vector.<int>>;	// m_voicesごとのシーケンスID
		// 予約コマンドコード
		protected static const C_setDetune:int			= 0;
		protected static const C_setEnvTimeUnit:int		= 1;
		protected static const C_setLfoResolution:int	= 2;
		protected static const C_setMixingVolume:int	= 3;
		protected static const C_setVolMode:int			= 4;
		protected static const C_setVolume:int			= 5;
		protected static const C_setPan:int				= 6;
		protected static const C_setPanLegacy:int		= 7;
		protected static const C_setForm:int			= 8;
		protected static const C_setSubForm:int			= 9;
		protected static const C_setPhaseRMode:int		= 10;
		protected static const C_setEnvelope:int		= 11;
		protected static const C_setLFO:int				= 12;
		protected static const C_setLFOrestart:int		= 13;
		protected static const C_setLPF:int				= 14;
		protected static const C_setFormant:int			= 15;
		protected static const C_setPWM:int				= 16;
		protected static const C_setOPMHwLfo:int		= 17;
		protected static const C_setPortamento:int		= 18;
		protected static const C_setMidiPort:int		= 19;
		protected static const C_setMidiPortRate:int	= 20;
		protected static const C_setPortBase:int		= 21;
		protected static const C_MAX:int				= 22;
		
		public function MPolyChannel(voiceLimit:int) {
			var i:int, j:int;
			m_voices = new Vector.<MChannel>(voiceLimit);
			m_voiSeqId = new Vector.<Vector.<int>>(voiceLimit);
			for (i = 0; i < m_voices.length; i++) {
				m_voices[i] = new MChannel();
				m_voiSeqId[i] = new Vector.<int>(C_MAX);
				for (j = 0; j < C_MAX; j++) { m_voiSeqId[i][j] = 0; }
			}
			m_mstSeqId = new Vector.<int>(C_MAX);
			for (i = 0; i < C_MAX; i++) { m_mstSeqId[i] = 0; }
			
			m_nowSeqId   = 0;
			
			m_voiceId    = 0;
			m_voiceLimit = voiceLimit;
			m_lastVoice  = null;
			m_voiceLen   = m_voices.length;
		}

		public function noteOn(noteNo:int,pdif:uint):void {
			var i:int;
			var vo:MChannel = null;
			var vi:int;
			var oldID:int;
			
			// 無音スロットをつかむ
			if (getVoiceCount() <= m_voiceLimit) {
				for (i = 0; i < m_voiceLen; i++) {
					if (m_voices[i].isPlaying() == false) {
						vo = m_voices[i];
						vi = i;
						break;
					}
				}
			}
			// 無音スロットがつかめなかった場合、一番古い発音中スロットをつかむ
			if (vo == null) {
				oldID = ((m_voiceId + 1) % m_voiceLen);		// 現在の番号に１加算し、総数の剰余をとったものが最も古い
				for (i = 0; i < m_voiceLen; i++) {
					if (oldID == m_voices[i].getId()) {
						vo = m_voices[i];
						vi = i;
					}
				}
				if (vo == null) {
					// fail-safe
					vo = m_voices[0];
					vi = 0;
				}
			}
			
			// 予約コマンドを確認して実行
			if (m_voiSeqId[vi][C_setDetune] != m_mstSeqId[C_setDetune]) {
				vo.setDetune(m_setDetune_a, m_setDetune_b);
				m_voiSeqId[vi][C_setDetune] = m_mstSeqId[C_setDetune];
			}
			if (m_voiSeqId[vi][C_setEnvTimeUnit] != m_mstSeqId[C_setEnvTimeUnit]) {
				vo.setEnvTimeUnit(m_setEnvTimeUnit_a);
				m_voiSeqId[vi][C_setEnvTimeUnit] = m_mstSeqId[C_setEnvTimeUnit];
			}
			if (m_voiSeqId[vi][C_setLfoResolution] != m_mstSeqId[C_setLfoResolution]) {
				vo.setLfoResolution(m_setLfoResolution_a);
				m_voiSeqId[vi][C_setLfoResolution] = m_mstSeqId[C_setLfoResolution];
			}
			if (m_voiSeqId[vi][C_setMixingVolume] != m_mstSeqId[C_setMixingVolume]) {
				vo.setMixingVolume(m_setMixingVolume_a);
				m_voiSeqId[vi][C_setMixingVolume] = m_mstSeqId[C_setMixingVolume];
			}
			if (m_voiSeqId[vi][C_setVolMode] != m_mstSeqId[C_setVolMode]) {
				vo.setVolMode(m_setVolMode_a, m_setVolMode_b, m_setVolMode_c);
				m_voiSeqId[vi][C_setVolMode] = m_mstSeqId[C_setVolMode];
			}
			if (m_voiSeqId[vi][C_setVolume] != m_mstSeqId[C_setVolume]) {
				vo.setVolume(m_setVolume_a);
				m_voiSeqId[vi][C_setVolume] = m_mstSeqId[C_setVolume];
			}
			if (m_voiSeqId[vi][C_setPan] != m_mstSeqId[C_setPan]) {
				vo.setPan(m_setPan_a);
				m_voiSeqId[vi][C_setPan] = m_mstSeqId[C_setPan];
			}
			if (m_voiSeqId[vi][C_setPanLegacy] != m_mstSeqId[C_setPanLegacy]) {
				vo.setPanLegacy(m_setPanLegacy_a);
				m_voiSeqId[vi][C_setPanLegacy] = m_mstSeqId[C_setPanLegacy];
			}
			if (m_voiSeqId[vi][C_setForm] != m_mstSeqId[C_setForm]) {
				vo.setForm(m_setForm_a, m_setForm_b);
				m_voiSeqId[vi][C_setForm] = m_mstSeqId[C_setForm];
			}
			if (m_voiSeqId[vi][C_setSubForm] != m_mstSeqId[C_setSubForm]) {
				vo.setSubForm(m_setSubForm_a);
				m_voiSeqId[vi][C_setSubForm] = m_mstSeqId[C_setSubForm];
			}
			if (m_voiSeqId[vi][C_setPhaseRMode] != m_mstSeqId[C_setPhaseRMode]) {
				vo.setPhaseRMode(m_setPhaseRMode_a, m_setPhaseRMode_b);
				m_voiSeqId[vi][C_setPhaseRMode] = m_mstSeqId[C_setPhaseRMode];
			}
			if (m_voiSeqId[vi][C_setEnvelope] != m_mstSeqId[C_setEnvelope]) {
				vo.setEnvelope(m_setEnvelope_a, m_setEnvelope_b, m_setEnvelope_c, m_setEnvelope_d, m_setEnvelope_e);
				m_voiSeqId[vi][C_setEnvelope] = m_mstSeqId[C_setEnvelope];
			}
			if (m_voiSeqId[vi][C_setLFO] != m_mstSeqId[C_setLFO]) {
				vo.setLFO(m_setLFO_a, m_setLFO_b, m_setLFO_c);
				m_voiSeqId[vi][C_setLFO] = m_mstSeqId[C_setLFO];
			}
			if (m_voiSeqId[vi][C_setLFOrestart] != m_mstSeqId[C_setLFOrestart]) {
				vo.setLFOrestart(m_setLFO_a);
				m_voiSeqId[vi][C_setLFOrestart] = m_mstSeqId[C_setLFOrestart];
			}
			if (m_voiSeqId[vi][C_setLPF] != m_mstSeqId[C_setLPF]) {
				vo.setLPF(m_setLPF_a, m_setLPF_b);
				m_voiSeqId[vi][C_setLPF] = m_mstSeqId[C_setLPF];
			}
			if (m_voiSeqId[vi][C_setFormant] != m_mstSeqId[C_setFormant]) {
				vo.setFormant(m_setFormant_a);
				m_voiSeqId[vi][C_setFormant] = m_mstSeqId[C_setFormant];
			}
			if (m_voiSeqId[vi][C_setPWM] != m_mstSeqId[C_setPWM]) {
				vo.setPWM(m_setPWM_a, m_setPWM_b);
				m_voiSeqId[vi][C_setPWM] = m_mstSeqId[C_setPWM];
			}
			if (m_voiSeqId[vi][C_setOPMHwLfo] != m_mstSeqId[C_setOPMHwLfo]) {
				vo.setOPMHwLfo(m_setOPMHwLfo_a);
				m_voiSeqId[vi][C_setOPMHwLfo] = m_mstSeqId[C_setOPMHwLfo];
			}
			if (m_voiSeqId[vi][C_setPortamento] != m_mstSeqId[C_setPortamento]) {
				vo.setPortamento(m_setPortamento_a, m_setPortamento_b);
				m_voiSeqId[vi][C_setPortamento] = m_mstSeqId[C_setPortamento];
				//一度受け取ったらリセットすることで不本意な多重実行を防止
				m_setPortamento_a = 0.0;
				m_setPortamento_b = 1.0;
			}
			if (m_voiSeqId[vi][C_setMidiPort] != m_mstSeqId[C_setMidiPort]) {
				vo.setMidiPort(m_setMidiPort_a);
				m_voiSeqId[vi][C_setMidiPort] = m_mstSeqId[C_setMidiPort];
			}
			if (m_voiSeqId[vi][C_setMidiPortRate] != m_mstSeqId[C_setMidiPortRate]) {
				vo.setMidiPortRate(m_setMidiPortRate_a);
				m_voiSeqId[vi][C_setMidiPortRate] = m_mstSeqId[C_setMidiPortRate];
			}
			if (m_voiSeqId[vi][C_setPortBase] != m_mstSeqId[C_setPortBase]) {
				vo.setPortBase(m_setPortBase_a);
				m_voiSeqId[vi][C_setPortBase] = m_mstSeqId[C_setPortBase];
			}
			
			// 発音する
			vo.noteOnWidthId(noteNo, m_voiceId, pdif);
			
			// 次回への準備
			m_voiceId = ((m_voiceId + 1) % m_voiceLen);
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

		protected var m_setDetune_a:Number;
		protected var m_setDetune_b:int;
		public function setDetune(detune:Number, rate:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setDetune] = m_nowSeqId;
			m_setDetune_a = detune;
			m_setDetune_b = rate;
		}

		protected var m_setEnvTimeUnit_a:Number;
		public function setEnvTimeUnit(spt:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setEnvTimeUnit] = m_nowSeqId;
			m_setEnvTimeUnit_a = spt;
		}

		protected var m_setLfoResolution_a:Number;
		public function setLfoResolution(spt:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setLfoResolution] = m_nowSeqId;
			m_setLfoResolution_a = spt;
		}

		protected var m_setMixingVolume_a:Number;
		public function setMixingVolume(m_vol:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setMixingVolume] = m_nowSeqId;
			m_setMixingVolume_a = m_vol;
		}

		protected var m_setVolMode_a:int;
		protected var m_setVolMode_b:Number;
		protected var m_setVolMode_c:int;
		public function setVolMode(max:int, rate:Number, mode:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setVolMode] = m_nowSeqId;
			m_setVolMode_a = max;
			m_setVolMode_b = rate;
			m_setVolMode_c = mode;
		}

		protected var m_setVolume_a:Number;
		public function setVolume(vol:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setVolume] = m_nowSeqId;
			m_setVolume_a = vol;
		}

		protected var m_setPan_a:Number;
		public function setPan(pan:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPan] = m_nowSeqId;
			m_setPan_a = pan;
		}

		protected var m_setPanLegacy_a:int;
		public function setPanLegacy(lgPan:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPanLegacy] = m_nowSeqId;
			m_setPanLegacy_a = lgPan;
		}

		protected var m_setForm_a:int;
		protected var m_setForm_b:int;
		public function setForm(form:int, subform:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setForm] = m_nowSeqId;
			m_setForm_a = form;
			m_setForm_b = subform;
		}

		protected var m_setSubForm_a:int;
		public function setSubForm(subform:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setSubForm] = m_nowSeqId;
			m_setSubForm_a = subform;
		}

		protected var m_setPhaseRMode_a:int;
		protected var m_setPhaseRMode_b:Number;
		public function setPhaseRMode(mode:int, phase:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPhaseRMode] = m_nowSeqId;
			m_setPhaseRMode_a = mode;
			m_setPhaseRMode_b = phase;
		}

		protected var m_setEnvelope_a:int;
		protected var m_setEnvelope_b:int;
		protected var m_setEnvelope_c:Boolean;
		protected var m_setEnvelope_d:Number;
		protected var m_setEnvelope_e:Array;
		public function setEnvelope(dest:int, lvRd_mode:int, atk_mode:Boolean, initlevel:Number, evPoints:Array):void {
			m_nowSeqId++;
			m_mstSeqId[C_setEnvelope] = m_nowSeqId;
			m_setEnvelope_a = dest;
			m_setEnvelope_b = lvRd_mode;
			m_setEnvelope_c = atk_mode;
			m_setEnvelope_d = initlevel;
			m_setEnvelope_e = evPoints;
		}

		protected var m_setLFO_a:int;
		protected var m_setLFO_b:Array;
		protected var m_setLFO_c:Number;
		public function setLFO(target:int, paramA:Array, spt:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setLFO] = m_nowSeqId;
			m_setLFO_a = target;
			m_setLFO_b = paramA;
			m_setLFO_c = spt;
		}

		protected var m_setLFOrestart_a:int;
		public function setLFOrestart(target:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setLFOrestart] = m_nowSeqId;
			m_setLFOrestart_a = target;
		}

		protected var m_setLPF_a:int;
		protected var m_setLPF_b:Array;
		public function setLPF(swt:int, paramA:Array):void {
			m_nowSeqId++;
			m_mstSeqId[C_setLPF] = m_nowSeqId;
			m_setLPF_a = swt;
			m_setLPF_b = paramA;
		}

		protected var m_setFormant_a:int;
		public function setFormant(vowel:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setFormant] = m_nowSeqId;
			m_setFormant_a = vowel;
		}

		protected var m_setPWM_a:Number;
		protected var m_setPWM_b:int;
		public function setPWM(pwm:Number, mode:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPWM] = m_nowSeqId;
			m_setPWM_a = pwm;
			m_setPWM_b = mode;
		}

		protected var m_setOPMHwLfo_a:int;
		public function setOPMHwLfo(data:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setOPMHwLfo] = m_nowSeqId;
			m_setOPMHwLfo_a = data;
		}

		public function setYControl(m:int, f:int, n:Number):void {
			// 全ての m_voices[] に即時反映
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setYControl(m,f,n);
		}

		protected var m_setPortamento_a:Number;
		protected var m_setPortamento_b:Number;
		public function setPortamento(depth:Number, len:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPortamento] = m_nowSeqId;
			m_setPortamento_a = depth;
			m_setPortamento_b = len;
		}

		protected var m_setMidiPort_a:int;
		public function setMidiPort(mode:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setMidiPort] = m_nowSeqId;
			m_setMidiPort_a = mode;
		}

		protected var m_setMidiPortRate_a:int;
		public function setMidiPortRate(rate:int):void {
			m_nowSeqId++;
			m_mstSeqId[C_setMidiPortRate] = m_nowSeqId;
			m_setMidiPortRate_a = rate;
		}

		protected var m_setPortBase_a:Number;
		public function setPortBase(portBase:Number):void {
			m_nowSeqId++;
			m_mstSeqId[C_setPortBase] = m_nowSeqId;
			m_setPortBase_a = portBase;
		}

		public function setVoiceLimit(voiceLimit:int):void {
			m_voiceLimit = Math.max(1, Math.min(voiceLimit, m_voiceLen));
		}

		public function setFade(time:Number, range:Number, mode:int):void {
			// 全ての m_voices[] に即時反映
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setFade(time, range, mode);
		}

		public function allocDelayBuffer(reqbuf:int):void {
			// 全ての m_voices[] に即時反映
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].allocDelayBuffer(reqbuf);
		}
		public function setDelay(cnt:int, lv:Number):void {
			// 全ての m_voices[] に即時反映
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].setDelay(cnt, lv);
		}

		public function close():void {
			// 全ての m_voices[] に即時反映
			for (var i:int = 0; i < m_voiceLen; i++) m_voices[i].close();
		}

		public function setSoundOff():void {
			// @z は最後の発音トラック対し発行する
			if (m_lastVoice != null && m_lastVoice.isPlaying()) {
				m_lastVoice.setSoundOff();
			}
		}

		public function reset():void {
			var i:int, j:int;
			for (i = 0; i < m_voices.length; i++) {
				m_mstSeqId[i] = 0;
				for (j = 0; j < C_MAX; j++) { m_voiSeqId[i][j] = 0; }
			}
			m_nowSeqId = 0;
			m_voiceId = 0;
			// 全ての m_voices[] に即時反映
			for (i = 0; i < m_voiceLen; i++) m_voices[i].reset();
		}

		public function getVoiceCount():int {
			var i:int;
			var c:int = 0;
			for (i = 0; i < m_voiceLen; i++) {
				c += m_voices[i].getVoiceCount();
			}
			return c;
		}

		public function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void {
			for (var i:int = 0; i < m_voiceLen; i++) {
				if (m_voices[i].isPlaying()) {
					m_voices[i].getSamples(samples, max, start, delta);
				}
			}
		}
	}

}