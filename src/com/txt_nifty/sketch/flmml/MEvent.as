package com.txt_nifty.sketch.flmml {
	import mx.controls.videoClasses.CuePointManager;

    public class MEvent {
        private var m_delta:int;
        private var m_status:int;
        private var m_data0:int;
        private var m_data1:int;
		private var m_tick:uint;
        private var TEMPO_SCALE:Number = 100; // bpm小数点第二位まで有効

        public function MEvent(tick:uint) {
            set(MStatus.NOP, 0, 0);
			setTick(tick);
        }

        public function set(status:int, data0:int, data1:int):void {
            m_status = status;
            m_data0  = data0;
            m_data1  = data1;
        }

        public function setEOT():void                         { set(MStatus.EOT, 0, 0); }
        public function setNoteOn(noteNo:int, vel:int):void   { set(MStatus.NOTE_ON, noteNo, vel); }
        public function setNoteOff(noteNo:int, vel:int):void  { set(MStatus.NOTE_OFF, noteNo, vel); }
        public function setTempo(tempo:Number):void              { set(MStatus.TEMPO, tempo * TEMPO_SCALE, 0); }
        public function setVolume(vol:int):void               { set(MStatus.VOLUME, vol, 0); }
        public function setNote(noteNo:int):void              { set(MStatus.NOTE, noteNo, 0); }
        public function setForm(form:int, sub:int):void       { set(MStatus.FORM, form, sub); }
        public function setEnvelope1Atk(a:int):void           { set(MStatus.ENVELOPE1_ATK, a, 0); }
        public function setEnvelope1Point(t:int, l:int):void  { set(MStatus.ENVELOPE1_ADD, t, l); }
        public function setEnvelope1Rel(r:int):void           { set(MStatus.ENVELOPE1_REL, r, 0); }
        public function setEnvelope2Atk(a:int):void           { set(MStatus.ENVELOPE2_ATK, a, 0); }
        public function setEnvelope2Point(t:int, l:int):void  { set(MStatus.ENVELOPE2_ADD, t, l); }
        public function setEnvelope2Rel(r:int):void           { set(MStatus.ENVELOPE2_REL, r, 0); }
        public function setNoiseFreq(f:int):void              { set(MStatus.NOISE_FREQ, f, 0); }
        public function setPWM(w:int):void                    { set(MStatus.PWM, w, 0); }
        public function setPan(p:int):void                    { set(MStatus.PAN, p, 0); }
        public function setFormant(vowel:int):void            { set(MStatus.FORMANT, vowel, 0); }
        public function setDetune(d:int):void                 { set(MStatus.DETUNE, d, 0); }
        public function setLFOFMSF(fm:int, sf:int):void       { set(MStatus.LFO_FMSF, fm, sf); }
        public function setLFODPWD(dp:int, wd:int):void       { set(MStatus.LFO_DPWD, dp, wd); }
        public function setLFODLTM(dl:int, tm:int):void       { set(MStatus.LFO_DLTM, dl, tm); }
        public function setLFOTarget(target:int):void         { set(MStatus.LFO_TARGET, target, 0); }
        public function setLPFSWTAMT(swt:int, amt:int):void   { set(MStatus.LPF_SWTAMT, swt, amt); }
        public function setLPFFRQRES(frq:int, res:int):void   { set(MStatus.LPF_FRQRES, frq, res); }
        public function setClose():void                       { set(MStatus.CLOSE, 0, 0); }
        public function setVolMode(m:int):void                { set(MStatus.VOL_MODE, m, 0); }
        public function setInput(sens:int, pipe:int):void     { set(MStatus.INPUT, sens, pipe); }
        public function setOutput(mode:int, pipe:int):void    { set(MStatus.OUTPUT, mode, pipe); }
        public function setExpression(ex:int):void            { set(MStatus.EXPRESSION, ex, 0); }
        public function setRing(sens:int, pipe:int):void      { set(MStatus.RINGMODULATE, sens, pipe); }
        public function setSync(mode:int, pipe:int):void      { set(MStatus.SYNC, mode, pipe); }
        public function setDelta(delta:int):void              { m_delta = delta; }
		public function setTick(tick:uint):void               { m_tick = tick; }
		public function setPortamento(depth:int, len:int):void { set(MStatus.PORTAMENTO, depth, len); }
		public function setMidiPort(mode:int):void            { set(MStatus.MIDIPORT, mode, 0); };
		public function setMidiPortRate(rate:int):void        { set(MStatus.MIDIPORTRATE, rate, 0); };
		public function setPortBase(base:int):void            { set(MStatus.BASENOTE, base, 0); };
		public function setPoly(voiceCount:int):void		  { set(MStatus.POLY, voiceCount, 0); };
		public function setResetAll():void					  { set(MStatus.RESET_ALL, 0, 0); }
		public function setSoundOff():void					  { set(MStatus.SOUND_OFF, 0, 0); }
		public function setHwLfo(w:int,f:int,pmd:int,amd:int,
		                         pms:int,ams:int,s:int):void  { set(MStatus.HW_LFO, ((w&3)<<27)|((f&0xff)<<19)|((pmd&0x7f)<<12)|((amd&0x7f)<<5)|((pms&7)<<2)|(ams&3),0);}
        public function getStatus():int     { return m_status; }
        public function getDelta():int      { return m_delta; }
		public function getTick():uint      { return m_tick;  }
        public function getNoteNo():int     { return m_data0; }
        public function getVelocity():int   { return m_data1; }
        public function getTempo():Number   { return Number(m_data0) / TEMPO_SCALE; }
        public function getVolume():int     { return m_data0; }
        public function getForm():int       { return m_data0; }
        public function getSubForm():int    { return m_data1; }
        public function getEnvelopeA():int  { return m_data0; }
        public function getEnvelopeT():int  { return m_data0; }
        public function getEnvelopeL():int  { return m_data1; }
        public function getEnvelopeR():int  { return m_data0; }
        public function getNoiseFreq():int  { return m_data0; }
        public function getPWM():int        { return m_data0; }
        public function getPan():int        { return m_data0; }
        public function getVowel():int      { return m_data0; }
        public function getDetune():int     { return m_data0; }
        public function getLFODepth():int   { return m_data0; }
        public function getLFOWidth():int   { return m_data1; }
        public function getLFOForm():int    { return m_data0; }
        public function getLFOSubForm():int { return m_data1; }
        public function getLFODelay():int   { return m_data0; }
        public function getLFOTime():int    { return m_data1; }
        public function getLFOTarget():int  { return m_data0; }
        public function getLPFSwt():int     { return m_data0; }
        public function getLPFAmt():int     { return m_data1; }
        public function getLPFFrq():int     { return m_data0; }
        public function getLPFRes():int     { return m_data1; }
        public function getVolMode():int    { return m_data0; }
        public function getInputSens():int  { return m_data0; }
        public function getInputPipe():int  { return m_data1; }
        public function getOutputMode():int { return m_data0; }
        public function getOutputPipe():int { return m_data1; }
        public function getExpression():int { return m_data0; }
        public function getRingSens():int   { return m_data0; }
        public function getRingInput():int  { return m_data1; }
        public function getSyncMode():int   { return m_data0; }
        public function getSyncPipe():int   { return m_data1; }
		public function getPorDepth():int   { return m_data0; }
		public function getPorLen():int     { return m_data1; }
		public function getMidiPort():int   { return m_data0; }
		public function getMidiPortRate():int { return m_data0; }
		public function getPortBase():int   { return m_data0; }
		public function getVoiceCount():int { return m_data0; }
		public function getHwLfoData():int  { return m_data0; }
    }
}
