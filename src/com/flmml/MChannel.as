package com.flmml {
	import __AS3__.vec.Vector;

	public class MChannel implements IChannel {
		public static const  NOTE_LIMIT_MAX:Number  = 120.0;		//o10c 以下のノートにする。o4a=440Hzのときo10c=16.7kHz
		public static const  NOTE_LIMIT_MIN:Number  = (-12.0);		//o(-1)c 以上のノートにする。o4a=440Hzのときo(-1)c=8.1758Hz
		public static var    s_BaseNote:Number      = 57.0;			//基準になる音階。o0c=0,o4c=48,o4a=57。メタデータから取得
		public static var    s_BaseFreq:Number      = 440.0;		//基準音階にあてがう周波数をいくつにするか。メタデータから取得
		public static var    s_LFOclockMode:Boolean = true;			//default:true。trueのとき、s_LFOclockは1tick（テンポ依存）。falseのとき、s_LFOclockは固定時間。
		public static var    s_LFOclockMgnf:Number  = 1.0;
		public static var    s_LFOclock:Number      = 1.0/120.0;
		public static var    s_lfoDeltaMode:Boolean = false;		//default:false。trueのとき、s_lfoDeltaは1tick（テンポ依存）。falseのとき、s_lfoDeltaは固定時間。
		public static var    s_lfoDeltaMgnf:Number  = 1.0;
		public static var    s_lfoDelta:int         = 147;			//245=1/180sec, 147=1/300sec, 105=1/420sec
		protected static var s_samples:Vector.<Number>;				//monaural sample buffer

		private static const LFO_TARGET_PITCH:int     = 0;
		private static const LFO_TARGET_AMPLITUDE:int = 1;
		private static const LFO_TARGET_FILTER:int    = 2;
		private static const LFO_TARGET_PANPOT:int    = 3;
		private static const LFO_TARGET_YCONTROL:int  = 4;
		private static const LFO_MAX:int              = 5;

		private static const ENV_F_TRIGGER_AMP:int    = 0x00000001;
		private static const ENV_F_TRIGGER_FIL:int    = 0x00000010;
		private static const ENV_F_TRIGGER_PWM:int    = 0x00000100;

		private var m_pitchReso:Number;			// 音程の分解能。半音を何分割にするかの数
		private var m_noteNo:int;
		private var m_detune:Number;
		private var m_freqNo:Number;
		private var m_envForceTrigger:int;
		private var m_envelope1:MEnvelope;		// for Amplitude
		private var m_envelope2:MEnvelope;		// for Filter
		private var m_envelope3:MEnvelope;		// for Pulse Width
		private var m_env3Connect:Boolean;		// PWM envelope : false=disable, true=enable

		private var m_oscSet1:MOscillator;		// for playing : wave rendering
		private var m_oscMod1:MOscMod;

		private var m_formReq:Boolean;
		private var m_subfReq:Boolean;
		private var m_phaseRMReq:Boolean;
		private var m_formNo:int;
		private var m_subfNo:int;
		private var m_phaseRMmode:int;
		private var m_phaseRMphase:Number;

		private var m_oscSetL0:MOscillatorL;		// for Pitch LFO
		private var m_oscSetL1:MOscillatorLA;		// for Amplitude LFO
		private var m_oscSetL2:MOscillatorL;		// for Filter LFO
		private var m_oscSetL3:MOscillatorL;		// for PanPot LFO
		private var m_oscSetL4:MOscillatorL;		// for Y-Control LFO
		private var m_oscModL:Vector.<MOscModL>;	// 使用波形モジュール
		private var m_oscLConnect:Vector.<int>;		// 有効・無効確認
		private var m_lfoDepth:Vector.<Number>;
		private var m_lfoDelay:Vector.<Number>;
		private var m_lfoInit:Array;
		private var m_lfoYfuncMod:int;
		private var m_lfoYfuncNum:int;

		private var m_filter:MFilter;
		private var m_filterConnect:int;
		private var m_lpfAmt:Number;
		private var m_lpfFrq:Number;
		private var m_lpfRes:Number;
		private var m_lpfInit:Array;
		private var m_formant:MFormant;

		private var m_mix_volume:Number;		// mixing volume
		private var m_vmode_max:Number;			// 音量値の最大
		private var m_vmode_index:Number;		// 現在の音量
		private var m_vmode_rate:Number;		// 最大音量からの減衰レート（０のとき線形、正のときｄＢ）
		private var m_vmode_vzmd:Boolean;		// ｄＢスケールの場合の v0 の処理モード。trueのときv0=無音。
		private var m_volume:Number;			// volume     (max:1.0)
		private var m_ampLevel:Number;			// amplifier level (max:1.0)

		private var m_pan:Number;				// (left)0.0 ... 0.5(center) ... 1.0(right)
		private var m_lgPan_L:Number;			// Legacy Panpot:Left ch. switch
		private var m_lgPan_R:Number;			// Legacy Panpot:Right ch. switch

		private var m_fadeMode:int;				//フェードアウトのモード。-1:無効。0:フェードアウト。1:フェードイン。
		private var m_fadeDyRange:Number;		//フェードアウトのダイナミックレンジ（dB）。０の場合リニア減衰。
		private var m_fadeCount:Number;			//フェードアウトの経過時間。単位はサンプル。1sec=44100
		private var m_fadeTotal:Number;			//フェードアウトの全体時間。単位はサンプル。1sec=44100

		private var m_delayMode:int;			//ディレイ効果のモード。0:無効。1:有効。
		private var m_delayBufSize:int;			//ディレイ効果用リングバッファのサイズ。遅延時間[単位samples]でもある。
		private var m_delayPrepare:int;			//ディレイ効果開始指示から効果開始までの準備用ダウンカウンタ。
		private var m_delayWrIndex:int;			//ディレイ効果の書き込み位置。
		private var m_delayAmpLv:Number;
		private var m_delayVal_L:Number;
		private var m_delayVal_R:Number;
		private var m_delayBufL:Vector.<Number>;
		private var m_delayBufR:Vector.<Number>;

		private var m_onCounter:int;			// NoteONからの経過サンプル数(44100Hz)
		private var m_pulseWidth:Number;

		private var m_portDepth:Number;
		private var m_portDepthAdd:Number;
		private var m_portamento:int;
		private var m_portRate:Number;
		private var m_lastFreqNo:Number;

		private var m_voiceid:int;			// ボイスID for Poly

		public function MChannel() {
			m_pitchReso = MML.DEF_DETUNE_RESO;
			m_noteNo = 0;
			m_detune = 0.0;
			m_freqNo = 0.0;
			// env1:amp, env2:filter, env3:pwm
			m_envelope1 = new MEnvelope(1, 1.0,1.0, 180.0,0.0, 1.0,0.0);
			m_envelope2 = new MEnvelope(2, 1.0,1.0, 120.0,0.0, 1.0,0.0);
			m_envelope3 = new MEnvelope(3, 0.0,0.5,   0.0,0.5, 1.0,0.5);
			m_env3Connect = false;
			// wave rendering
			m_oscSet1  = new MOscillator();
			m_oscMod1  = m_oscSet1.getCurrent();
			m_formReq  = false;
			m_subfReq  = false;
			m_phaseRMReq = false;
			m_formNo   = MML.DEF_FORM;
			m_subfNo   = MML.DEF_SUBFORM;
			m_phaseRMmode = 1;
			m_phaseRMphase = 0.0;
			// MixingVol/Volume/Expression parameter stand by
			m_mix_volume    = 1.0;
			m_volume        = 1.0;
			m_vmode_rate    = MML.DEF_VSRATE;
			m_vmode_max     = Number(MML.DEF_VSMAX);
			m_vmode_index   = Number(MML.DEF_VSMAX);			//スタンバイ時は最大。m_volumeの初期値との整合性のため。
			m_vmode_vzmd    = true;
			// LFO stand by
			m_oscSetL0 = new MOscillatorL();
			m_oscSetL1 = new MOscillatorLA();
			m_oscSetL2 = new MOscillatorL();
			m_oscSetL3 = new MOscillatorL();
			m_oscSetL4 = new MOscillatorL();
			m_oscModL = new Vector.<MOscModL>(LFO_MAX);
			m_oscLConnect = new Vector.<int>(LFO_MAX);
			m_lfoDepth = new Vector.<Number>(LFO_MAX);
			m_lfoDelay = new Vector.<Number>(LFO_MAX);
			m_lfoInit  = new Array(0.0, 1.0, 0, 0, 0.0);			//depth, width, form, subform, delay
			// Pitch LFO
			m_oscSetL0.setForm(MOscillatorL.SINE);
			m_oscModL[LFO_TARGET_PITCH] = m_oscSetL0.getCurrent();
			m_oscModL[LFO_TARGET_PITCH].setWaveNo(0);
			m_oscLConnect[LFO_TARGET_PITCH] = 0;
			// Amplitude LFO
			m_oscSetL1.setForm(MOscillatorLA.SINE);
			m_oscModL[LFO_TARGET_AMPLITUDE] = m_oscSetL1.getCurrent();
			m_oscModL[LFO_TARGET_AMPLITUDE].setWaveNo(0);
			m_oscLConnect[LFO_TARGET_AMPLITUDE] = 0;
			// Filter LFO
			m_oscSetL2.setForm(MOscillatorL.SINE);
			m_oscModL[LFO_TARGET_FILTER] = m_oscSetL2.getCurrent();
			m_oscModL[LFO_TARGET_FILTER].setWaveNo(0);
			m_oscLConnect[LFO_TARGET_FILTER] = 0;
			// PanPot LFO
			m_oscSetL3.setForm(MOscillatorL.SINE);
			m_oscModL[LFO_TARGET_PANPOT] = m_oscSetL3.getCurrent();
			m_oscModL[LFO_TARGET_PANPOT].setWaveNo(0);
			m_oscLConnect[LFO_TARGET_PANPOT] = 0;
			// Y-Control LFO
			m_oscSetL4.setForm(MOscillatorL.TABLE);
			m_oscModL[LFO_TARGET_YCONTROL] = m_oscSetL4.getCurrent();
			m_oscModL[LFO_TARGET_YCONTROL].setWaveNo(0);
			m_oscLConnect[LFO_TARGET_YCONTROL] = 0;
			m_lfoYfuncMod = MOscillator.PULSE;
			m_lfoYfuncNum = 0;
			// Filter
			m_filter = new MFilter();
			m_filterConnect = 0;
			m_formant = new MFormant();
			m_lpfAmt   = 0;
			m_lpfFrq   = 0;
			m_lpfRes   = 0;
			m_lpfInit  = new Array(0.0, 0.0, 0.0);
			// delay effect
			allocDelayBuffer(0);		//ディレイエフェクト無効状態で初期化（バッファはnullを指示。使用時に確保指示）
			// パラメータのリセット
			resetParam();
		}
		public function resetParam():void {
			m_voiceid = 0;
			setFormDirect(MML.DEF_FORM, MML.DEF_SUBFORM);
			setPWM(0.5, 0);
			setDetune(0, MML.DEF_DETUNE_RESO);
			m_envForceTrigger = 0;
			// 音量
			setMixingVolume(MML.DEF_MIXVOL);				//setMixingVolume()を初めて呼ぶ場合に必ずm_volumeとm_vmode_rateをセットしておく。
			setVolMode(MML.DEF_VSMAX, MML.DEF_VSRATE, 0);	//setVolMode()を初めて呼ぶ場合に必ずsetMixingVolume()を行っておく。
			setVolume(MML.DEF_VOL);							//setVolume()を初めて呼ぶ場合に必ずsetVolMode()を行っておく。
			setPan(0.0);
			setPanLegacy(0);
			// ノイズ周波数
			setYControl(MOscillator.NOISE_W,   5, 1.0);		//Noise Freq.
			setYControl(MOscillator.NOISE_FC,  5, 0.0);
			setYControl(MOscillator.NOISE_GB,  5, 0.0);
			setYControl(MOscillator.NOISE_PSG, 5, 1.0);
			// LFO
			m_onCounter = 0;
			setLFO(LFO_TARGET_PITCH, m_lfoInit, 1.0);
			setLFO(LFO_TARGET_AMPLITUDE, m_lfoInit, 1.0);
			setLFO(LFO_TARGET_FILTER, m_lfoInit, 1.0);
			setLFO(LFO_TARGET_PANPOT, m_lfoInit, 1.0);
			setLFO(LFO_TARGET_YCONTROL, m_lfoInit, 1.0);
			// フィルタ
			setLPF(0, m_lpfInit);
			setFormant(-1);
			// ポルタメント
			m_portDepth     = 0.0;
			m_portDepthAdd  = 0.0;
			m_lastFreqNo    = 0.0;
			m_portamento    = 0;
			m_portRate      = 0.0;
			// エフェクト
			setFade(1.0, 0.0, -1);		//mode:-1（フェード無効）
		}
		public static function boot(numSamples:int):void {
			s_samples = new Vector.<Number>(numSamples);
			s_samples.fixed = true;
		}
		public function getFrequency(freqNo:Number):Number {
			var freqIdx:Number = freqNo;
			var freq:Number;
			if (freqIdx < (NOTE_LIMIT_MIN * m_pitchReso)) {
				freqIdx = (NOTE_LIMIT_MIN * m_pitchReso);
			}
			else if (freqIdx > (NOTE_LIMIT_MAX * m_pitchReso)) {
				freqIdx = (NOTE_LIMIT_MAX * m_pitchReso);
			}
			freq = s_BaseFreq * Math.pow(2.0, ( (freqIdx - (s_BaseNote * m_pitchReso)) / (12.0 * m_pitchReso) ) );
			return freq;
		}
		private function setPitchResolution(reso:int):void {
			if ((reso >= 10) && (reso <= 1000)) {
				m_pitchReso = Number(reso);
			}
		}
		public function isPlaying():Boolean {
			if (m_oscSet1.getForm() == MOscillator.OPMS) {
				return ((MOscOPMS)(m_oscSet1.getCurrent())).IsPlaying();
			}
			else {
				return m_envelope1.isPlaying();
			}
		}
		public function getId():int {
			return m_voiceid;
		}
		public function getVoiceCount():int {
			return isPlaying() ? 1 : 0;
		}
		public function noteOnWidthId(noteNo:int, id:int, pdif:uint):void {
			m_voiceid = id;
			noteOn(noteNo,pdif);
		}
		private function setEnvForceTrigger():void {
			if ((m_envForceTrigger & ENV_F_TRIGGER_AMP) != 0) {
				m_oscMod1.setPlayingInfo(0,isPlaying());
				m_envelope1.triggerEnvelope();
				m_oscMod1.resetPhase();
			}
			if ((m_envForceTrigger & ENV_F_TRIGGER_FIL) != 0) {
				m_envelope2.triggerEnvelope();
			}
			if ((m_envForceTrigger & ENV_F_TRIGGER_PWM) != 0) {
				m_envelope3.triggerEnvelope();
			}
			m_envForceTrigger = 0;
		}
		public function noteOn(noteNo:int,pdif:uint):void {
			var i:int;
			//for note
			m_envForceTrigger = 0;			//通常ノートオンでは強制トリガ要求を無効化。タイ中のみ強制トリガ要求を受け付けるため。
			setNoteNo(noteNo, false);						//事前バッファされた音色指定、位相リセットモード指定なども反映される
			m_oscMod1.setPlayingInfo(pdif,isPlaying());		//ここで通知するisPlaying()は、ノートオン直前の状態
			m_oscMod1.resetPhase();
			//for LFO
			((MOscLTable)(m_oscModL[LFO_TARGET_YCONTROL])).setWaveNo1st();
			for (i = 0; i < LFO_MAX; i++) {
				if (m_lfoDelay[i] >= 0.0) {
					m_oscModL[i].resetPhase();
				}
			}
			m_onCounter = 0;
			//for ENVELOPE
			m_envelope1.triggerEnvelope();
			m_envelope2.triggerEnvelope();
			m_envelope3.triggerEnvelope();
			m_oscSet1.getMod(MOscillator.SMP_DPCM  ).setNoteNo(m_noteNo);
			((MOscOPMS)(m_oscSet1.getMod(MOscillator.OPMS))).noteOn();
			//for Filter
			m_filter.reset();
		}
		public function noteOff(noteNo:int):void {
			if (noteNo < 0 || noteNo == m_noteNo) {
				m_envelope1.releaseEnvelope();
				m_envelope2.releaseEnvelope();
				m_envelope3.releaseEnvelope();
				((MOscOPMS)(m_oscSet1.getMod(MOscillator.OPMS))).noteOff();
				((MOscLTable)(m_oscModL[LFO_TARGET_YCONTROL])).setWaveNo2nd();
			}
		}
		public function setNoteNo(noteNo:int, tie:Boolean = true):void {
			setFormOnNote();
			setSubFormOnNote();
			setPhaseRModeOnNote();
			setEnvForceTrigger();

			m_noteNo = noteNo;
			m_freqNo = (Number(m_noteNo) * m_pitchReso) + m_detune;
			m_oscMod1.setFrequency(getFrequency(m_freqNo));

			if (m_portamento == 1) {
				if (!tie) {
					m_portDepth = (m_lastFreqNo - m_freqNo);
				}
				else {
					m_portDepth += (m_lastFreqNo - m_freqNo);
				}
				m_portDepthAdd = (m_portDepth < 0.0) ? m_portRate : (m_portRate * (-1.0));
			}
			m_lastFreqNo = m_freqNo;
		}
		public function setDetune(detune:Number, rate:int):void {
			m_detune = detune;
			setPitchResolution(rate);
			m_freqNo = (Number(m_noteNo) * m_pitchReso) + m_detune;
			m_oscMod1.setFrequency(getFrequency(m_freqNo));
			// m_freqNo に制限は掛けないが、getFrequency(m_freqNo) で得られる周波数には最大最小制限が掛かる
		}
		public function getNoteNo():int {
			return m_noteNo;
		}
		public function setEnvTimeUnit(spt:Number):void {
			var envclk:Number;
			if (MEnvelope.s_envClockMode == true) {
				envclk = ((spt * MEnvelope.s_envClockMgnf) / 44100.0);
				if (envclk < (44.1 / 44100.0)) envclk = 44.1 / 44100.0;		//超高速モードにつきあう限界
				MEnvelope.s_envClock = envclk;								//エンベロープ時間単位の追従
			}
			if (MEnvelope.s_envResolMode == 1) {
				envclk = (spt * MEnvelope.s_envResolMgnf);
				if (envclk < 44.1) envclk = 44.1;							//tick依存モードの解像度は1msを下限とする
				MEnvelope.s_envResol = envclk;
			}
		}
		public function setLfoResolution(spt:Number):void {
			var lforeso:int;
			if (s_lfoDeltaMode == true) {
				lforeso = int(spt * s_lfoDeltaMgnf);
				if (lforeso < 147) lforeso = 147;							//超高速モードにつきあう限界
				s_lfoDelta = lforeso;										//ＬＦＯ解像度の追従
			}
		}
		public function setMixingVolume(m_vol:Number):void {
			var val:Number = m_vol;
			if (m_vol > (-100.0)) {
				if (m_vol > 24.0) { val = 24.0;  }		//利得24dBまで。
				else              { val = m_vol; }
				m_mix_volume = Math.pow(10.0, (val / 20.0));
			}
			else {
				//-100.0dB以下の指定は無音とみなす
				m_mix_volume = 0.0;
			}
			
			m_ampLevel = m_mix_volume * m_volume;
			((MOscOPMS)(m_oscSet1.getMod(MOscillator.OPMS))).setVolume(m_ampLevel); // 利得を含むゲイン
		}
		public function setVolMode(max:int, rate:Number, mode:int):void {
			m_vmode_max  = Number(max);
			m_vmode_rate = rate;
			m_vmode_vzmd = (mode == 0) ? true : false;
			if ( m_vmode_max < 3.0 )  m_vmode_max  = 3.0;
			if ( m_vmode_rate < 0.0 ) m_vmode_rate = 0.0;
			m_vmode_index = m_vmode_max;
			setVolume(m_vmode_max);
		}
		public function setVolume(vol:Number):void {
			m_vmode_index = vol;
			if (m_vmode_index < 0.0)         m_vmode_index = 0.0;
			if (m_vmode_index > m_vmode_max) m_vmode_index = m_vmode_max;
			if (m_vmode_rate == 0.0) {
				//線形
				m_volume = m_vmode_index / m_vmode_max;
				if (m_volume > 1.0) m_volume = 1.0;
				if (m_volume < 0.0) m_volume = 0.0;
			}
			else {
				//ｄＢ
				if ((m_vmode_index > 0) || (m_vmode_vzmd == false)) {
					m_volume = Math.pow( 10.0, (((m_vmode_index - m_vmode_max) * m_vmode_rate) / 20.0) );
					if (m_volume > 1.0) m_volume = 1.0;
				}
				else {
					//(m_vmode_index == 0) && (m_vmode_vzmd == true) の場合
					m_volume = 0.0;
				}
			}
			//m_mix_volumeとの乗算結果には上限制限しないでおく（利得を含むため）。
			m_ampLevel = m_mix_volume * m_volume;
			if (m_ampLevel < 0.0) m_ampLevel = 0.0;
			((MOscOPMS)(m_oscSet1.getMod(MOscillator.OPMS))).setVolume(m_ampLevel);		//利得を含む m_ampLevel を与える
		}
		public function setPan(pan:Number):void {
			// left -100.0 - 0.0 - 100.0 right
			// master_vol = (0.25 * 2) 強制0.5倍の上、pan中心で0.5倍。最大偏ると片方が０で片方が1.0倍なのでmaster_volが0.5相当
			// m_pan : full-left=0.0,  center=0.5, full-right=1.0;
			m_pan = (pan + 100.0) / 200.0;
			if (m_pan < 0.0) m_pan = 0.0;
			if (m_pan > 1.0) m_pan = 1.0;
		}
		public function setPanLegacy(lgPan:int):void {
			// left -1 ... 0 ... 1 right
			if (lgPan == 0) {
				m_lgPan_L = 1.0;
				m_lgPan_R = 1.0;
			}
			else if (lgPan == (-1)) {
				m_lgPan_L = 1.0;
				m_lgPan_R = 0.0;
			}
			else if (lgPan == 1) {
				m_lgPan_L = 0.0;
				m_lgPan_R = 1.0;
			}
			else {
				m_lgPan_L = 1.0;
				m_lgPan_R = 1.0;
			}
		}
		public function setForm(form:int, sub:int):void {
			if ((form >= 0) && (form < MOscillator.MAX)) {
				m_formNo  = form;
				m_subfNo  = sub;
				m_formReq = true;
			}
		}
		public function setSubForm(subform:int):void {
			m_subfNo  = subform;
			m_subfReq = true;
		}
		public function setPhaseRMode(mode:int, phase:Number):void {
			m_phaseRMmode = mode;
			m_phaseRMphase = phase;
			m_phaseRMReq = true;
		}
		private function setFormOnNote():void {
			if (m_formReq == true) {
				m_oscMod1 = m_oscSet1.setForm(m_formNo);
				m_oscMod1.setWaveNo(m_subfNo);
				m_formReq = false;
			}
		}
		private function setSubFormOnNote():void {
			if (m_subfReq == true) {
				m_oscMod1.setWaveNo(m_subfNo);
				m_subfReq = false;
			}
		}
		private function setPhaseRModeOnNote():void {
			if (m_phaseRMReq == true) {
				m_oscMod1.setPhaseResetMode(m_phaseRMmode, m_phaseRMphase);
				m_phaseRMReq = false;
			}
		}
		private function setFormDirect(form:int, sub:int):void {
			m_oscMod1 = m_oscSet1.setForm(form);
			m_oscMod1.setWaveNo(sub);
		}
		public function setEnvelope(dest:int, lvRd_mode:int, atk_mode:Boolean, initlevel:Number, evPoints:Array):void {
			var i:int;
			var len:int;
			var MEnv:MEnvelope;
			var p_mode:int;
			var r_mode:Boolean;
			var rate:Number;
			var level:Number;

			switch(dest) {
			case 1:
			default:
				MEnv = m_envelope1;
				m_envForceTrigger |= ENV_F_TRIGGER_AMP;
				break;
			case 2:
				MEnv = m_envelope2;
				m_envForceTrigger |= ENV_F_TRIGGER_FIL;
				break;
			case 3:
				MEnv = m_envelope3;
				m_envForceTrigger |= ENV_F_TRIGGER_PWM;
				break;
			}

			len = evPoints.length;
			MEnv.newPoint(dest, initlevel, atk_mode, lvRd_mode);

			for (i = 0; i < len; i++) {
				p_mode = evPoints[i].pt_mode;
				r_mode = evPoints[i].rt_mode;
				rate   = evPoints[i].rate;
				level  = evPoints[i].level;
				MEnv.addPoint(dest, r_mode, rate, level, p_mode);
			}
		}
		public function setLFO(target:int, paramA:Array, spt:Number):void {
			var valid:Boolean;
			
			var depth:Number  = paramA[0];
			var width:Number  = paramA[1];
			var form:int      = paramA[2];		//YCONTROLではYControl-Mod(16bit)/YControl-Num(16bit)
			var subform:int   = paramA[3];		//YCONTROLではsubform1(16bit)/subform2(16bit)
			var delay:Number  = paramA[4];
			
			var dp:Number;
			var sign:Number;
			var freq:Number;
			var widthSMP:Number;
			var i:int, j:int;
			
			// target check
			switch (target) {
			case LFO_TARGET_PITCH:
			case LFO_TARGET_AMPLITUDE:
			case LFO_TARGET_FILTER:
			case LFO_TARGET_PANPOT:
			case LFO_TARGET_YCONTROL:
				valid = true;
				break;
			default:
				valid = false;
			}
			if (valid == false) return;

			// parameter check
			if (depth == 0.0) {
				m_oscLConnect[target] = 0;
			}
			else {
				m_oscLConnect[target] = 1;
			}
			if ( (width == 0.0) || (spt == 0.0) || (s_LFOclock == 0.0) || (s_LFOclockMgnf == 0.0) ) {
				m_oscLConnect[target] = 0;
			}
			switch (target) {
			case LFO_TARGET_PITCH:
				if (form >= MOscillatorL.MAX) m_oscLConnect[target] = 0;
				break;
			case LFO_TARGET_AMPLITUDE:
				if (form >= MOscillatorLA.MAX) m_oscLConnect[target] = 0;
				break;
			case LFO_TARGET_FILTER:
				if (form >= MOscillatorL.MAX) m_oscLConnect[target] = 0;
				break;
			case LFO_TARGET_PANPOT:
				if (form >= MOscillatorL.MAX) m_oscLConnect[target] = 0;
				break;
			case LFO_TARGET_YCONTROL:
				i = (form >> 16) & 0x0ffff;								//Y-Controlのtargetモジュール番号
				if (i >= MOscillator.MAX) m_oscLConnect[target] = 0;	//MOscillatorL.MAXではなくMOscillator.MAXであることに注意
				break;
			default:
				break;
			}
			if (m_oscLConnect[target] == 0) {
				return;
			}

			// parameter set: depth
			dp = Math.abs(depth);
			sign = depth / dp;
			switch (target) {
			case LFO_TARGET_PITCH:
				m_lfoDepth[target] = depth;
				break;
			case LFO_TARGET_AMPLITUDE:
				if (dp > Number(m_vmode_max)) dp = Number(m_vmode_max);
				m_lfoDepth[target] = dp * sign;
				break;
			case LFO_TARGET_FILTER:
				if (dp > 100.0) dp = 100.0;
				dp = dp / 100.0;
				m_lfoDepth[target] = dp * sign;
				break;
			case LFO_TARGET_PANPOT:
				if (dp > 200.0) dp = 200.0;
				dp = dp * (0.5 / 100.0);		//m_panは0.5中心の0.0～1.0推移のため、振幅0.5のスケールに合わせる。
				m_lfoDepth[target] = dp * sign;
				break;
			case LFO_TARGET_YCONTROL:
				m_lfoDepth[target] = depth;
				break;
			default:
				break;
			}

			// parameter set: form/subform
			switch (target) {
			case LFO_TARGET_PITCH:
				m_oscModL[target] = m_oscSetL0.setForm(form);
				m_oscModL[target].setWaveNo(subform);
				break;
			case LFO_TARGET_AMPLITUDE:
				m_oscModL[target] = m_oscSetL1.setForm(form);
				m_oscModL[target].setWaveNo(subform);
				break;
			case LFO_TARGET_FILTER:
				m_oscModL[target] = m_oscSetL2.setForm(form);
				m_oscModL[target].setWaveNo(subform);
				break;
			case LFO_TARGET_PANPOT:
				m_oscModL[target] = m_oscSetL3.setForm(form);
				m_oscModL[target].setWaveNo(subform);
				break;
			case LFO_TARGET_YCONTROL:
				m_oscModL[target] = m_oscSetL4.setForm(MOscillatorL.TABLE);		//テーブルシーケンスに固定
				i = (subform >> 16) & 0x0ffff;
				j = (subform) & 0x0ffff;
				if (j == 0x0ffff) j = (-1);
				m_oscModL[target].setWaveNoForSwitchCtrl(i,j);
				break;
			default:
				break;
			}

			// parameter set: width
			if (s_LFOclockMode == true) {
				width = width * s_LFOclockMgnf;
				freq = 44100.0 / (width * spt);
			}
			else {
				freq = 44100.0 / (width * (44100.0 * s_LFOclock));
			}
			if (s_lfoDeltaMode == true) {
				widthSMP = (width * (spt * s_lfoDeltaMgnf));
			}
			else {
				widthSMP = (width * Number(s_lfoDelta));
			}
			m_oscModL[target].setFrequency(freq);
			m_oscModL[target].resetPhase();
			switch (target) {
			case LFO_TARGET_PITCH:
				(MOscLNoiseW)(m_oscSetL0.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( width );
				(MOscLTable)(m_oscSetL0.getMod(MOscillatorL.TABLE)).setPShiftParam( width );
				(MOscLBendNL)(m_oscSetL0.getMod(MOscillatorL.NONL_BEND)).setBendWidth( width );
				break;
			case LFO_TARGET_AMPLITUDE:
				(MOscLNoiseWA)(m_oscSetL1.getMod(MOscillatorLA.NOISE_W)).setNoiseFreq( widthSMP );
				(MOscLTable)(m_oscSetL1.getMod(MOscillatorLA.TABLE)).setPShiftParam( widthSMP );
				break;
			case LFO_TARGET_FILTER:
				(MOscLNoiseW)(m_oscSetL2.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( width );
				(MOscLTable)(m_oscSetL2.getMod(MOscillatorL.TABLE)).setPShiftParam( width );
				(MOscLBendNL)(m_oscSetL2.getMod(MOscillatorL.NONL_BEND)).setBendWidth( width );
				break;
			case LFO_TARGET_PANPOT:
				(MOscLNoiseW)(m_oscSetL3.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( widthSMP );
				(MOscLTable)(m_oscSetL3.getMod(MOscillatorL.TABLE)).setPShiftParam( widthSMP );
				(MOscLBendNL)(m_oscSetL3.getMod(MOscillatorL.NONL_BEND)).setBendWidth( widthSMP );
				break;
			case LFO_TARGET_YCONTROL:
				(MOscLNoiseW)(m_oscSetL4.getMod(MOscillatorL.NOISE_W)).setNoiseFreq( width );
				(MOscLTable)(m_oscSetL4.getMod(MOscillatorL.TABLE)).setPShiftParam( width );
				(MOscLBendNL)(m_oscSetL4.getMod(MOscillatorL.NONL_BEND)).setBendWidth( width );
				break;
			default:
				break;
			}

			// parameter set: delay
			if (delay >= 0.0) {
				if (s_LFOclockMode == true) {
					m_lfoDelay[target] = (delay * s_LFOclockMgnf) * spt;
				}
				else {
					m_lfoDelay[target] = delay * (44100.0 * s_LFOclock);
				}
			}
			else {
				m_lfoDelay[target] = (-1.0);		//ノートオン非同期モード
			}

			// parameter set: attack（実装検討中）

			// parameter set: Y-func-Number
			switch (target) {
			case LFO_TARGET_YCONTROL:
				i = (form >> 16) & 0x0ffff;
				j = (form) & 0x0ffff;
				m_lfoYfuncMod = i;
				m_lfoYfuncNum = j;
				break;
			default:
				break;
			}

			//ＬＦＯディレイ用カウンタをクリア（タイ中のＬＦＯ再設定を想定）
			m_onCounter = 0;
		}
		public function setLFOrestart(target:int):void {
			var valid:Boolean;
			// target check
			switch (target) {
				case LFO_TARGET_PITCH:
				case LFO_TARGET_AMPLITUDE:
				case LFO_TARGET_FILTER:
				case LFO_TARGET_PANPOT:
				case LFO_TARGET_YCONTROL:
					valid = true;
					break;
				default:
					valid = false;
			}
			if (valid == false) return;
			
			m_oscModL[target].resetPhase();
			m_onCounter = 0;
		}
		public function setLPF(swt:int, paramA:Array):void {
			var amt:Number = paramA[0];
			var frq:Number = paramA[1];
			var res:Number = paramA[2];
			// swt
			if ((-3 < swt) && (swt < 3) && (swt != m_filterConnect)) {
				m_filterConnect = swt;
				m_filter.setSwitch(swt);
			}
			// amt
			if (amt <= -100.0) {
				m_lpfAmt = -1.0;
			}
			else if (amt >= 100.0) {
				m_lpfAmt = 1.0;
			}
			else {
				m_lpfAmt = (amt / 100.0);
			}
			// frq
			if (frq <= 40.0) {
				m_lpfFrq = 40.0 / 44100.0;
			}
			else if (frq >= 44100.0) {
				m_lpfFrq = 1.0;
			}
			else {
				m_lpfFrq = frq / 44100.0;
			}
			// res
			if (res <= 0.0) {
				m_lpfRes = 0.0;
			}
			else if (res >= 100.0) {
				m_lpfRes = 1.0;
			}
			else {
				m_lpfRes = (res / 100.0);
			}
		}
		public function setFormant(vowel:int):void {
			if (vowel >= 0) m_formant.setVowel(vowel);
			else m_formant.disable();
		}
		public function setPWM(pwm:Number, mode:int):void {
			if (mode == 0) {
				m_env3Connect = false;
				m_pulseWidth = pwm;
				(MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE)).setPWM(m_pulseWidth);
			}
			else {
				m_env3Connect = true;
			}
		}
		public function setOPMHwLfo(data:int):void {
			var hmd:int = (data>>30) & 0x01;
			var w:int   = (data>>28) & 0x03;
			var f:int   = (data>>20) & 0x0FF;
			var pmd:int = (data>>13) & 0x7F;
			var amd:int = (data>> 6) & 0x7F;
			var pms:int = (data>> 3) & 0x07;
			var ams:int = (data>> 1) & 0x03;
			var syn:int = (data    ) & 0x01;
			var fms:MOscOPMS = ((MOscOPMS)(m_oscSet1.getMod(MOscillator.OPMS)));
			fms.setHLFOMODE(hmd);
			if (hmd == 0) {
				fms.setWF(w);
				fms.setLFRQ(f);
				fms.setPMD(pmd);
				fms.setAMD(amd);
				fms.setPMSAMS( ((pms<<4)|ams) );
				fms.setSYNC(syn);
			}
			else {
				fms.setLFRQa(f);
				fms.setAMSPMSa( ((ams<<4)|pms) );
				fms.setSYNCa(syn);
			}
		}
		public function setYControl(m:int, f:int, n:Number):void {
			if ((m >= 0) && (m < MOscillator.MAX)) {
				(m_oscSet1.getMod(m)).setYControl(m,f,n);
			}
		}
		public function setPortamento(depth:Number, len:Number):void {
			m_portamento = 0;
			m_portDepth = depth;
			m_portDepthAdd = (m_portDepth / len) * (-1.0);		//ポルタメント終了まで m_portDepth * m_portDepthAdd は負数
		}
		public function setMidiPort(mode:int):void {
			m_portamento = mode;
			m_portDepth = 0.0;
		}
		public function setMidiPortRate(rate:int):void {
			if (rate > 0) {
				m_portRate = (8.0 - (Number(rate) * 7.99 / 128.0)) / Number(rate);
			}
			else {
				m_portRate = 0.0;
			}
		}
		public function setPortBase(base:Number):void {
			m_lastFreqNo = base;
		}
		public function setVoiceLimit(voiceLimit:int) : void {
			// [MStatus.POLY] 無視
		}
		public function setFade(time:Number, range:Number, mode:int):void {
			var t:Number = time;
			var r:Number = range;
			if (t < 0.005) t = 0.005;
			if (r > 0.0)   r = 0.0;
			if (r < (-110.0)) r = (-110.0);
			if (mode == 0 || mode == 1) {
				m_fadeMode    = mode;
				m_fadeTotal   = Math.round(t * 44100.0);
				m_fadeCount   = 0.0;
				m_fadeDyRange = r;
			}
			else {
				m_fadeMode    = (-1);
				m_fadeTotal   = 44100.0;
				m_fadeCount   = 0.0;
				m_fadeDyRange = 0.0;
			}
		}
		public function allocDelayBuffer(reqbuf:int):void {
			var size:int = reqbuf;
			if (size >= MML.DEF_MIN_DELAY_CT) {
				size += 4;		//保険
				m_delayBufL = new Vector.<Number>(size);
				m_delayBufR = new Vector.<Number>(size);
			}
			else {
				m_delayBufL = null;
				m_delayBufR = null;
			}
			setDelay(0, 1.0);
		}
		public function setDelay(cnt:int, lv:Number):void {
			if (m_delayMode == 1) {
				//既にディレイエフェクト稼働中で、現在と同内容での再設定要求は無視する
				if ((m_delayBufSize == cnt) && (m_delayAmpLv == lv)) {
					return;
				}
			}
			if (cnt >= MML.DEF_MIN_DELAY_CT) {
				m_delayMode = 1;
				m_delayWrIndex = 0;
				m_delayBufSize = cnt;
				m_delayPrepare = m_delayBufSize;
				m_delayAmpLv = lv;
				m_delayVal_L = 0.0;
				m_delayVal_R = 0.0;
			}
			else {
				m_delayMode = 0;
				m_delayWrIndex = 0;
				m_delayBufSize = 0;
				m_delayPrepare = m_delayBufSize;
				m_delayAmpLv = 0.0;
				m_delayVal_L = 0.0;
				m_delayVal_R = 0.0;
			}
		}
		public function culcDelay(inputL:Number, inputR:Number):void {
			var now_p:int;
			var next_p:int;
			//現在と過去のポインタをあらかじめ把握し、先に次回ポインタの準備も終わらせておく
			now_p = m_delayWrIndex;
			next_p = now_p + 1;
			if (next_p >= m_delayBufSize) next_p = 0;
			m_delayWrIndex = next_p;
			
			if (m_delayPrepare > 0) {
				//リングバッファ１周目（ディレイ指示直後）は、ディレイ無効
				m_delayPrepare--;
				m_delayVal_L = inputL;
				m_delayVal_R = inputR;
			}
			else {
				//リングバッファの最も古いサンプルをディレイ値として加算
				m_delayVal_L = inputL + m_delayBufL[next_p];
				m_delayVal_R = inputR + m_delayBufR[next_p];
			}
			m_delayBufL[now_p] = m_delayVal_L * m_delayAmpLv;
			m_delayBufR[now_p] = m_delayVal_R * m_delayAmpLv;
		}
		public function close():void {
			noteOff(m_noteNo);
			m_filter.setSwitch(0);
		}
		public function setSoundOff():void {
			m_envelope1.soundOff();
			m_envelope2.soundOff();
		}
		public function reset():void {
			// 基本
			setSoundOff();
			resetParam();
		}

		public function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void {
			var end:int = start + delta;
			var s:int, e:int;
			var trackBuffer:Vector.<Number> = s_samples;
			var playing:Boolean = isPlaying();
			var tmpFlag:Boolean;
			var freqNo:Number;
			var depth:Number, depth2:Number;
			var vol:Number, Vscale:Number, Vrate:Number;
			var lpffrq:Number;
			var key:Number = getFrequency(m_freqNo);
			var pan:Number;
			var amplitude:Number, rightAmplitude:Number;
			var i:int, j:int;
			var onCounter:int;

			if (end >= max) end = max;

			// sound generate & portamento & pitch LFO & Y-Control LFO & PWM envelope
			if (playing) {
				var modP:MOscPulse = (MOscPulse)(m_oscSet1.getMod(MOscillator.PULSE));
				var modY:MOscMod   = m_oscSet1.getMod(m_lfoYfuncMod);
				if (
					(m_portDepth != 0.0) ||
					(m_oscLConnect[LFO_TARGET_PITCH] != 0) ||
					(m_oscLConnect[LFO_TARGET_YCONTROL] != 0) ||
					(m_env3Connect == true)
				) {
					s = start;
					depth = m_lfoDepth[LFO_TARGET_PITCH];
					depth2 = m_lfoDepth[LFO_TARGET_YCONTROL];
					onCounter = m_onCounter;
					//LFO入力波形は、0.0を中心に-1.0～1.0を行き来するモジュール
					do {
						e = s + s_lfoDelta;
						if (e > end) e = end;
						//for pitch
						freqNo = m_freqNo;
						if (m_portDepth != 0.0) {
							freqNo += m_portDepth;
							m_portDepth += (m_portDepthAdd * Number(e - s - 1));
							if ((m_portDepth * m_portDepthAdd) > 0.0) m_portDepth = 0.0;
						}
						if (m_oscLConnect[LFO_TARGET_PITCH] != 0) {
							if (onCounter >= m_lfoDelay[LFO_TARGET_PITCH]) {
								freqNo += (m_oscModL[LFO_TARGET_PITCH].getNextSample() * depth);
								m_oscModL[LFO_TARGET_PITCH].addPhase(e - s - 1);
							}
						}
						m_oscMod1.setFrequency(getFrequency(freqNo));
						//for Y-Control
						if (m_oscLConnect[LFO_TARGET_YCONTROL] != 0) {
							if (onCounter >= m_lfoDelay[LFO_TARGET_YCONTROL]) {
								modY.setYControl(m_lfoYfuncMod, m_lfoYfuncNum, (m_oscModL[LFO_TARGET_YCONTROL].getNextSample() * depth2));
								m_oscModL[LFO_TARGET_YCONTROL].addPhase(e - s - 1);
							}
						}
						//PWM+WaveSet or WaveSet
						if (m_env3Connect == true) {
							for (i = s; i < e; i++) {
								modP.setPWM( m_envelope3.getNextAmplitudeLinear() );
								trackBuffer[i] = m_oscMod1.getNextSample();
							}
						} else {
							m_oscMod1.getSamples(trackBuffer, s, e);
						}
						onCounter += e - s;
						s = e;
					} while (s < end)
				}
				else {
					m_oscMod1.getSamples(trackBuffer, start, end);
				}
			}

			// Amplitude Envelope
			if (m_oscSet1.getForm() != MOscillator.OPMS) {
				if(m_vmode_rate == 0.0){
					m_envelope1.ampSamplesLinear(trackBuffer, start, end, m_ampLevel, m_mix_volume, m_volume, m_vmode_rate, m_vmode_index, m_vmode_max);
				}else{
					m_envelope1.ampSamplesNonLinear(trackBuffer, start, end, m_ampLevel, m_mix_volume, m_volume, m_vmode_rate, m_vmode_index, m_vmode_max);
				}
			}
			else {
				//ＦＭ音源モジュールの場合で、playing==false の場合
				if (playing==false) {
					for(i = start; i < end; i++) {
						trackBuffer[i] = 0.0;
					}
				}
			}
			// この音量エンベロープ処理は、playing==false での無音レンダリングを行う。
			// ＦＭ音源モジュールが選択されている場合は独自に無音レンダリングを行う。

			// Amplitude LFO
			if(m_oscLConnect[LFO_TARGET_AMPLITUDE] != 0){
				s = start;
				onCounter = m_onCounter;
				depth = m_lfoDepth[LFO_TARGET_AMPLITUDE];
				Vscale = Number(m_vmode_max);
				Vrate  = m_vmode_rate;
				//LFO入力波形は 0.0から-1.0間を行き来するモジュール
				if (m_vmode_rate == 0.0) {	// Linear Amplitude Mode
					for(i = start; i < end; i++) {
						vol = 1.0;
						if (onCounter >= m_lfoDelay[LFO_TARGET_AMPLITUDE]) {
							vol += m_oscModL[LFO_TARGET_AMPLITUDE].getNextSample() * (depth/Vscale);
						}
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						onCounter++;
					}
				}
				else {	// Non Linear Amplitude Mode
					for(i = start; i < end; i++) {
						vol = 1.0;
						if (onCounter >= m_lfoDelay[LFO_TARGET_AMPLITUDE]) {
							vol *= Math.pow( 10.0, (((m_oscModL[LFO_TARGET_AMPLITUDE].getNextSample() * depth) * Vrate) / 20.0) );
						}
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						onCounter++;
					}
				}
			}

			// Fade
			if (m_fadeMode == 0) {		//FadeOut
				if (m_fadeDyRange >= 0.0) {
					for(i = start; i < end; i++) {
						vol = 1.0 - (m_fadeCount / m_fadeTotal);
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						if (m_fadeCount < m_fadeTotal) m_fadeCount += 1.0;
					}
				}
				else {
					for(i = start; i < end; i++) {
						vol = Math.pow( 10.0, (((m_fadeCount / m_fadeTotal) * m_fadeDyRange) / 20.0) );
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						if (m_fadeCount < m_fadeTotal) m_fadeCount += 1.0;
					}
				}
			}
			if (m_fadeMode == 1) {		//FadeIn
				if (m_fadeDyRange >= 0.0) {
					for(i = start; i < end; i++) {
						vol = (m_fadeCount / m_fadeTotal);
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						if (m_fadeCount < m_fadeTotal) m_fadeCount += 1.0;
					}
					if (m_fadeCount >= m_fadeTotal) m_fadeMode = (-1);			//フェードインで上がりきったら解除
				}
				else {
					for(i = start; i < end; i++) {
						vol = Math.pow( 10.0, (((1.0 - (m_fadeCount / m_fadeTotal)) * m_fadeDyRange) / 20.0) );
						if (vol < 0.0) vol = 0.0;
						if (vol > 1.0) vol = 1.0;
						trackBuffer[i] *= vol;
						if (m_fadeCount < m_fadeTotal) m_fadeCount += 1.0;
					}
					if (m_fadeCount >= m_fadeTotal) m_fadeMode = (-1);			//フェードインで上がりきったら解除
				}
			}

			// Formant Filter
			// フォルマントフィルタを経由した後の音声が無音であればスキップ
			tmpFlag = playing;
			playing = playing || m_formant.checkToSilence();
			if(playing != tmpFlag){
				for(i = start; i < end; i++) trackBuffer[i] = 0;
			}
			if(playing){
				m_formant.run(trackBuffer, start, end);
			}

			// IIR Filter
			// フィルタを経由した後の音声が無音であればスキップ
			tmpFlag = playing;
			playing = playing || m_filter.checkToSilence();
			if(playing != tmpFlag){
				for(i = start; i < end; i++) trackBuffer[i] = 0;
			}
			if(playing){
				if(m_oscLConnect[LFO_TARGET_FILTER] != 0){
					s = start;
					depth = m_lfoDepth[LFO_TARGET_FILTER];
					onCounter = m_onCounter;
					//LFO入力波形は、0.0を中心に-1.0～1.0を行き来するモジュール
					do {
						e = s + s_lfoDelta;
						if (e > end) e = end;
						lpffrq = m_lpfFrq;
						if (onCounter >= m_lfoDelay[LFO_TARGET_FILTER]) {
							lpffrq += m_oscModL[LFO_TARGET_FILTER].getNextSample() * depth;
							m_oscModL[LFO_TARGET_FILTER].addPhase(e - s - 1);
						}
						if(lpffrq < 0.0){
							lpffrq = 0.0;
						}else if(lpffrq > 1.0){
							lpffrq = 1.0;
						}
						m_filter.run(trackBuffer, s, e, m_envelope2, lpffrq, m_lpfAmt, m_lpfRes, key);
						onCounter += e - s;
						s = e;
					} while(s < end);
				}else{
					m_filter.run(trackBuffer, start, end, m_envelope2, m_lpfFrq, m_lpfAmt, m_lpfRes, key);
				}
			}

			// Delay Effect & PanPot LFO & Wave Rendering
			if (m_delayMode != 0) {
				//【注意】Delay Effect が有効の場合、playingと同期しなくなるため常にレンダリング
				if (m_oscLConnect[LFO_TARGET_PANPOT] != 0) {
					//Delay[ON] PanLFO[ON]
					depth = m_lfoDepth[LFO_TARGET_PANPOT];
					onCounter = m_onCounter;
					pan = m_pan;						//m_panは0.5中心の0.0～1.0で推移。幅が0.5であることに注意。
					//LFO入力波形は、0.0を中心に-1.0～1.0を行き来するモジュール
					for (i = start; i < end; i++) {
						j = i + i;
						if (onCounter >= m_lfoDelay[LFO_TARGET_PANPOT]) {
							pan = m_pan + m_oscModL[LFO_TARGET_PANPOT].getNextSample() * depth;
							if (pan < 0) {
								pan = 0;
							}
							else if (pan > 1.0) {
								pan = 1.0;
							}
						}
						
						amplitude = trackBuffer[i] * 0.5;
						rightAmplitude = amplitude * pan;
						culcDelay(  ((amplitude - rightAmplitude) * m_lgPan_L),  (rightAmplitude * m_lgPan_R)  );
						samples[j] += m_delayVal_L;
						j++;
						samples[j] += m_delayVal_R;
						onCounter++;
					}
				}
				else {
					//Delay[ON] PanLFO[OFF]
					for (i = start; i < end; i++) {
						j = i + i;
						
						amplitude = trackBuffer[i] * 0.5;
						rightAmplitude = amplitude * m_pan;
						culcDelay(  ((amplitude - rightAmplitude) * m_lgPan_L),  (rightAmplitude * m_lgPan_R)  );
						samples[j] += m_delayVal_L;
						j++;
						samples[j] += m_delayVal_R;
					}
				}
			}
			else {
				if (playing) {
					if (m_oscLConnect[LFO_TARGET_PANPOT] != 0) {
						//Delay[OFF] PanLFO[ON]
						depth = m_lfoDepth[LFO_TARGET_PANPOT];
						onCounter = m_onCounter;
						pan = m_pan;						//m_panは0.5中心の0.0～1.0で推移。幅が0.5であることに注意。
						//LFO入力波形は、0.0を中心に-1.0～1.0を行き来するモジュール
						for (i = start; i < end; i++) {
							j = i + i;
							if (onCounter >= m_lfoDelay[LFO_TARGET_PANPOT]) {
								pan = m_pan + m_oscModL[LFO_TARGET_PANPOT].getNextSample() * depth;
								if (pan < 0) {
									pan = 0;
								}
								else if (pan > 1.0) {
									pan = 1.0;
								}
							}
							
							amplitude = trackBuffer[i] * 0.5;
							rightAmplitude = amplitude * pan;
							samples[j] += ((amplitude - rightAmplitude) * m_lgPan_L);
							j++;
							samples[j] += (rightAmplitude * m_lgPan_R);
							onCounter++;
						}
					}
					else {
						//Delay[OFF] PanLFO[OFF]
						for (i = start; i < end; i++) {
							j = i + i;
							
							amplitude = trackBuffer[i] * 0.5;
							rightAmplitude = amplitude * m_pan;
							samples[j] += ((amplitude - rightAmplitude) * m_lgPan_L);
							j++;
							samples[j] += (rightAmplitude * m_lgPan_R);
						}
					}
				}
			}
			if (playing) {
				//trace("output audio");
				m_onCounter += end - start;				//常にplayingに同期して更新
			}
		}

	}
}
