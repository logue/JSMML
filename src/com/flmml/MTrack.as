﻿package com.flmml {
	import __AS3__.vec.Vector;
	
	import flash.errors.MemoryError;

	public class MTrack {
		public static const TEMPO_TRACK:int = 0;
		public static const FIRST_TRACK:int = 1;
		public static var s_infiniteRepeatF:Boolean = false;
		public static var s_IRRequestLastTrack:int = 0;
		public  var m_IRCheckStrictlyF:Boolean;	//テンポトラックで、先頭以外にも複数ポイントでテンポ指定を行う場合に厳密チェック要求を行う。
		public  var m_IRepeatF:Boolean;
		public  var m_IRepeatPt:int;
		public  var m_IRepeatGt:uint;
		public  var m_IRepeatGtReq:uint;
		public  var m_IRepeatStOct:int;		//無限リピートエントリ時のオクターブ値（デバッグ表示用）
		public  var m_IRepeatEdOct:int;		//無限リピート有効時のトラック終端オクターブ値（デバッグ表示用）
		private var m_bpm:Number;         // beat per minute
		private var m_spt:Number;         // samples per tick
		private var m_spt_final:Number;   // テンポトラック終端における m_spt
		private var m_ch:IChannel;        // channel (instrument)
		private var m_needle:Number;      // delta time
		private var m_gate_rate:Number;   // default gate time rate (max:1.0)
		private var m_gate_ticks1:int;    // gate time 1 (ticks)
		private var m_gate_ticks2:int;    // gate time 2 (ticks)
		private var m_events:Array;       //
		private var m_pointer:int;        // current event no.
		private var m_delta:uint;
		private var m_isEnd:int;
		private var m_globalTick:uint;
		private var m_pitchReso:Number;
		private var m_totalMSec:Number;
		private var m_noteOnPos:uint;
		private var m_noteOffPos:uint;
		private var m_delayCountReq:int;
		private var m_polyFound:Boolean;
		private var m_chordBegin:uint;
		private var m_chordEnd:uint;
		private var m_chordMode:Boolean;
		private var m_ch_length:int;
		
		public function MTrack() {
			m_isEnd              = 0;
			m_ch                 = new MChannel();
			m_ch_length          = 1;
			m_needle             = 0.0;
			m_polyFound          = false;
			playTempo(MML.DEF_BPM);
			recGateRate(1.0/1.0);				//デフォルトはゲート無し。
			recGateTicks1(0);					//デフォルトはゲート無し。
			recGateTicks2(0);					//デフォルトはゲート無し。
			m_events             = new Array();
			m_pointer = 0;
			m_delta = 0;
			m_globalTick = 0;
			m_pitchReso = MML.DEF_DETUNE_RESO;
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
			
			//初期化 for Status Disp. --------------------------------------------
			forStatus_playTempo(MML.DEF_BPM);
			m_tStatus_needle = 0.0;
			m_tStatus_pointer = 0;
			m_tStatus_delta = 0;
			m_tStatus_isEnd = 0;
			m_tStatus_globalTick = 0;
			
			m_tStatus_info = new Vector.<Number>(TSTAT_MAX);
			m_tStatus_info[TSTAT_BPM] = MML.DEF_BPM;
			m_tStatus_info[TSTAT_NOTE] = 0.0;
			m_tStatus_info[TSTAT_NOTE_NOW] = 0.0;
			m_tStatus_info[TSTAT_NOTE_ON] = 0.0;
			m_tStatus_info[TSTAT_DETUNE] = 0.0;
			m_tStatus_info[TSTAT_P_RESO] = MML.DEF_DETUNE_RESO;
			m_tStatus_info[TSTAT_MIXVOL] = MML.DEF_MIXVOL;
			m_tStatus_info[TSTAT_VMODE_MAX] = Number(MML.DEF_VSMAX);
			m_tStatus_info[TSTAT_VMODE_RT] = MML.DEF_VSRATE;
			m_tStatus_info[TSTAT_VMODE_VZ] = 0.0;
			m_tStatus_info[TSTAT_VOL] = MML.DEF_VOL;
			m_tStatus_info[TSTAT_PAN] = MML.DEF_PAN;
			m_tStatus_info[TSTAT_PAN_NOW] = MML.DEF_PAN;
			m_tStatus_info[TSTAT_PANLG] = Number(MML.DEF_LG_PAN);
			m_tStatus_info[TSTAT_FORM] = Number(MML.DEF_FORM);
			m_tStatus_info[TSTAT_SUBFORM] = Number(MML.DEF_SUBFORM);
			m_tStatus_info[TSTAT_LFO_P] = 0.0;
			m_tStatus_info[TSTAT_LFO_A] = 0.0;
			m_tStatus_info[TSTAT_LFO_B] = 0.0;
			m_tStatus_info[TSTAT_LFO_F] = 0.0;
			m_tStatus_info[TSTAT_LFO_Y] = 0.0;
			m_tStatus_info[TSTAT_LPF] = 0.0;
			m_tStatus_info[TSTAT_FORMANT] = (-1.0);
			m_tStatus_info[TSTAT_PWM] = 0.5;
			m_tStatus_info[TSTAT_FM_HLFO] = 0.0;
			m_tStatus_info[TSTAT_NOISE_W] = 1.0;
			m_tStatus_info[TSTAT_NOISE_FC] = 0.0;
			m_tStatus_info[TSTAT_NOISE_GB] = 0.0;
			m_tStatus_info[TSTAT_NOISE_PSG] = 1.0;
			m_tStatus_info[TSTAT_MIDIPORT] = 0.0;
			m_tStatus_info[TSTAT_POLY] = 1.0;
			m_tStatus_info[TSTAT_FADE] = (-1.0);
			m_tStatus_info[TSTAT_DELAY] = 0.0;
			
			m_tStatus_noteOn = new Vector.<Number>(TSTAT_NOTE_MAX);
			for (var i:int = 0; i<TSTAT_NOTE_MAX; i++) {
				m_tStatus_noteOn[i] = 0.0;
			}
			
			m_tStatus_noteNo = 0;
			m_tStatus_freqNo = 0.0;
			m_tStatus_detune = 0.0;
			m_tStatus_pitchReso = MML.DEF_DETUNE_RESO;
			m_tStatus_portDepth = 0.0;
			m_tStatus_portDepthAdd = 0.0;
			m_tStatus_portamento = 0;
			m_tStatus_portRate = 0.0;
			m_tStatus_lastFreqNo = 0.0;
			
			m_tStatus_pan = 0.0;
			
			// LFO stand by [static to member]
			m_tStatus_LFOclockMode = MChannel.s_LFOclockMode;
			m_tStatus_LFOclockMgnf = MChannel.s_LFOclockMgnf;
			m_tStatus_LFOclock = MChannel.s_LFOclock;
			m_tStatus_lfoDeltaMode = MChannel.s_lfoDeltaMode;
			m_tStatus_lfoDeltaMgnf = MChannel.s_lfoDeltaMgnf;
			m_tStatus_lfoDelta = MChannel.s_lfoDelta;
			m_tStatus_lfoLastSPT = 0.0;
			// LFO stand by [module]
			m_tStatus_oscSetLP = new MOscillatorL();
			m_tStatus_oscSetLB = new MOscillatorL();
			m_tStatus_oscModL = new Vector.<MOscModL>(TSTAT_LFO_MAX);
			m_tStatus_oscLConnect = new Vector.<int>(TSTAT_LFO_MAX);
			m_tStatus_lfoParam = new Vector.<Array>(TSTAT_LFO_MAX);
			m_tStatus_lfoDepth = new Vector.<Number>(TSTAT_LFO_MAX);
			m_tStatus_lfoDelay = new Vector.<Number>(TSTAT_LFO_MAX);
			m_tStatus_lfoDelta_seqCnt = new Vector.<Number>(TSTAT_LFO_MAX);
			m_tStatus_lfoInit  = new Array(0.0, 1.0, 0, 0, 0.0);			//depth, width, form, subform, delay
			// Pitch LFO
			m_tStatus_oscSetLP.setForm(MOscillatorL.SINE);
			m_tStatus_oscModL[TSTAT_LFO_TARGET_PITCH] = m_tStatus_oscSetLP.getCurrent();
			m_tStatus_oscModL[TSTAT_LFO_TARGET_PITCH].setWaveNo(0);
			m_tStatus_oscLConnect[TSTAT_LFO_TARGET_PITCH] = 0;
			// PanPot LFO
			m_tStatus_oscSetLB.setForm(MOscillatorL.SINE);
			m_tStatus_oscModL[TSTAT_LFO_TARGET_PANPOT] = m_tStatus_oscSetLB.getCurrent();
			m_tStatus_oscModL[TSTAT_LFO_TARGET_PANPOT].setWaveNo(0);
			m_tStatus_oscLConnect[TSTAT_LFO_TARGET_PANPOT] = 0;
			// LFO reset Param
			m_tStatus_onCounter = 0;
			forStatus_setLFO(TSTAT_LFO_TARGET_PITCH, m_tStatus_lfoInit, 1.0);
			forStatus_setLFO(TSTAT_LFO_TARGET_PANPOT, m_tStatus_lfoInit, 1.0);
		}
		
		// for Track Status Disp. [start]--------------------------------------
		private var m_tStatus_spt:Number;
		private var m_tStatus_spt_final:Number;
		private var m_tStatus_needle:Number;
		private var m_tStatus_pointer:int;
		private var m_tStatus_delta:uint;
		private var m_tStatus_isEnd:int;
		private var m_tStatus_globalTick:uint;
		
		public  var m_tStatus_info:Vector.<Number>;
		public static const TSTAT_BPM:int		= 0;
		public static const TSTAT_NOTE:int		= 1;
		public static const TSTAT_NOTE_NOW:int	= 2;
		public static const TSTAT_NOTE_ON:int	= 3;
		public static const TSTAT_DETUNE:int	= 4;
		public static const TSTAT_P_RESO:int	= 5;
		public static const TSTAT_MIXVOL:int	= 6;
		public static const TSTAT_VMODE_MAX:int	= 7;
		public static const TSTAT_VMODE_RT:int	= 8;
		public static const TSTAT_VMODE_VZ:int	= 9;
		public static const TSTAT_VOL:int		= 10;
		public static const TSTAT_PAN:int		= 11;
		public static const TSTAT_PAN_NOW:int	= 12;
		public static const TSTAT_PANLG:int		= 13;
		public static const TSTAT_FORM:int		= 14;
		public static const TSTAT_SUBFORM:int	= 15;
		public static const TSTAT_LFO_P:int		= 16;
		public static const TSTAT_LFO_A:int		= 17;
		public static const TSTAT_LFO_B:int		= 18;
		public static const TSTAT_LFO_F:int		= 19;
		public static const TSTAT_LFO_Y:int		= 20;
		public static const TSTAT_LPF:int		= 21;
		public static const TSTAT_FORMANT:int	= 22;
		public static const TSTAT_PWM:int		= 23;
		public static const TSTAT_FM_HLFO:int	= 24;
		public static const TSTAT_NOISE_W:int	= 25;
		public static const TSTAT_NOISE_FC:int	= 26;
		public static const TSTAT_NOISE_GB:int	= 27;
		public static const TSTAT_NOISE_PSG:int	= 28;
		public static const TSTAT_MIDIPORT:int	= 29;
		public static const TSTAT_POLY:int		= 30;
		public static const TSTAT_FADE:int		= 31;
		public static const TSTAT_DELAY:int		= 32;
		public static const TSTAT_MAX:int		= 33;
		public var m_tStatus_noteOn:Vector.<Number>;
		public static const TSTAT_NOTE_MAX:int	= 128;
		
		private var m_tStatus_noteNo:int;
		private var m_tStatus_freqNo:Number;
		private var m_tStatus_detune:Number;
		private var m_tStatus_pitchReso:Number;
		private var m_tStatus_portDepth:Number;
		private var m_tStatus_portDepthAdd:Number;
		private var m_tStatus_portamento:int;
		private var m_tStatus_portRate:Number;
		private var m_tStatus_lastFreqNo:Number;
		
		private var m_tStatus_pan:Number;
		
		private static const TSTAT_LFO_TARGET_PITCH:int     = 0;
		private static const TSTAT_LFO_TARGET_PANPOT:int    = 1;
		private static const TSTAT_LFO_MAX:int              = 2;
		private var m_tStatus_onCounter:int;				// NoteONからの経過サンプル数(44100Hz)
		private var m_tStatus_LFOclockMode:Boolean;
		private var m_tStatus_LFOclockMgnf:Number;
		private var m_tStatus_LFOclock:Number;
		private var m_tStatus_lfoDeltaMode:Boolean;
		private var m_tStatus_lfoDeltaMgnf:Number;
		private var m_tStatus_lfoDelta:int;
		private var m_tStatus_lfoLastSPT:Number;
		private var m_tStatus_oscSetLP:MOscillatorL;		// for Pitch LFO
		private var m_tStatus_oscSetLB:MOscillatorL;		// for PanPot LFO
		private var m_tStatus_oscModL:Vector.<MOscModL>;	// 使用波形モジュール
		private var m_tStatus_oscLConnect:Vector.<int>;		// 有効・無効確認
		private var m_tStatus_lfoParam:Vector.<Array>;		// MMLからのパラメータ配列の参照を保持
		private var m_tStatus_lfoDepth:Vector.<Number>;
		private var m_tStatus_lfoDelay:Vector.<Number>;
		private var m_tStatus_lfoDelta_seqCnt:Vector.<Number>;
		private var m_tStatus_lfoInit:Array;
		
		private function limitNum(min:Number, max:Number, num:Number):Number {
			if (num < min) return min;
			else if (num > max) return max;
			else return num;
		}
		private function limitNumI(min:int, max:int, num:int):int {
			if (num < min) return min;
			else if (num > max) return max;
			else return num;
		}
		private function forStatus_isEnd():int {
			return m_tStatus_isEnd;
		}
		private function forStatus_playTempo(bpm:Number):void {
			m_tStatus_spt = calcSpt(bpm);
		}
		// skip再生時における samples per tick 強制設定（通常は使用しないこと）
		private function forStatus_setSptForce(spt:Number):void {
			m_tStatus_spt = spt;
		}
		public function forStatus_onSampleData(start:int, end:int):void {
			if (forStatus_isEnd()) return;
			for (var n:Number = Number(start); n < Number(end);) {
				// exec events
				var exec:int = 0;
				var eLen:int = m_events.length;
				var stat:int;
				var i:int, j:int, arr:Array;
				var tickpos:uint;
				var e:MEvent;
				var delta:Number;
				do {
					exec = 0;
					if (m_tStatus_pointer < eLen) {
						e = m_events[m_tStatus_pointer];
						delta = Number(e.getDelta()) * m_tStatus_spt;
						if (m_tStatus_needle >= delta) {
							exec = 1;
							stat = e.getStatus();
							tickpos = e.getTick();
							switch(stat) {
								case MStatus.EOT:
									m_tStatus_isEnd = 1;
									break;
								case MStatus.NOP:
									break;
								case MStatus.TEMPO:
									m_tStatus_info[TSTAT_BPM] = e.getTempo();
									forStatus_playTempo(e.getTempo());
									forStatus_setLfoSptUnit(m_tStatus_spt);
									break;
								case MStatus.REST:
									break;
								case MStatus.NOTE_ON:
									m_tStatus_noteNo = e.getNoteNo();
									m_tStatus_freqNo = (Number(m_tStatus_noteNo) * m_tStatus_pitchReso) + m_tStatus_detune;
									if (m_tStatus_portamento == 1) {
										m_tStatus_portDepth = (m_tStatus_lastFreqNo - m_tStatus_freqNo);
										m_tStatus_portDepthAdd = (m_tStatus_portDepth < 0.0) ? m_tStatus_portRate : (m_tStatus_portRate * (-1.0));
									}
									m_tStatus_lastFreqNo = m_tStatus_freqNo;
									
									m_tStatus_info[TSTAT_NOTE] = limitNum(0.0,120.0,Math.round(m_tStatus_freqNo / m_tStatus_pitchReso));
									m_tStatus_info[TSTAT_NOTE_NOW] = m_tStatus_info[TSTAT_NOTE];
									m_tStatus_info[TSTAT_NOTE_ON] = 1.0;
									
									if (m_tStatus_info[TSTAT_POLY] > 1.0) {
										for (j=0; j<TSTAT_NOTE_MAX; j++) {
											if (m_tStatus_noteOn[j] < 1.0) m_tStatus_noteOn[j] = 0.0;
										}
										m_tStatus_noteOn[ limitNumI(0,120,m_tStatus_noteNo) ] = 1.0;	//ポリモードでは、detuneやportamentoによるずれをサポートしない
									}
									
									for (i = 0; i < TSTAT_LFO_MAX; i++) {
										if (m_tStatus_lfoDelay[i] >= 0.0) {
											m_tStatus_oscModL[i].resetPhase();
											m_tStatus_lfoDelta_seqCnt[i] = m_tStatus_lfoDelay[i];
										}
									}
									m_tStatus_onCounter = 0;
									break;
								case MStatus.NOTE_OFF:
									m_tStatus_info[TSTAT_NOTE_ON] = 0.0;
									
									if (m_tStatus_info[TSTAT_POLY] > 1.0) {
										i = limitNumI(0,120,e.getNoteNo());
										m_tStatus_noteOn[i] = 0.375;
									}
									break;
								case MStatus.NOTE:
									if (m_tStatus_info[TSTAT_POLY] > 1.0) {
										m_tStatus_noteOn[ int(m_tStatus_info[TSTAT_NOTE]) ] = 0.0;
									}
									
									m_tStatus_noteNo = e.getNoteNo();
									m_tStatus_freqNo = (Number(m_tStatus_noteNo) * m_tStatus_pitchReso) + m_tStatus_detune;
									if (m_tStatus_portamento == 1) {
										m_tStatus_portDepth += (m_tStatus_lastFreqNo - m_tStatus_freqNo);
										m_tStatus_portDepthAdd = (m_tStatus_portDepth < 0.0) ? m_tStatus_portRate : (m_tStatus_portRate * (-1.0));
									}
									m_tStatus_lastFreqNo = m_tStatus_freqNo;
									
									m_tStatus_info[TSTAT_NOTE] = limitNum(0.0,120.0,Math.round(m_tStatus_freqNo / m_tStatus_pitchReso));
									m_tStatus_info[TSTAT_NOTE_NOW] = m_tStatus_info[TSTAT_NOTE];
									
									if (m_tStatus_info[TSTAT_POLY] > 1.0) {
										m_tStatus_noteOn[ limitNumI(0,120,m_tStatus_noteNo) ] = 1.0;	//ポリモードでは、detuneやportamentoによるずれをサポートしない
									}
									break;
								case MStatus.DETUNE:
									var dtrate:Number = e.getDetuneRate();
									if ((dtrate >= 10.0) && (dtrate <= 1000.0)) {
										m_tStatus_pitchReso = dtrate;
										m_tStatus_info[TSTAT_P_RESO] = dtrate;
									}
									m_tStatus_detune = e.getDetune();
									m_tStatus_freqNo = (Number(m_tStatus_noteNo) * m_tStatus_pitchReso) + m_tStatus_detune;
									m_tStatus_info[TSTAT_DETUNE] = m_tStatus_detune;
									m_tStatus_info[TSTAT_NOTE_NOW] = limitNum(0.0,120.0,Math.round(m_tStatus_freqNo / m_tStatus_pitchReso));
									break;
								case MStatus.MIXING_VOL:
									m_tStatus_info[TSTAT_MIXVOL] = e.getMixingVolume();
									break;
								case MStatus.VOL_MODE:
									m_tStatus_info[TSTAT_VMODE_MAX] = Number(e.getVolModeMAX());
									m_tStatus_info[TSTAT_VOL] = m_tStatus_info[TSTAT_VMODE_MAX];
									m_tStatus_info[TSTAT_VMODE_RT] = e.getVolModeRate();
									m_tStatus_info[TSTAT_VMODE_VZ] = Number(e.getVolModeVzMD());
									break;
								case MStatus.VOLUME:
									m_tStatus_info[TSTAT_VOL] = e.getVolume();
									break;
								case MStatus.PAN:
									m_tStatus_pan = e.getPan();
									m_tStatus_info[TSTAT_PAN] = m_tStatus_pan;
									m_tStatus_info[TSTAT_PAN_NOW] = m_tStatus_pan;
									break;
								case MStatus.PAN_LEGACY:
									m_tStatus_info[TSTAT_PANLG] = Number(e.getPanLegacy());
									break;
								case MStatus.FORM:
									m_tStatus_info[TSTAT_FORM] = Number(e.getForm());
									m_tStatus_info[TSTAT_SUBFORM] = Number(e.getFormSub());
									break;
								case MStatus.SUBFORM:
									m_tStatus_info[TSTAT_SUBFORM] = Number(e.getSubForm());
									break;
								case MStatus.PHASE_R_MODE:
									break;
								case MStatus.OPTION_CLOCK:
									forStatus_setOptionClock(e.getOptionClockFunc(), e.getOptionClockMode(), e.getOptionClockNum());
									break;
								case MStatus.ENVELOPE:
									break;
								case MStatus.LFO:
									i = e.getLFOtarget();
									arr = e.getLFOparams();
									if (i == 0) {
										m_tStatus_info[TSTAT_LFO_P] = arr[0];
										forStatus_setLFO(TSTAT_LFO_TARGET_PITCH, arr, m_tStatus_spt);
									}
									else if (i == 1) { m_tStatus_info[TSTAT_LFO_A] = arr[0]; }
									else if (i == 2) { m_tStatus_info[TSTAT_LFO_F] = arr[0]; }
									else if (i == 3) {
										m_tStatus_info[TSTAT_LFO_B] = arr[0];
										forStatus_setLFO(TSTAT_LFO_TARGET_PANPOT, arr, m_tStatus_spt);
									}
									else if (i == 4) { m_tStatus_info[TSTAT_LFO_Y] = arr[0]; }
									break;
								case MStatus.LFO_RESTART:
									i = e.getLFOrestartTarget();
									if (i == 0)      { forStatus_setLFOrestart(TSTAT_LFO_TARGET_PITCH); }
									else if (i == 3) { forStatus_setLFOrestart(TSTAT_LFO_TARGET_PANPOT); }
									break;
								case MStatus.LPF:
									m_tStatus_info[TSTAT_LPF] = Number(e.getLPFswt());
									break;
								case MStatus.FORMANT:
									m_tStatus_info[TSTAT_FORMANT] = Number(e.getVowel());
									break;
								case MStatus.PWM:
									i = e.getPWMmode();
									if (i == 0) { m_tStatus_info[TSTAT_PWM] = Number(e.getPWM()); }
									else { m_tStatus_info[TSTAT_PWM] = (-1.0); }		//エンベロープモード
									break;
								case MStatus.OPM_HW_LFO:
									i = e.getOPMHwLfoData();
									var fmlfo_hmd:int = (i>>30) & 0x01;
									var fmlfo_pmd:int = (i>>13) & 0x7F;
									var fmlfo_amd:int = (i>> 6) & 0x7F;
									var fmlfo_pms:int = (i>> 3) & 0x07;
									var fmlfo_ams:int = (i>> 1) & 0x03;
									if (fmlfo_hmd == 0){
										if ( ((fmlfo_pmd==0)||(fmlfo_pms==0)) && ((fmlfo_amd==0)||(fmlfo_ams==0)) ) {
											m_tStatus_info[TSTAT_FM_HLFO] = 0.0;
										}
										else {
											m_tStatus_info[TSTAT_FM_HLFO] = 1.0;		//OPM HLFO
										}
									}
									else {
										if ( (fmlfo_pms==0) && (fmlfo_ams==0) ) {
											m_tStatus_info[TSTAT_FM_HLFO] = 0.0;
										}
										else {
											m_tStatus_info[TSTAT_FM_HLFO] = 2.0;		//OPNA HLFO
										}
									}
									break;
								case MStatus.Y_CONTROL:
									i = e.getYCtrlMod();
									j = e.getYCtrlFunc();
									if ((i==MOscillator.NOISE_W) && (j==5)) {
										m_tStatus_info[TSTAT_NOISE_W] = limitNum(1.0, 44100.0, e.getYCtrlParam());
									}
									else if ((i==MOscillator.NOISE_FC) && (j==5)) {
										m_tStatus_info[TSTAT_NOISE_FC] = limitNum(0.0, 15.0, e.getYCtrlParam());
									}
									else if ((i==MOscillator.NOISE_GB) && (j==5)) {
										m_tStatus_info[TSTAT_NOISE_GB] = limitNum(0.0, 157.0, e.getYCtrlParam());
									}
									else if ((i==MOscillator.NOISE_PSG) && (j==5)) {
										m_tStatus_info[TSTAT_NOISE_PSG] = limitNum(1.0, 1023.0, e.getYCtrlParam());
									}
									break;
								case MStatus.PORTAMENTO:
									m_tStatus_portamento = 0;
									m_tStatus_portDepth = Number(e.getPorDepth()) * m_tStatus_pitchReso;
									m_tStatus_portDepthAdd = (m_tStatus_portDepth / (Number(e.getPorLen()) * m_tStatus_spt)) * (-1.0);
									m_tStatus_info[TSTAT_MIDIPORT] = 0.0;
									break;
								case MStatus.MIDIPORT:
									m_tStatus_portamento = e.getMidiPort();
									m_tStatus_portDepth = 0.0;
									m_tStatus_info[TSTAT_MIDIPORT] = Number(m_tStatus_portamento);
									break;
								case MStatus.MIDIPORTRATE:
									i = e.getMidiPortRate();
									if (i > 0) {
										m_tStatus_portRate = (8.0 - (Number(i) * 7.99 / 128.0)) / Number(i);
									}
									else {
										m_tStatus_portRate = 0.0;
									}
									break;
								case MStatus.BASENOTE:
									m_tStatus_lastFreqNo = Number(e.getPortBase()) * m_pitchReso;
									break;
								case MStatus.POLY:
									m_tStatus_info[TSTAT_POLY] = Number(e.getVoiceCount());
									break;
								case MStatus.EFF_FADE:
									m_tStatus_info[TSTAT_FADE] = Number(e.getFadeMode());
									break;
								case MStatus.EFF_DELAY:
									m_tStatus_info[TSTAT_DELAY] = Number(e.getDelayCount());
									break;
								case MStatus.REPEAT_ENTRY:
									//conduct()後にTEMPOと同系列で処理。シーケンス中はＮＯＰ。
									break;
								case MStatus.JUMP_TO_REPT:
									//当コマンドはconduct()後に生成される。
									//ジャンプ処理そのものは下記if節で行う。通常のm_pointerインクリメントと排他制御するため。
									break;
								case MStatus.CLOSE:
									break;
								case MStatus.SOUND_OFF:
									break;
								case MStatus.RESET_ALL:
									break;
								default:
									break;
							}
							m_tStatus_needle -= delta;
							if (stat != MStatus.JUMP_TO_REPT) {
								m_tStatus_pointer++;
							}
							else {
								m_tStatus_pointer = m_IRepeatPt;
								m_tStatus_globalTick = m_IRepeatGt;
							}
						}
					}
				} while(exec);
				
				// create a short wave (dummy)
				var dn:Number;
				var smpSeq_s:int, smpSeq_e:int, smpSeq_end:int;
				var smpSeq_freqNo:Number;
				var smpSeq_pan:Number;
				var smpSeq_onCounter:int;
				var smpSeq_skipCnt:int;
				if (m_tStatus_pointer < eLen) {
					e = m_events[m_tStatus_pointer];
					delta = Number(e.getDelta()) * m_tStatus_spt;
					dn = Math.ceil(delta - m_tStatus_needle);
					if ((n + dn) >= Number(end)) dn = Number(end) - n;
					m_tStatus_needle += dn;
					//trace("n:" + n + "/dn:" + dn);
					//m_ch.getSamples(samples, end, int(n), int(dn));
					
					smpSeq_s = int(n);
					smpSeq_e = smpSeq_s + int(dn);
					if (smpSeq_e > end) smpSeq_e = end;
					smpSeq_onCounter = m_tStatus_onCounter;
					smpSeq_freqNo = m_tStatus_freqNo;
					
					if (m_tStatus_portDepth != 0.0) {
						smpSeq_freqNo += m_tStatus_portDepth;
						m_tStatus_portDepth += (m_tStatus_portDepthAdd * Number(smpSeq_e - smpSeq_s - 0));			//getNextSample()をしないので-1が不要
						if ((m_tStatus_portDepth * m_tStatus_portDepthAdd) > 0.0) m_tStatus_portDepth = 0.0;
					}
					
					if (m_tStatus_oscLConnect[TSTAT_LFO_TARGET_PITCH] != 0) {
						if (m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PITCH] <= 0) {
							smpSeq_freqNo += (m_tStatus_oscModL[TSTAT_LFO_TARGET_PITCH].getNextSample() * m_tStatus_lfoDepth[TSTAT_LFO_TARGET_PITCH]);
							m_tStatus_oscModL[TSTAT_LFO_TARGET_PITCH].addPhase(smpSeq_e - smpSeq_s - 1);
							smpSeq_skipCnt = int( Math.ceil(dn / Number(m_tStatus_lfoDelta)) );
							if (smpSeq_skipCnt > 1) {
								m_tStatus_oscModL[TSTAT_LFO_TARGET_PITCH].addPShift(smpSeq_skipCnt - 1);
							}
							m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PITCH] += dn;
						}
						m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PITCH] -= dn;
					}
					//trace("seqCnt:"+m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PITCH]+" dn:"+dn+" onCnt:"+m_tStatus_onCounter);
					m_tStatus_info[TSTAT_NOTE_NOW] = limitNum(0.0,120.0,Math.round(smpSeq_freqNo / m_tStatus_pitchReso));
					
					if (m_tStatus_oscLConnect[TSTAT_LFO_TARGET_PANPOT] != 0) {
						smpSeq_pan = m_tStatus_pan;
						if (m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PANPOT] <= 0) {
							smpSeq_pan += (m_tStatus_oscModL[TSTAT_LFO_TARGET_PANPOT].getNextSample() * m_tStatus_lfoDepth[TSTAT_LFO_TARGET_PANPOT]);
							m_tStatus_oscModL[TSTAT_LFO_TARGET_PANPOT].addPhase(smpSeq_e - smpSeq_s - 1);
							m_tStatus_oscModL[TSTAT_LFO_TARGET_PANPOT].addPShift(smpSeq_e - smpSeq_s - 1);
							m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PANPOT] += dn;
						}
						m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PANPOT] -= dn;
						//trace("seqCnt(pan):"+m_tStatus_lfoDelta_seqCnt[TSTAT_LFO_TARGET_PANPOT]+" pan:"+smpSeq_pan+" dn:"+dn+" onCnt:"+m_tStatus_onCounter);
						m_tStatus_info[TSTAT_PAN_NOW] = limitNum(-100.0,100.0,smpSeq_pan);
					}
					
					m_tStatus_onCounter += int(dn);
					n += dn;
				}
				else {
					break;
				}
			}
		}
		private function forStatus_setLfoSptUnit(spt:Number):void {
			var lforeso:int;
			if (m_tStatus_lfoLastSPT == spt) return;
			
			if (m_tStatus_lfoDeltaMode == true) {
				lforeso = int(spt * m_tStatus_lfoDeltaMgnf);
				if (lforeso < 147) lforeso = 147;							//超高速モードにつきあう限界
				m_tStatus_lfoDelta = lforeso;										//ＬＦＯ解像度の追従
			}
			
			forStatus_refreshLFO(spt);
			
			m_tStatus_lfoLastSPT = spt;
		}
		private function forStatus_setOptionClock(func:int, mode:int, num:Number):void {
			var lforeso:int;
			switch (func) {
				case 0:		//env.clock
					break;
				case 1:		//env.resol
					break;
				case 2:		//lfo.clock
					m_tStatus_LFOclockMode = ((mode == 0) ? false : true );
					m_tStatus_LFOclockMgnf = ((mode == 0) ? (1.0) : num  );			//m_LFOclockMode==falseのとき、m_LFOclockMgnfは参照されない
					m_tStatus_LFOclock =     ((mode == 0) ? num   : (1.0/120.0));	//m_LFOclockMode==trueのとき、m_LFOclockは参照されない
					forStatus_refreshLFO(m_tStatus_lfoLastSPT);
					break;
				case 3:		//lfo.resol
					m_tStatus_lfoDeltaMode = ((mode == 0) ? false : true );
					m_tStatus_lfoDeltaMgnf = ((mode == 0) ? (1.0) : num  );			//m_lfoDeltaMode==falseのとき、m_lfoDeltaMgnfは参照されない
					if (m_tStatus_lfoDeltaMode == true) {
						lforeso = int(m_tStatus_lfoLastSPT * m_tStatus_lfoDeltaMgnf);
						if (lforeso < 147) lforeso = 147;							//超高速モードにつきあう限界
						m_tStatus_lfoDelta = lforeso;								//ＬＦＯ解像度の追従
					}
					else {
						m_tStatus_lfoDelta = int(44100.0 * num);
					}
					forStatus_refreshLFO(m_tStatus_lfoLastSPT);
					break;
				default:
					break;
			}
		}
		private function forStatus_setLFO(target:int, paramA:Array, spt:Number):void {
			var valid:Boolean;
			
			var depth:Number  = paramA[0];
			var width:Number  = paramA[1];
			var form:int      = paramA[2];
			var subform:int   = paramA[3];
			var delay:Number  = paramA[4];
			
			var dp:Number;
			var sign:Number;
			var freq:Number;
			var widthSMP:Number;
			var i:int, j:int;
			
			// target check
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
				case TSTAT_LFO_TARGET_PANPOT:
					valid = true;
					break;
				default:
					valid = false;
			}
			if (valid == false) return;
			
			// parameter check
			if (depth == 0.0) {
				m_tStatus_oscLConnect[target] = 0;
				m_tStatus_lfoParam[target] = null;
			}
			else {
				m_tStatus_oscLConnect[target] = 1;
				m_tStatus_lfoParam[target] = paramA;		//指定パラメータ配列の参照を保存
			}
			if ( (width == 0.0) || (m_tStatus_LFOclock == 0.0) || (m_tStatus_LFOclockMgnf == 0.0) ) {
				m_tStatus_oscLConnect[target] = 0;
			}
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
					if (form >= MOscillatorL.MAX) m_tStatus_oscLConnect[target] = 0;
					break;
				case TSTAT_LFO_TARGET_PANPOT:
					if (form >= MOscillatorL.MAX) m_tStatus_oscLConnect[target] = 0;
					break;
				default:
					break;
			}
			if (m_tStatus_oscLConnect[target] == 0) {
				return;
			}
			
			// parameter set: depth
			dp = Math.abs(depth);
			sign = depth / dp;
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
					m_tStatus_lfoDepth[target] = depth;
					break;
				case TSTAT_LFO_TARGET_PANPOT:
					if (dp > 200.0) dp = 200.0;
					m_tStatus_lfoDepth[target] = dp * sign;
					break;
				default:
					break;
			}
			
			// parameter set: form/subform
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
					m_tStatus_oscModL[target] = m_tStatus_oscSetLP.setForm(form);
					m_tStatus_oscModL[target].setWaveNo(subform);
					break;
				case TSTAT_LFO_TARGET_PANPOT:
					m_tStatus_oscModL[target] = m_tStatus_oscSetLB.setForm(form);
					m_tStatus_oscModL[target].setWaveNo(subform);
					break;
				default:
					break;
			}
			
			// parameter set: width
			if (m_tStatus_LFOclockMode == true) {
				width = width * m_tStatus_LFOclockMgnf;
				if (spt != 0.0) { freq = 44100.0 / (width * spt); }
				else { freq = 44100.0; }
			}
			else {
				freq = 44100.0 / (width * (44100.0 * m_tStatus_LFOclock));
			}
			if (m_tStatus_lfoDeltaMode == true) {
				widthSMP = (width * (spt * m_tStatus_lfoDeltaMgnf));
			}
			else {
				widthSMP = (width * Number(m_tStatus_lfoDelta));
			}
			m_tStatus_oscModL[target].setFrequency(freq);
			m_tStatus_oscModL[target].resetPhase();
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
					(MOscLNoiseW)(m_tStatus_oscSetLP.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( width );
					(MOscLTable)(m_tStatus_oscSetLP.getMod(MOscillatorL.TABLE)).setPShiftParam( width );
					(MOscLBendNL)(m_tStatus_oscSetLP.getMod(MOscillatorL.NONL_BEND)).setBendWidth( width );
					break;
				case TSTAT_LFO_TARGET_PANPOT:
					(MOscLNoiseW)(m_tStatus_oscSetLB.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( widthSMP );
					(MOscLTable)(m_tStatus_oscSetLB.getMod(MOscillatorL.TABLE)).setPShiftParam( widthSMP );
					(MOscLBendNL)(m_tStatus_oscSetLB.getMod(MOscillatorL.NONL_BEND)).setBendWidth( widthSMP );
					break;
				default:
					break;
			}
			
			// parameter set: delay
			if (delay >= 0.0) {
				if (m_tStatus_LFOclockMode == true) {
					m_tStatus_lfoDelay[target] = (delay * m_tStatus_LFOclockMgnf) * spt;
				}
				else {
					m_tStatus_lfoDelay[target] = delay * (44100.0 * m_tStatus_LFOclock);
				}
				m_tStatus_lfoDelta_seqCnt[target] = m_tStatus_lfoDelay[target];
			}
			else {
				m_tStatus_lfoDelay[target] = (-1.0);		//ノートオン非同期モード
				m_tStatus_lfoDelta_seqCnt[target] = 0.0;
			}
			
			// parameter set: attack（実装検討中）
			
			// parameter set: Y-func-Number
			
			//ＬＦＯディレイ用カウンタをクリア（タイ中のＬＦＯ再設定を想定）
			m_tStatus_onCounter = 0;
		}
		private function forStatus_refreshLFO(spt:Number):void {
			var paramA:Array;
			var width:Number;
			var freq:Number;
			var widthSMP:Number;
			var delay:Number;
			var target:int;
			
			for (target=0; target<TSTAT_LFO_MAX; target++){
				paramA = m_tStatus_lfoParam[target];
				if (paramA == null) { continue; }
				
				width = paramA[1];
				delay = paramA[4];
				
				// parameter set: width
				if (m_tStatus_LFOclockMode == true) {
					width = width * m_tStatus_LFOclockMgnf;
					freq = 44100.0 / (width * spt);
				}
				else {
					freq = 44100.0 / (width * (44100.0 * m_tStatus_LFOclock));
				}
				if (m_tStatus_lfoDeltaMode == true) {
					widthSMP = (width * (spt * m_tStatus_lfoDeltaMgnf));
				}
				else {
					widthSMP = (width * Number(m_tStatus_lfoDelta));
				}
				m_tStatus_oscModL[target].setFrequency(freq);
				m_tStatus_oscModL[target].resetPhase();
				switch (target) {
					case TSTAT_LFO_TARGET_PITCH:
						(MOscLNoiseW)(m_tStatus_oscSetLP.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( width );
						(MOscLTable)(m_tStatus_oscSetLP.getMod(MOscillatorL.TABLE)).setPShiftParam( width );
						(MOscLBendNL)(m_tStatus_oscSetLP.getMod(MOscillatorL.NONL_BEND)).setBendWidth( width );
						break;
					case TSTAT_LFO_TARGET_PANPOT:
						(MOscLNoiseW)(m_tStatus_oscSetLB.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( widthSMP );
						(MOscLTable)(m_tStatus_oscSetLB.getMod(MOscillatorL.TABLE)).setPShiftParam( widthSMP );
						(MOscLBendNL)(m_tStatus_oscSetLB.getMod(MOscillatorL.NONL_BEND)).setBendWidth( widthSMP );
						break;
					default:
						break;
				}
				
				// parameter set: delay
				if (delay >= 0.0) {
					if (m_tStatus_LFOclockMode == true) {
						m_tStatus_lfoDelay[target] = (delay * m_tStatus_LFOclockMgnf) * spt;
					}
					else {
						m_tStatus_lfoDelay[target] = delay * (44100.0 * m_tStatus_LFOclock);
					}
				}
				else {
					m_tStatus_lfoDelay[target] = (-1.0);		//ノートオン非同期モード
				}
			}
		}
		private function forStatus_setLFOrestart(target:int):void {
			var valid:Boolean;
			// target check
			switch (target) {
				case TSTAT_LFO_TARGET_PITCH:
				case TSTAT_LFO_TARGET_PANPOT:
					valid = true;
					break;
				default:
					valid = false;
			}
			if (valid == false) return;
			
			m_tStatus_oscModL[target].resetPhase();
			m_tStatus_onCounter = 0;
		}
		// for Track Status Disp. [end]----------------------------------------
		
		public function getNumEvents():int {
			return m_events.length;
		}
		
		public function onSampleData(samples:Vector.<Number>, start:int, end:int):void {
			if (isEnd()) return;
			//trace("start:"+start+",end:"+end);
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
							//trace("start:"+start+",end:"+end+","+n+"/mpt:"+m_pointer+"/global:"+(int)(m_globalTick/m_spt)+"/status:"+e.getStatus()+"/delta:"+delta+"-"+e.getDelta()+"/noteNo:"+e.getNoteNo());
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
								m_ch.setEnvSptUnit(m_spt);
								m_ch.setLfoSptUnit(m_spt);
								break;
							case MStatus.REST:
								break;
							case MStatus.NOTE_ON:
								m_noteOnPos = tickpos;
								m_ch.noteOn(e.getNoteNo(), (m_noteOnPos - m_noteOffPos));
								break;
							case MStatus.NOTE_OFF:
								m_noteOffPos = tickpos;
								m_ch.noteOff(e.getNoteNo());
								break;
							case MStatus.NOTE:
								m_ch.setNoteNo(e.getNoteNo());
								break;
							case MStatus.DETUNE:
								var dtrate:Number = e.getDetuneRate();
								if ((dtrate >= 10.0) && (dtrate <= 1000.0)) {
									m_pitchReso = dtrate;
								}
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
							case MStatus.OPTION_CLOCK:
								m_ch.setOptionClock(e.getOptionClockFunc(), e.getOptionClockMode(), e.getOptionClockNum());
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
								m_ch.setPortamento(Number(e.getPorDepth()) * m_pitchReso, Number(e.getPorLen()) * m_spt);
								break;
							case MStatus.MIDIPORT:
								m_ch.setMidiPort(e.getMidiPort());
								break;
							case MStatus.MIDIPORTRATE:
								m_ch.setMidiPortRate(e.getMidiPortRate());
								break;
							case MStatus.BASENOTE:
								m_ch.setPortBase(Number(e.getPortBase()) * m_pitchReso);
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
					//trace("start:"+start+ ",end:"+end+ ",n:"+n+ ",dn:"+dn);
					//trace("n:" + n + "/dn:" + dn);
					m_ch.getSamples(samples, end, int(n), int(dn));
					n += dn;
				}
				else {
					break;
				}
			}
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

		public function recDetune(d:Number, r:int):void {
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

		public function recVolume(vol:Number):void {
			var e:MEvent = makeEvent();
			e.setVolume(vol);
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

		public function recOptionClock(ocFunc:int, ocMode:int, ocNum:Number):void {
			var e:MEvent = makeEvent();
			e.setOptionClock(ocFunc, ocMode, ocNum);
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

		public function recOPMHwLfo(hmode:int, wf:int, freq:int, pmd:int, amd:int, pms:int, ams:int, syn:int):void {
			var e:MEvent = makeEvent();
			var params:int;
			params = 
				((hmode & 1) << 30) |
				((wf & 3) << 28) |
				((freq & 0x0ff) << 20) |
				((pmd & 0x7f) << 13) |
				((amd & 0x7f) << 6) |
				((pms & 7) << 3) |
				((ams & 3) << 1) |
				(syn & 1)
				;
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
			var spt:Number = calcSpt(MML.DEF_BPM);
			var i:int, j:int;
			var e:MEvent;
			for (i = 0; i < ni; i++) {
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
			//再生長取得のため、最も演奏時間の長いトラックのTicks数にtempoトラックを合わせる
			var maxGlobalTick:uint = 0;
			if (m_IRepeatF == false) {
				for (j = FIRST_TRACK; j < nj; j++) {
					if (maxGlobalTick < trackArr[j].getRecGlobalTick()) {
						maxGlobalTick = trackArr[j].getRecGlobalTick();
					}
				}
			}
			else {
				maxGlobalTick = trackArr[s_IRRequestLastTrack].getRecGlobalTick();		//無限リピート時の特例
			}
			
			var catchupGlobalTick:uint;
			catchupGlobalTick = (maxGlobalTick >= globalTick) ? globalTick : maxGlobalTick;		//必ず(maxGlobalTick >= globalTick)であるはずだが念のため
			m_delta = maxGlobalTick - catchupGlobalTick;
			m_globalTick = maxGlobalTick;
			
			e = makeEvent();
			e.setNOP();
			recGlobal(maxGlobalTick, e);
			globalSample += (Number(maxGlobalTick - globalTick) * spt);
			
			m_totalMSec = (globalSample * 1000.0) / 44100.0;
			
			m_spt_final = spt;		//テンポトラックのインスタンスにおける、トラック終端におけるsptを設定
			
			// MMLクラスのpost processにて、各トラックの終端処理を行う
		}
		public function conduct_skip(trackArr:Vector.<MTrack>, start:uint):void {
			var ni:int = m_events.length;
			var nj:int = trackArr.length;
			var globalTick:uint = 0;
			var globalSample:Number = 0.0;
			var spt:Number = calcSpt(MML.DEF_BPM);
			var tempo:Number = MML.DEF_BPM;
			var i:int, j:int;
			var e:MEvent;
			for (j = FIRST_TRACK; j < nj; j++) {
				trackArr[j].setSptForce(0.0);			//強制最高速度状態
				trackArr[j].forStatus_setSptForce(0.0);	//強制最高速度状態
			}
			//path 1
			for (i = 0; i < ni; i++) {
				e = m_events[i];
				globalTick += uint(e.getDelta());
				switch(e.getStatus()) {
					case MStatus.TEMPO:
						spt = calcSpt(e.getTempo());
						if (globalTick >= start) {
							for (j = FIRST_TRACK; j < nj; j++) {
								trackArr[j].recTempo(globalTick, e.getTempo());
							}
						}
						else {
							tempo = e.getTempo();
						}
						break;
					default:
						break;
				}
			}
			for (j = TEMPO_TRACK; j < nj; j++) {
				trackArr[j].recTempo(start, tempo);		//指定位置直前のテンポを、指定位置に埋め込み
			}
			//path 2
			ni = m_events.length;
			globalTick = 0;
			globalSample = 0.0;
			spt = calcSpt(MML.DEF_BPM);
			for (i = 0; i < ni; i++) {
				e = m_events[i];
				globalTick += uint(e.getDelta());
				if (globalTick > start) {
					globalSample += (Number(e.getDelta()) * spt);	//再生開始位置からの累積
				}
				switch(e.getStatus()) {
					case MStatus.TEMPO:
						spt = calcSpt(e.getTempo());
						break;
					default:
						break;
				}
			}
			//再生長取得のため、最も演奏時間の長いトラックのTicks数にtempoトラックを合わせる
			var maxGlobalTick:uint = 0;
			if (m_IRepeatF == false) {
				for (j = FIRST_TRACK; j < nj; j++) {
					if (maxGlobalTick < trackArr[j].getRecGlobalTick()) {
						maxGlobalTick = trackArr[j].getRecGlobalTick();
					}
				}
			}
			else {
				maxGlobalTick = trackArr[s_IRRequestLastTrack].getRecGlobalTick();		//無限リピート時の特例
			}
			
			var catchupGlobalTick:uint;
			catchupGlobalTick = (maxGlobalTick >= globalTick) ? globalTick : maxGlobalTick;		//必ず(maxGlobalTick >= globalTick)であるはずだが念のため
			m_delta = maxGlobalTick - catchupGlobalTick;
			m_globalTick = maxGlobalTick;
			
			e = makeEvent();
			e.setNOP();
			recGlobal(maxGlobalTick, e);
			globalSample += (Number(maxGlobalTick - globalTick) * spt);
			
			m_totalMSec = (globalSample * 1000.0) / 44100.0;
			
			m_spt_final = spt;		//テンポトラックのインスタンスにおける、トラック終端におけるsptを設定
			
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

		// skip再生時における samples per tick 強制設定（通常は使用しないこと）
		public function setSptForce(spt:Number):void {
			m_spt = spt;
		}

		public function getTotalMSec():Number {
			return m_totalMSec;
		}

		public function addTotalMSec(ticks:int):void {
			m_totalMSec += ( ((Number(ticks) * m_spt_final) * 1000.0) / 44100.0 );		//実行はテンポトラックのインスタンスでのみ行う
		}

		public function getTotalTimeStr():String {
			if (s_infiniteRepeatF == true) {
				return "infinity";
			}
			else {
				var sec:Number = Math.ceil(m_totalMSec / 1000.0);
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

		// 発音中のチャネル数を取得
		public function getVoiceCount():int {
			return m_ch.getVoiceCount();
		}
		
		// 確保中のチャネル数を取得
		public function getVoiceAllocNum():int {
			return m_ch_length;
		}
		
		// モノモードへ移行 (再生開始前に行うこと)
		public function usingMono():void {
			m_ch = new MChannel();
			m_ch_length = 1;
			m_ch.allocDelayBuffer(m_delayCountReq);
		}
		
		// ポリモードへ移行 (再生開始前に行うこと)
		public function usingPoly(maxVoice:int):void {
			m_ch = new MPolyChannel(maxVoice);
			m_ch_length = maxVoice;
			m_ch.allocDelayBuffer(m_delayCountReq);
		}
		
		// ポリ命令を１回でも使ったか？
		public function findPoly():Boolean {
			return m_polyFound;
		}
	}
}