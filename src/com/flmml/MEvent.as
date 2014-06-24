package com.flmml {
	import mx.controls.videoClasses.CuePointManager;

	public class MEvent {
		private var m_delta:int;
		private var m_status:int;
		private var m_data0:int;
		private var m_data1:int;
		private var m_dataN:Number;
		private var m_dataX:Array;
		private var m_tick:uint;

		public function MEvent(tick:uint) {
			set(MStatus.NOP, 0, 0, 0.0, null);
			setTick(tick);
		}

		public function set(status:int, data0:int, data1:int, dataN:Number, dataX:Array):void {
			m_status = status;
			m_data0  = data0;
			m_data1  = data1;
			m_dataN  = dataN;
			m_dataX  = dataX;
		}

		public function setDelta(delta:int):void {
			m_delta = delta;
		}
		public function setTick(tick:uint):void {
			m_tick = tick;
		}
		public function setEOT():void {
			set(MStatus.EOT,           0, 0, 0.0, null);
		}
		public function setNOP():void {
			set(MStatus.NOP,           0, 0, 0.0, null);
		}
		public function setTempo(tempo:Number):void {
			set(MStatus.TEMPO,         0, 0, tempo, null);
		}
		public function setREST():void {
			set(MStatus.REST,          0, 0, 0.0, null);
		}
		public function setNoteOn(noteNo:int):void {
			set(MStatus.NOTE_ON,       noteNo, 0, 0.0, null);
		}
		public function setNoteOff(noteNo:int):void {
			set(MStatus.NOTE_OFF,      noteNo, 0, 0.0, null);
		}
		public function setNote(noteNo:int):void {
			set(MStatus.NOTE,          noteNo, 0, 0.0, null);
		}
		public function setDetune(d:Number, r:int):void {
			set(MStatus.DETUNE,        r, 0, d, null);
		}
		public function setMixingVolume(m_vol:Number):void {
			set(MStatus.MIXING_VOL,    0, 0, m_vol, null);
		}
		public function setVolMode(max:int, rate:Number, mode:int):void {
			set(MStatus.VOL_MODE,      max, mode, rate, null);
		}
		public function setVolume(vol:Number):void {
			set(MStatus.VOLUME,        0, 0, vol, null);
		}
		public function setPan(p:Number):void {
			set(MStatus.PAN,           0, 0, p, null);
		}
		public function setPanLegacy(p:int):void {
			set(MStatus.PAN_LEGACY,    p, 0, 0.0, null);
		}
		public function setForm(form:int, sub:int):void {
			set(MStatus.FORM,          form, sub, 0.0, null);
		}
		public function setSubForm(sub:int):void {
			set(MStatus.SUBFORM,       sub, 0, 0.0, null);
		}
		public function setPhaseRMode(m:int, ph:Number):void {
			set(MStatus.PHASE_R_MODE,  m, 0, ph, null);
		}
		public function setEnvelope(p:int, r:int, lv:Number, a:Array):void {
			set(MStatus.ENVELOPE,      p, r, lv, a);
		}
		public function setLFO(target:int, paramA:Array):void {
			set(MStatus.LFO,           target, 0, 0.0, paramA);
		}
		public function setLFOrestart(target:int):void {
			set(MStatus.LFO_RESTART,   target, 0, 0.0, null);
		}
		public function setLPF(swt:int, paramA:Array):void {
			set(MStatus.LPF,           swt, 0, 0, paramA);
		}
		public function setFormant(vowel:int):void {
			set(MStatus.FORMANT,       vowel, 0, 0.0, null);
		}
		public function setPWM(w:Number, m:int):void {
			set(MStatus.PWM,           m, 0, w, null);
		}
		public function setOPMHwLfo(params:int):void {
			set(MStatus.OPM_HW_LFO,    params, 0, 0.0, null);
		}
		public function setYControl(m:int, f:int, n:Number):void {
			set(MStatus.Y_CONTROL, m, f, n, null);
		}
		public function setPortamento(depth:int, len:int):void {
			set(MStatus.PORTAMENTO,    depth, len, 0.0, null);
		}
		public function setMidiPort(mode:int):void {
			set(MStatus.MIDIPORT,      mode, 0, 0.0, null);
		}
		public function setMidiPortRate(rate:int):void {
			set(MStatus.MIDIPORTRATE,  rate, 0, 0.0, null);
		}
		public function setPortBase(base:int):void {
			set(MStatus.BASENOTE,      base, 0, 0.0, null);
		}
		public function setPoly(voiceCount:int):void {
			set(MStatus.POLY,          voiceCount, 0, 0.0, null);
		}
		public function setFade(time:Number, range:int, mode:int):void {
			set(MStatus.EFF_FADE,      range, mode, time, null);
		}
		public function setDelay(cnt:int, lv:Number):void {
			set(MStatus.EFF_DELAY,     cnt, 0, lv, null);
		}
		public function setRepeatEntry():void {
			set(MStatus.REPEAT_ENTRY,  0, 0, 0.0, null);
		}
		public function setJumpToRept():void {
			set(MStatus.JUMP_TO_REPT,  0, 0, 0.0, null);
		}
		public function setClose():void {
			set(MStatus.CLOSE,         0, 0, 0.0, null);
		}
		public function setSoundOff():void {
			set(MStatus.SOUND_OFF,     0, 0, 0.0, null);
		}
		public function setResetAll():void {
			set(MStatus.RESET_ALL,     0, 0, 0.0, null);
		}

		public function getStatus():int				{ return m_status; }
		public function getDelta():int				{ return m_delta; }
		public function getTick():uint				{ return m_tick;  }
		public function getTempo():Number			{ return m_dataN; }
		public function getNoteNo():int				{ return m_data0; }
		public function getDetune():Number			{ return m_dataN; }
		public function getDetuneRate():int			{ return m_data0; }
		public function getMixingVolume():Number	{ return m_dataN; }
		public function getVolModeMAX():int			{ return m_data0; }
		public function getVolModeRate():Number		{ return m_dataN; }
		public function getVolModeVzMD():int		{ return m_data1; }
		public function getVolume():Number			{ return m_dataN; }
		public function getPan():Number				{ return m_dataN; }
		public function getPanLegacy():int			{ return m_data0; }
		public function getForm():int				{ return m_data0; }
		public function getFormSub():int			{ return m_data1; }
		public function getSubForm():int			{ return m_data0; }
		public function getPhaseRMode():int			{ return m_data0; }
		public function getPhaseRModePH():Number	{ return m_dataN; }
		public function getEnvelopePdest():int		{ return m_data0; }
		public function getEnvelopeRlvRoundM():int	{ return (m_data1 & 0x0ff); }
		public function getEnvelopeRattackM():int	{ return ((m_data1 >> 8) & 1); }
		public function getEnvelopeLinitLv():Number	{ return m_dataN; }
		public function getEnvelopeApoints():Array	{ return m_dataX; }
		public function getLFOtarget():int			{ return m_data0; }
		public function getLFOparams():Array		{ return m_dataX; }
		public function getLFOrestartTarget():int	{ return m_data0; }
		public function getLPFswt():int				{ return m_data0; }
		public function getLPFparams():Array		{ return m_dataX; }
		public function getVowel():int				{ return m_data0; }		//Formant
		public function getPWM():Number				{ return m_dataN; }
		public function getPWMmode():int			{ return m_data0; }
		public function getOPMHwLfoData():int		{ return m_data0; }
		public function getYCtrlMod():int			{ return m_data0; }
		public function getYCtrlFunc():int			{ return m_data1; }
		public function getYCtrlParam():Number		{ return m_dataN; }
		public function getPorDepth():int			{ return m_data0; }
		public function getPorLen():int				{ return m_data1; }
		public function getMidiPort():int			{ return m_data0; }
		public function getMidiPortRate():int		{ return m_data0; }
		public function getPortBase():int			{ return m_data0; }
		public function getVoiceCount():int			{ return m_data0; }		//POLY
		public function getFadeTime():Number		{ return m_dataN; }
		public function getFadeRange():int			{ return m_data0; }
		public function getFadeMode():int			{ return m_data1; }
		public function getDelayCount():int			{ return m_data0; }
		public function getDelayLevel():Number		{ return m_dataN; }
	}
}
