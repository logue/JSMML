package com.flmml {
	import flash.events.EventDispatcher;
	import flash.utils.*;
	
	import mx.utils.StringUtil;

	public class MML extends EventDispatcher {
		//●印は、createTrack()の時に初期化が必要
		public static const DEF_FORM:int = 3;
		public static const DEF_SUBFORM:int = 0;
		public static const DEF_VSMAX:int = 15;
		public static const DEF_VSRATE:Number = 3.0;
		public static const DEF_VOL:int = 13;
		public static const DEF_EXPRS:int = 0;
		public static const DEF_MIXVOL:Number = 0.0;
		public static const DEF_PWMNUM:Number = 4.0;
		public static const DEF_PWMDNM:Number = 8.0;
		public static const DEF_NZMOD:int = 7;
		public static const DEF_MAX_L_CLK:Number = 1.0 / 1.0;
		public static const DEF_MIN_L_CLK:Number = 1.0 / 300.0;
		public static const DEF_MAX_E_CLK:Number = 1.0 / 1.0;
		public static const DEF_MIN_E_CLK:Number = 1.0 / 1000.0;
		public static const DEF_MAX_DELAY_CT:int = 44100 * 2;
		public static const DEF_MIN_DELAY_CT:int = 4;
		public static const DEF_MAX_DELAY_LV:Number = (-0.2);
		public static const DEF_MIN_DELAY_LV:Number = (-96.0);
		public static var s_tickUnit:Number = 192.0;
		public static var s_reportTotalTicks:Boolean;
		protected static const MAX_POLYVOICE:int = 64;
		protected var m_sequencer:MSequencer;
		protected var m_tracks:Vector.<MTrack>;
		protected var m_string:String;
		protected var m_trackNo:int;
		protected var m_octave:int;				// ●
		protected var m_relativeDir:Boolean;	// 相対オクターブ記号向き切り替え
		protected var m_detune:int;				// ●
		protected var m_VXscaleMax:int;			// ●Volume/eXpressionスケール管理：最大値
		protected var m_VXscaleRate:Number;		// ●Volume/eXpressionスケール管理：減衰率（０のとき線形、正数のときdB）
		protected var m_volume:int;				// ●ボリューム値管理
		protected var m_volumeDir:int;			// 相対ボリューム記号向き切り替え
		protected var m_expression:int;			// ●エクスプレッション値管理
		protected var m_vDir:Boolean;			// 相対volume記号向き切り替え
		protected var m_length:int;				// default length
		protected var m_tempo:Number;
		protected var m_totalTicks:uint;		// コンパイル時のチェック用Ticksカウンタ
		protected var m_totalOvFlow:Boolean;	// コンパイル時のチェック用フラグ
		protected var m_letter:int;
		protected var m_keyoff:int;
		protected var m_form:int;
		protected var m_subForm:int;
		protected var m_pwmNum:Number;			// ●pwmの分子
		protected var m_pwmDenom:Number;		// ●pwmの分母
		protected var m_gate:int;				// qの分子
		protected var m_maxGate:int;			// ●qの分母
		protected var m_noteShift:int;			// ●
		protected var m_AEnvLvRdMode:int;		// ●
		protected var m_AEnvLvDenom:Number;		// ●
		protected var m_AEnvLvOffset:Number;	// ●
		protected var m_noiseModDest:int;		// ●
		protected var m_delayCountMax:int;		// ●
		protected var m_warning:String;
		protected var m_beforeNote:int;
		protected var m_portamento:int;
		protected var m_usingPoly:Boolean;
		protected var m_polyVoice:int;
		protected var m_polyForce:Boolean;
		protected var m_metaTitle:String;
		protected var m_metaArtist:String;
		protected var m_metaCoding:String;
		protected var m_metaComment:String;

		public function MML() {
			startup();
		}

		public function startup():void {
			m_sequencer = new MSequencer();
			var self:MML = this;
			m_sequencer.addEventListener(MMLEvent.COMPLETE, function(e:MMLEvent):void {
					m_sequencer.stop();
					self.dispatchEvent(new MMLEvent(MMLEvent.COMPLETE));
				});
			m_sequencer.addEventListener(MMLEvent.BUFFERING, function(e:MMLEvent):void {
					self.dispatchEvent(new MMLEvent(MMLEvent.BUFFERING, false, false, 0, 0, e.progress));
				});
		}

		public function set onSignal(func:Function):void {
			// ex) function func(globalTick:uint, event:int):void {}
			m_sequencer.onSignal = func;
		}

		public function setSignalInterval(interval:int):void {
			m_sequencer.setSignalInterval(interval);
		}

		public function getWarnings():String {
			return m_warning;
		}

		protected function warning(header:String, warnId:int, str:String):void {
			m_warning += header + MWarning.getString(warnId, str) + "\n";
		}

		protected function len2tick(len:int):int {
			if (len == 0) return m_length;
			return (int(s_tickUnit)) / len;
		}

		protected function note(noteNo:int):void {
			//trace("note"+noteNo);
			noteNo += m_noteShift + getKeySig();
			if (getChar() == '*') {	// ポルタメント記号
				m_beforeNote = noteNo + m_octave * 12;
				m_portamento = 1;
				next();
			}
			else {
				var lenMode:int;
				var len:int;
				var tick:int = 0;
				var tickTemp:int;
				var tie:int = 0;
				var keyon:int = (m_keyoff == 0) ? 0 : 1;
				m_keyoff = 1;
				while (1) {
					if (getChar() != '%') {
						lenMode = 0;
					}
					else {
						lenMode = 1;
						next();
					}
					len = getUInt(0);
					if (tie == 1 && len == 0) {
						m_keyoff = 0;
						break;
					}
					tickTemp = (lenMode ? len : len2tick(len));
					tick += getDot(tickTemp);
					tie = 0;
					if (getChar() == '&') { // tie
						tie = 1;
						next();
					}
					else {
						break;
					}
				}
				
				if (checkLimitOfPlayTime(tick) == true) {
					
					if (m_portamento == 1) { // ポルタメントなら
						m_tracks[m_trackNo].recPortamento(m_beforeNote - (noteNo + m_octave * 12), tick);
					}
					m_tracks[m_trackNo].recNote(noteNo + m_octave * 12, tick, keyon, m_keyoff);
					if (m_portamento == 1) { // ポルタメントなら
						m_tracks[m_trackNo].recPortamento(0, 0);
						m_portamento = 0;
					}
					
				}
				else {
					if (m_portamento == 1) {
						m_portamento = 0;
					}
				}
			}
		}

		protected function rest():void {
			//trace("rest");
			var lenMode:int = 0;
			if (getChar() == '%') {
				lenMode = 1;
				next();
			}
			var len:int;
			len = getUInt(0);
			var tick:int = lenMode ? len : len2tick(len);
			tick = getDot(tick);
			if (m_keyoff == 0) {
				//タイ中に休符を受け付けた場合、ノートオフし、タイモード終了
				m_tracks[m_trackNo].recNoteOff(-1);
				m_keyoff = 1;
			}
			if (checkLimitOfPlayTime(tick) == true) {
				m_tracks[m_trackNo].recRest(tick);
			}
		}

		protected function checkLimitOfPlayTime(ticks:int):Boolean {
			var maxtt:uint = (uint.MAX_VALUE) >> 1;			// ticks累計の受付上限
			var nowtt:uint = m_totalTicks;
			var result:Boolean = true;
			
			if (m_totalOvFlow == true) {
				return false;
			}
			
			if ((maxtt - nowtt) <= ticks) result = false;
			
			if (result == true) {
				m_totalTicks += ticks;
			}
			else {
				m_totalOvFlow = true;
				m_warning += "[Track:" + m_trackNo + "] 音符・休符の受付許容を超えました。当Trackでの音符・休符は途中から無効になります。\n";
			}
			return result;
		}

		protected function atmark():void {
			var c:String = getChar();
			var c0:String;
			var c1:String;
			var o:int = 1;
			var n:Number;
			switch(c) {
			case 'e': // @ea/@ef/@ew: Envelope
				{
					var evGetFail:int;
					var evGetFinish:Boolean;
					var evDest:int;
					var evCurP:int;
					var evLoopP:int;
					var relEntryP:int;
					var LvRdMode:int;
					var atkMode:Boolean;
					var initLv:Number;
					var LvDenom:Number;
					var LvOffset:Number;
					var pmode:int, rmode:Boolean, rtval:Number, lvval:Number;
					var evPoints:Array = new Array();
					var evEl:MMLArgEnv;
					var chklp:int;
					var evErr:String;
					next();

					evGetFail = 0;
					evGetFinish = false;
					evCurP    = 0;
					evLoopP   = -1;
					relEntryP = -1;
					evErr     = "";
					//エンベロープ宛先決定および別CMDからのオプション値受け取り
					switch(getChar()) {
					case 'a':
						evDest  = 1;
						LvRdMode = m_AEnvLvRdMode;
						if (m_AEnvLvDenom == 0.0) {
							LvDenom = Number(m_VXscaleMax);
						} else {
							LvDenom = m_AEnvLvDenom;
						}
						LvOffset = m_AEnvLvOffset;
						next();
						break;
					case 'f':
						evDest = 2;
						LvRdMode = 0;
						LvDenom = 100.0;
						LvOffset = 0.0;
						next();
						break;
					case 'w':
						evDest = 3;
						LvRdMode = 0;
						LvDenom = m_pwmDenom;
						LvOffset = 0.0;
						next();
						break;
					default:
						evGetFail |= 0x00000001;
						evErr += "/env-mode-error/";
						LvRdMode = 0;
						LvDenom = 10000.0;
						LvOffset = 0.0;
						break;
					}

					//initial level
					if (getChar() == '&') {
						atkMode = true;
						initLv = 0.0;
						next();
					}
					else {
						atkMode = false;
						initLv = (getSNumber(0.0) + LvOffset) / LvDenom;
						if (initLv > 1.0) initLv = 1.0;
						if (initLv < 0.0) initLv = 0.0;
					}
					if (getChar() == ',') next(); else evGetFail |= 0x00000100;

					//エンベロープの節の群を取得
					while (evGetFail == 0) {
						c0 = getChar();
						if (c0 == 'n') {
							pmode = MEnvelope.EPM_NORMAL;
							next();
						}
						else if (c0 == 'l') {
							pmode = MEnvelope.EPM_LOOP_ENT;
							if (evLoopP < 0) evLoopP = evCurP; else evGetFail |= 0x00000200;
							next();
						}
						else if (c0 == 'r') {
							pmode = MEnvelope.EPM_REL_ENT;
							if (relEntryP < 0) relEntryP = evCurP; else evGetFail |= 0x00000400;
							if (relEntryP <= evLoopP) evGetFail |= 0x00000401;
							next();
						}
						else {
							pmode = -1;
							evGetFail |= 0x00000800;
						}
						if (getChar() == ',') next(); else evGetFail |= 0x00001000;

						c0 = getChar();
						if (c0 == 'i') {
							rmode = false; next();
						}
						else if (c0 == 't') {
							rmode = true;  next();
						}
						else {
							rmode = true;			//この時点では失敗判定しない
						}

						rtval = getUNumber(0.0);
						if (getChar() == ',') next(); else evGetFail |= 0x00010000;

						chklp = m_letter;
						lvval = (getSNumber(0.0) + LvOffset) / LvDenom;
						if (lvval > 1.0) lvval = 1.0;
						if (lvval < 0.0) lvval = 0.0;
						if (getChar() == ',') {
							next();
						} else {
							if (chklp == m_letter) {
								evGetFail |= 0x00100000;
							}
							else {
								evGetFinish = true;
							}
						}

						if (evGetFail == 0) {
							evEl = new MMLArgEnv(evCurP);
							evEl.pt_mode = pmode;
							evEl.rt_mode = rmode;
							evEl.rate    = rtval;
							evEl.level   = lvval;
							evPoints.push(evEl);
							evCurP++;
						}
						else {
							break;
						}

						if (evGetFinish == true) break;
					}

					if ((evDest == 1) && (lvval != 0.0)) {
						//音量エンベロープのリリース最終節のレベルが０でない場合、失敗とみなす（ノートオフ後の無限開放禁止）
						evGetFail |= 0x10000000;
						evErr += "/final-level must be zero/";
						//フィルタやＰＷＭでは０終了の必要なし。
					}

					if ( (evGetFail == 0) && (evPoints.length > 0) && (relEntryP > 0) ) {
						m_tracks[m_trackNo].recEnvelope(evDest, LvRdMode, atkMode, initLv, evPoints);
					}
					else {
						warning("[Track:" + m_trackNo + "] ", MWarning.ERR_ENVELOPE, "CODE:" + evGetFail + evErr);
					}
				}
				break;
			case 'o':
				next();
				if (getChar() == 'e') {
					next();
					if (getChar() == 'a') {
						// @oea: Option Envelope for Amplitude
						next();
						m_AEnvLvRdMode = getUInt(m_AEnvLvRdMode);				//レベルの丸めモード。省略時は過去設定値。
						if (m_AEnvLvRdMode > 4) m_AEnvLvRdMode = 0;				//0:丸めず少数以下有効。1:切上げ。2:TYPE-S。3:TYPE-Y。4:TYPE-D4。
						if (getChar() == ',') {
							next();
							m_AEnvLvDenom = getUNumber(m_AEnvLvDenom);			//レベルの分母指定。省略時は過去設定値。
							if (m_AEnvLvDenom < 0.0) m_AEnvLvDenom = 0.0;		//0.0 は特例でレベルの分母にm_VXscaleMaxを採用するモード。
							if (getChar() == ',') {
								next();
								m_AEnvLvOffset = getSNumber(m_AEnvLvOffset);	//レベルのオフセット指定。省略時は過去設定値。
							}
						}
					}
					else {
						// 未定義コマンド
						warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0+c1);
						next();
					}
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'm':
				next();
				c0 = getChar();
				if (c0 == 'h') {
					// @mh: OPM HARD LFO
					next();
					var wf:int = 0, freq:int = 0;
					var pmd:int = 0, amd:int = 0, pms:int = 0, ams:int = 0, sync:int = 0;
					do {
					wf = getUInt(wf);
					if (getChar() != ',') break;
					next();
					freq = getUInt(freq);
					if (getChar() != ',') break;
					next();
					pmd = getUInt(pmd);
					if (getChar() != ',') break;
					next();
					amd = getUInt(amd);
					if (getChar() != ',') break;
					next();
					pms = getUInt(pms);
					if (getChar() != ',') break;
					next();
					ams = getUInt(ams);
					if (getChar() != ',') break;
					next();
					sync = getUInt(sync);
					}
					while (false);
					m_tracks[m_trackNo].recOPMHwLfo(wf, freq, pmd, amd, pms, ams, sync);
				}
				else if (c0 == 'r') {
					// @mr: opM envelope generator Reset mode every note-on
					next();
					o = getUInt(0);
					if (o != 0) o = 1;
					m_tracks[m_trackNo].recYControl(9,5,Number(o));		//Y経由でsetOPMEgResetMode()呼び出し
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'n': // @n..
				next();
				c0 = getChar();
				if ( chkCharIsNum(c0) == true ) {
					// @n: Noise frequency
					n = getUNumber(0.0);
					if (n < 0.0) n = 0.0;
					if (n > 44100.0) n = 44100.0;
					o = m_noiseModDest;					//まず宛先を前回指定モジュールにしておく。
					if (getChar() == ',') {
						next();
						o = getUInt(m_noiseModDest);
						switch(o) {
						case MOscillator.NOISE_W:
						case MOscillator.NOISE_FC:
						case MOscillator.NOISE_GB:
						case MOscillator.NOISE_PSG:
							break;
						default:
							o = DEF_NZMOD;				//無効モジュールを指定された場合はデフォルト
							break;
						}
						m_noiseModDest = o;
					}
					m_tracks[m_trackNo].recYControl(o,5,n);		//音源モジュール側のYの番号５で統一のため
				}
				else if (c0 == 'c') {
					// @nc: Noise psg Clock
					next();
					o = getUInt(0);
					m_tracks[m_trackNo].recYControl(7,10,Number(o));
				}
				else if (c0 == 's') {
					// @ns: Note Shift (relative)
					next();
					m_noteShift += getSInt(0);
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'w': // @w..
				next();
				c0 = getChar();
				if ( (chkCharIsNum(c0) == true) || (c0 == ',')) {
					// @w: pulse Width modulation
					var wN:Number;
					var wD:Number;
					wD = m_pwmDenom;						//分母情報を前回採用した値で準備。
					if (chkCharIsNum(c0) == true) {
						wN = getUNumber(0.0);				//分子を0.0とした場合も、省略したとみなす。
					}
					else {
						wN = 0.0;							//分子を省略した場合を0.0とする。
					}
					if (getChar() == ',') {
						next();
						wD = getUNumber(m_pwmDenom);
						if (wN == 0.0) wN = wD / 2.0;	//分子を省略し、分母のみ指定した場合、分子/分母=0.5にする。カンマつきで分母省略時も同様。
					}
					n = wN / wD;
					if (n >= 0.005 && n <= 0.995) {
						m_pwmNum   = wN;
						m_pwmDenom = wD;
						m_tracks[m_trackNo].recPWM(n, 0);
					}
					else {
						warning("[Track:" + m_trackNo + "] ", MWarning.ERR_PWM, "@w"+wN+","+wD );
					}
				}
				else if (c0 == 'e') {
					// @we: pulse Width Envelope-mode enable
					next();
					m_tracks[m_trackNo].recPWM(0.5, 1);			//デューティー比50%指定はダミー。モード通知が目的。
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@" + c + c0);
					next();
				}
				break;
			case 'p': // @p..
				next();
				c0 = getChar();
				if ( (chkCharIsNum(c0) == true) || (c0 == '-') || (c0 == '+') ) {
					// @p: PanPot
					n = getSNumber(0.0);
					if (n < -100.0) n = -100.0;
					if (o > 100.0)  n = 100.0;
					m_tracks[m_trackNo].recPan(n);
				}
				else if (c0 == 'l') {
					// @pl: poly mode
					next();
					o = getUInt(m_polyVoice);
					o = Math.max(0, Math.min(m_polyVoice, o));
					m_tracks[m_trackNo].recPoly(o);
				}
				else if (c0 == 'h') {
					// @ph: phase reset mode
					next();
					o = getSInt(-1);					//mode値省略時mode=-1。（設定変更せず、位相ワンタイムリセット要求のみ）
					n = 0.0;
					if (getChar() == ',') {
						next();
						n = getSNumber(0.0);
					}
					if (n >= 1.0) n = n % 1.0;
					if (n < 0) n = (-1.0);
					m_tracks[m_trackNo].recPhaseRMode(o, n);
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case '\'': // @'a': formant filter
				next();
				o = m_string.indexOf('\'', m_letter);
				if (o >= 0) {
					var vstr:String = m_string.substring(m_letter, o);
					var vowel:int = 0;
					switch(vstr) {
					case 'a': vowel = MFormant.VOWEL_A; break;
					case 'e': vowel = MFormant.VOWEL_E; break;
					case 'i': vowel = MFormant.VOWEL_I; break;
					case 'o': vowel = MFormant.VOWEL_O; break;
					case 'u': vowel = MFormant.VOWEL_U; break;
					default: vowel = -1; break;
					}
					m_tracks[m_trackNo].recFormant(vowel);
					m_letter = o + 1;
				}
				break;
			case 'd': // @d..
				next();
				c0 = getChar();
				if ( (chkCharIsNum(c0) == true) || (c0 == '-') || (c0 == '+') ) {
					// @d: Detune
					m_detune = getSInt(m_detune);
					o = 0;			//変化単位の指定が無い場合は０。変化単位が０だとMChannel.setPitchResolution()で捨てられる（反映されない）。
					if (getChar() == ',') {
						next();
						o = getUInt(100);
					}
					m_tracks[m_trackNo].recDetune(m_detune, o);
				}
				else if (getChar() == 'l') {
					next();
					if (getChar() == 'y') {
						// @dly: DelaY effect
						var dlyTime:Number;
						var dlyCount:int;
						var dlyLvDB:Number;
						var dlyLevel:Number;
						dlyTime  = 0.0;
						dlyCount = 0;
						dlyLvDB  = (-6.0);
						dlyLevel = Math.pow( 10.0, dlyLvDB / 20.0 );
						next();
						c1 = getChar();
						if (chkCharIsNum(c1) == true) {
							dlyTime = getUNumber(0.0);			//時間指定の場合、単位はmsとみなす（少数以下の指定も有効）。
							dlyCount = int( Math.round(dlyTime * 44100.0 * 0.001) );
							if ((dlyTime > 0) && (dlyCount == 0)) {
								dlyCount = 1;		// 1 sampleに満たない 0 より大きいdlyTimeは、あえて 1 sample に再定義し、警告対象とする
							}
						}
						else if (c1 == '#') {
							next();
							dlyCount = getUInt(0);
						}
						else {
							dlyCount = 0;
						}
						if (getChar() == ',') {
							next();
							dlyLvDB = getSNumber(dlyLvDB);			//dB値として取得（負数を想定）
							dlyLevel = Math.pow( 10.0, dlyLvDB / 20.0 );
						}
						//無効指定または範囲内指定の場合にコマンド実行
						if (
							(dlyCount == 0)
							||
							(
								((dlyCount >= DEF_MIN_DELAY_CT) && (dlyCount <= DEF_MAX_DELAY_CT)) &&
								((dlyLvDB  >= DEF_MIN_DELAY_LV) && (dlyLvDB  <= DEF_MAX_DELAY_LV))
							)
						) {
							if (m_delayCountMax < dlyCount) m_delayCountMax = dlyCount;			//最大バッファ数の更新
							m_tracks[m_trackNo].recDelay(dlyCount, dlyLevel);
						}
						else {
							warning("[Track:" + m_trackNo + "] ", MWarning.ERR_EFF_DELAY, "delay:"+dlyCount+"samples, level:"+dlyLvDB+"dB");
						}
					}
					else {
						// 未定義コマンド
						warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0+c1);
						next();
					}
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'l': // @lp/@la/@lf/@lb/@ly: Low frequency oscillator (LFO)
				{
					var lDest:int;
					var lDp:Number = 0.0;
					var lWd:Number = 1.0;
					var lFm:int = 0;
					var lSf:int = 0;
					var lDl:Number = 0.0;
					var lYmod:int = 0;
					var lYnum:int = 0;
					var lYtb1:int = 0;
					var lYtb2:int = (-1);
					var lPset:Array = new Array();
					var lFail:int = 0;
					next();
					switch(getChar()) {
					case 'p': lDest = 0; next(); break;
					case 'a': lDest = 1; next(); break;
					case 'f': lDest = 2; next(); break;
					case 'b': lDest = 3; next(); break;
					case 'y': lDest = 4; next(); break;
					default: lFail = 1;
					}
					if ((lFail == 0) && (lDest != 4)) {
						lDp = getSNumber(lDp);
						if (getChar() == ',') {
							next();
							lWd = getUNumber(lWd);
							if (lWd < 1.0) lWd = 1.0;
							if (getChar() == ',') {
								next();
								lFm = getUInt(lFm);
								if (getChar() == '-') {
									next();
									lSf = getUInt(lSf);
								}
								if (getChar() == ',') {
									next();
									lDl = getUNumber(lDl);
								}
							}
						}
					}
					else if ((lFail == 0) && (lDest == 4)) {
						lDp = getSNumber(lDp);
						if (getChar() == ',') {
							next();
							lWd = getUNumber(lWd);
							if (lWd < 1.0) lWd = 1.0;
							if (getChar() == ',') {
								next();
								lYmod = getUInt(lYmod);
								if (getChar() == ',') {
									next();
									lYnum = getUInt(lYnum);
									if (getChar() == ',') {
										next();
										lYtb1 = getUInt(lYtb1);
										if (getChar() == ',') {
											next();
											lYtb2 = getSInt(lYtb2);
											if (getChar() == ',') {
												next();
												lDl = getUNumber(lDl);
											}
										}
									}
								}
							}
						}
						if (lYtb2 < 0) lYtb2 = 0x0ffff;
						lFm = (lYmod << 16) | (lYnum & 0x0ffff);
						lSf = (lYtb1 << 16) | (lYtb2 & 0x0ffff);
					}
					if (lFail == 0) {
						lPset.push(lDp);
						lPset.push(lWd);
						lPset.push(lFm);
						lPset.push(lSf);
						lPset.push(lDl);
						m_tracks[m_trackNo].recLFO(lDest, lPset);
					}
					else {
						warning("[Track:" + m_trackNo + "] ", MWarning.ERR_LFO, "CODE:" + lFail);
					}
				}
				break;
			case 'f': // @f..
				next();
				c0 = getChar();
				if ( (chkCharIsNum(c0) == true) || (c0 == '-') || (c0 == '+') ) {
					// @f: Filter
					var swt:int = 0;
					var amt:Number = 0.0;
					var frq:Number = 0.0;
					var res:Number = 0.0;
					var fPset:Array = new Array();
					swt = getSInt(swt);
					if (getChar() == ',') {
						next();
						amt = getSNumber(amt);
						if (getChar() == ',') {
							next();
							frq = getUNumber(frq);
							if (getChar() == ',') {
								next();
								res = getUNumber(res);
							}
						}
					}
					fPset.push(amt);
					fPset.push(frq);
					fPset.push(res);
					m_tracks[m_trackNo].recLPF(swt, fPset);
				}
				else if (c0 == 'o') {
					// @fo: FadeOut
					next();
					n = getUNumber(0.0);
					if (n < 0.005) n = 0.0;
					o = 0;
					if (getChar() == ',') {
						next();
						o = getSInt(0);
						if (o > 0) {
							o = 0;				// 0 は線形モード
						}
						if ( o < (-110) ) {
							o = (-110);			// 最大減衰 -110dBまで。
						}
					}
					if (n == 0.0) {
						m_tracks[m_trackNo].recFade(1.0, 0, -1);		//mode:-1(fade disable)
					}
					else {
						m_tracks[m_trackNo].recFade(n, o, 0);			//mode:0(fade enable:fadeOut)
					}
				}
				else if (c0 == 'i') {
					// @fi: FadeIn
					next();
					n = getUNumber(0.0);
					if (n < 0.005) n = 0.0;
					o = 0;
					if (getChar() == ',') {
						next();
						o = getSInt(0);
						if (o > 0) {
							o = 0;				// 0 は線形モード
						}
						if ( o < (-110) ) {
							o = (-110);			// 最大減衰 -110dBまで。
						}
					}
					if (n == 0.0) {
						m_tracks[m_trackNo].recFade(1.0, 0, -1);		//mode:-1(fade disable)
					}
					else {
						m_tracks[m_trackNo].recFade(n, o, 1);			//mode:1(fade enable:fadeIn)
					}
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'q': // @q: gate time 2 (ticks)
				next();
				m_tracks[m_trackNo].recGateTicks2(getUInt(0));
				break;
			case 'u':	// @u: midi風なポルタメント
				var rate:int;
				var mode:int;
				next();
				mode = getUInt(0);
				switch (mode) {
					case 0:
					case 1:
						m_tracks[m_trackNo].recMidiPort(mode);
						break;
					case 2:
						rate = 0;
						if (getChar() == ',') {
							next();
							rate = getUInt(0);
							if (rate < 0) rate = 0;
							if (rate > 127) rate = 127;
						}
						m_tracks[m_trackNo].recMidiPortRate(rate * 1);
						break;
					case 3:
						if (getChar() == ',') {
							next();
							var oct:int;
							var baseNote:int = -1;
							if (getChar() != 'o') {
								oct = m_octave;
							}
							else {
								next();
								oct = getUInt(0);
							}
							c = getChar();
							switch(c) {
								case 'c': baseNote = 0; break;
								case 'd': baseNote = 2; break;
								case 'e': baseNote = 4; break;
								case 'f': baseNote = 5; break;
								case 'g': baseNote = 7; break;
								case 'a': baseNote = 9; break;
								case 'b': baseNote = 11; break;
							}
							if (baseNote >= 0) {
								next();
								baseNote += m_noteShift + getKeySig();
								baseNote += oct * 12;
							}
							else {
								baseNote = getUInt(60);
							}
							if (baseNote < 0) baseNote = 0;
								if (baseNote > 127) baseNote = 127;
							m_tracks[m_trackNo].recPortBase(baseNote);
						}
						break;
					default:
						break;
				}
				break;
			case 'r': // @r..
				next();
				c0 = getChar();
				if (c0 == 'p') {
					// @rp: repeat infinitely entry 
					next();
					if (m_tracks[m_trackNo].m_IRepeatF == false) {
						m_tracks[m_trackNo].m_IRepeatF = true;
						m_tracks[m_trackNo].m_IRepeatGtReq = m_tracks[m_trackNo].getRecGlobalTick();
						//テンポ管理トラックへも上書き通知。テンポ管理トラックでは最終要求トラックの状態を持つ。
						m_tracks[MTrack.TEMPO_TRACK].m_IRepeatF = true;
						m_tracks[MTrack.TEMPO_TRACK].m_IRepeatGtReq = m_tracks[m_trackNo].getRecGlobalTick();
						MTrack.s_IRRequestLastTrack = m_trackNo;
					}
					else {
						//同トラック内での複数要求は認めない
						warning("[Track:" + m_trackNo + "] ", MWarning.ERR_IREPEAT_TIMES,"");
					}
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c+c0);
					next();
				}
				break;
			case 'z': // @z: damp off envelope
				next();
				if (m_keyoff == 0) {
					//タイ中に @z を受け付けた場合、ノートオフし、タイモード終了
					m_tracks[m_trackNo].recNoteOff(-1);
					m_keyoff = 1;
				}
				m_tracks[m_trackNo].recDampOffEnvelope();
				break;
			case '@':	// @@数字[-数字]: 音源モジュール選択。[-数字]は省略可能で、枝番指定。
				next();
				m_form = getUInt(m_form);
				o = 0;
				if (getChar() == '-') {
					next();
					o = getUInt(0);
				}
				m_tracks[m_trackNo].recForm(m_form, o);
				break;
			default:
				if ( chkCharIsNum(c) == true ) {
					// @数字： カレント音源モジュールの枝番指定。
					o = getUInt(0);
					m_tracks[m_trackNo].recSubForm(o);
				}
				else {
					// 未定義コマンド
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, "@"+c);
					next();
				}
				break;
			}
		}

		protected function firstLetter():void {
			var c:String = getCharNext();
			var c0:String;
			var i:int;
			var j:int;
			var n:Number;
			var f:Boolean;
			switch(c) {
			case 'c': note(0);  break;
			case 'd': note(2);  break;
			case 'e': note(4);  break;
			case 'f': note(5);  break;
			case 'g': note(7);  break;
			case 'a': note(9);  break;
			case 'b': note(11); break;
			case 'r': rest();   break;
			case 'o': // Octave
				m_octave = getUInt(m_octave);
				if (m_octave < 0) m_octave = 0;
				if (m_octave > 9) m_octave = 9;
				break;
			case '>' : // octave shift
				if (m_relativeDir == false) m_octave++; else m_octave--;
				break;
			case '<': // octave shift
				if (m_relativeDir == false) m_octave--; else m_octave++;
				break;
			case '@':
				atmark();
				break;
			case 'v': // v..
				c0 = getChar();
				if ( chkCharIsNum(c0) == true ) {
					// Volume
					m_volume = getUInt(m_volume);
					if (m_volume > m_VXscaleMax) m_volume = m_VXscaleMax;
					m_tracks[m_trackNo].recVolume(m_volume);
				}
				else if (c0 == 's') {
					// Volume Scale Setting
					next();
					i = 0;
					m_VXscaleMax = getUInt(m_VXscaleMax);
					if (m_VXscaleMax < 3)   m_VXscaleMax = 3;
					if (m_VXscaleMax > 1023) m_VXscaleMax = 1023;
					
					if (getChar() == ',') {
						next();
						m_VXscaleRate = getUNumber(m_VXscaleRate);
						if (m_VXscaleRate < 0.0)  m_VXscaleRate = 0.0;
						if (m_VXscaleRate > 24.0) m_VXscaleRate = 24.0;
						
						if (getChar() == ',') {
							next();
							i = getUInt(0);		//dBスケール時の、v0の処理モード。省略時は０（v0=無音）
						}
					}
					m_tracks[m_trackNo].recVolMode(m_VXscaleMax, m_VXscaleRate, i);
				}
				else {
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, c + c0);
					next();
				}
				break;
			case '(': // vol up/down
			case ')':
				i = 1;
				if ( chkCharIsNum( getChar() ) == true ) {
					i = getUInt(1);
				}
				if ( ( (c == ')') && (m_vDir == false) ) ||
					 ( (c == '(') && (m_vDir == true ) )  ) {
					// up
					m_volume += i;
					if (m_volume > m_VXscaleMax) m_volume = m_VXscaleMax;
				}
				else {
					// down
					m_volume -= i;
					if (m_volume < 0) m_volume = 0;
				}
				m_tracks[m_trackNo].recVolume(m_volume);
				break;
			case 'x':
				// eXpression
				m_expression = getSInt(m_expression);
				m_tracks[m_trackNo].recExpression(m_expression);
				break;
			case 'm':
				c0 = getChar();
				if (c0 == 'v') {
					// Mixing Volume
					next();
					n = getSNumber(0.0);
					m_tracks[m_trackNo].recMixingVolume(n);
				}
				else {
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, c + c0);
					next();
				}
				break;
			case 'p': // PanPot legacy mode
				i = getSInt(0);
				if (i < -1) i = (-1);
				if (i > 1)  i = 1;
				m_tracks[m_trackNo].recPanLegacy(i);
				break;
			case 'l': // Length
				m_length = len2tick(getUInt(4));
				m_length = getDot(m_length);
				break;
			case 'q': // Q..
				c0 = getChar();
				if ( chkCharIsNum(c0) == true ) {
					// gate time rate
					i = getUInt(0);						//分子を０とした場合も、省略したとみなす。
					j = m_maxGate;
					if (getChar() == ',') {
						next();
						j = getUInt(m_maxGate);			//カンマつきで分母省略時は前回採用された分母を使用する。
						if (i == 0) i = j;				//分子を省略していた場合、分子/分母=1.0にする。
					}
					if (i == 0) i = m_gate;				//分子を省略し、分母をカンマごと省略した場合は、直前までの設定を復元する。
					n = Number(i) / Number(j);
					if (n > 0.0 && n <= 1.0) {
						m_gate = i;
						m_maxGate = j;
						m_tracks[m_trackNo].recGateRate(Number(m_gate) / Number(m_maxGate));
					}
					else {
						warning("[Track:" + m_trackNo + "] ", MWarning.ERR_QUANTIZE, "q"+i+","+j );
					}
				}
				else if (c0 == '%') {
					// gate time 1 (ticks)
					next();
					m_tracks[m_trackNo].recGateTicks1(getUInt(0));
				}
				else {
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, c + c0);
					next();
				}
				break;
			case 'n':
				c0 = getChar();
				if (c0 == 's') {
					// Note Shift (absolute)
					next();
					m_noteShift = getSInt(m_noteShift);
				}
				else {
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, c + c0);
					next();
				}
				break;
			case 't': // Tempo
				var tempoGT:uint;
				m_tempo = getUNumber(MTrack.DEFAULT_BPM);			//省略時はデフォルト値
				if (getChar() == ',') {
					next();
					n = getUNumber(1.0);							//省略時は分母＝１
					if (n <= 0.0) n = 1.0;
					m_tempo = m_tempo / n;
				}
				if (m_tempo < 1.0) m_tempo = 1.0;					//ＢＰＭ１未満は１に矯正
				tempoGT = m_tracks[m_trackNo].getRecGlobalTick();
				if (tempoGT != 0) {
					m_tracks[MTrack.TEMPO_TRACK].m_IRCheckStrictlyF = true;
				}
				m_tracks[MTrack.TEMPO_TRACK].recTempo(tempoGT, m_tempo);
				break;
			case 'y': // Y: oscillator control: y(module),(func),(param)
				f = false;
				i = getUInt(0);
				if (getChar() == ',') {
					next();
					j = getUInt(0);
					if (getChar() == ',') {
						next();
						n = getSNumber(0.0);
						m_tracks[m_trackNo].recYControl(i,j,n);
					}
					else {
						f = true;
					}
				}
				else {
					f = true;
				}
				if (f == true) {
					warning("[Track:" + m_trackNo + "] ", MWarning.ERR_Y_CMD, "");
				}
				break;
			case '[':
				m_tracks[m_trackNo].recChordStart();
				break;
			case ']':
				m_tracks[m_trackNo].recChordEnd();
				break;
			case ';': // end of track
				if (m_tracks[m_trackNo].getNumEvents() > 0) {
					// トラック終端処理
					finalizeTrack();
					// 新規トラックへ移行＋インスタンス作成（initMMLvariable()込）
					m_trackNo++;
					m_tracks[m_trackNo] = createTrack();
				}
				else {
					initMMLvariable();
				}
				break;
			default:
				{
					warning("[Track:" + m_trackNo + "] ", MWarning.UNKNOWN_COMMAND, c);
				}
				break;
			}
		}

		protected function finalizeTrack():void {
			m_tracks[m_trackNo].enableDelayEffectBuffer(m_delayCountMax);		//ディレイ未使用の場合にも０の旨、通知
		}

		protected function getCharNext():String {
			return (m_letter < m_string.length) ? m_string.charAt(m_letter++) : '';
		}

		protected function getChar():String {
			return (m_letter < m_string.length) ? m_string.charAt(m_letter) : '';
		}

		protected function next(i:int = 1):void {
			m_letter += 1;
		}

		protected function chkCharIsNum(c:String):Boolean {
			if (c >= '0' && c <= '9') {
				return true;
			}
			else {
				return false;
			}
		}
		protected function getKeySig():int {
			var k:int = 0;
			var f:int = 1;
			while(f) {
				var c:String = getChar();
				switch(c) {
				case "+": case "#": k++; next(); break;
				case "-":           k--; next(); break;
				default: f = 0; break;
				}
			}
			return k;
		}

		protected function getUInt(def:int):int {
			var ret:int = 0;
			var l:int = m_letter;
			var f:int = 1;
			while(f) {
				var c:String = getChar();
				switch(c) {
				case '0': ret = (ret * 10) + 0; next(); break;
				case '1': ret = (ret * 10) + 1; next(); break;
				case '2': ret = (ret * 10) + 2; next(); break;
				case '3': ret = (ret * 10) + 3; next(); break;
				case '4': ret = (ret * 10) + 4; next(); break;
				case '5': ret = (ret * 10) + 5; next(); break;
				case '6': ret = (ret * 10) + 6; next(); break;
				case '7': ret = (ret * 10) + 7; next(); break;
				case '8': ret = (ret * 10) + 8; next(); break;
				case '9': ret = (ret * 10) + 9; next(); break;
				default: f = 0; break;
				}
			}
			return (m_letter == l) ? def : ret;
		}

		protected function getUNumber(def:Number):Number {
			var ret:Number = Number( getUInt(int(def)) );
			var l:Number = 1;
			if (getChar() == '.') {
				next();
				var f:Boolean = true;
				while(f) {
					var c:String = getChar();
					l *= (0.1);
					switch(c) {
						case '0': ret = ret + (0.0 * l); next(); break;
						case '1': ret = ret + (1.0 * l); next(); break;
						case '2': ret = ret + (2.0 * l); next(); break;
						case '3': ret = ret + (3.0 * l); next(); break;
						case '4': ret = ret + (4.0 * l); next(); break;
						case '5': ret = ret + (5.0 * l); next(); break;
						case '6': ret = ret + (6.0 * l); next(); break;
						case '7': ret = ret + (7.0 * l); next(); break;
						case '8': ret = ret + (8.0 * l); next(); break;
						case '9': ret = ret + (9.0 * l); next(); break;
						default: f = false; break;
					}
				}
			}
			return ret;
		}

		protected function getSInt(def:int):int {
			var c:String = getChar();
			var s:int = 1;
			var l:int;
			var ret:int;
			if      (c == '-') { s = -1; next(); }
			else if (c == '+') next();
			l = m_letter;
			ret = getUInt(def) * s;
			return (m_letter == l) ? def : ret;			//マイナスだけ書き数字省略した場合のdefの符号反転を防ぐ
		}

		protected function getSNumber(def:Number):Number {
			var c:String = getChar();
			var s:Number = 1.0;
			var l:int;
			var ret:Number;
			if      (c == '-') { s = -1.0; next(); }
			else if (c == '+') next();
			l = m_letter;
			ret = getUNumber(def) * s;
			return (m_letter == l) ? def : ret;			//マイナスだけ書き数字省略した場合のdefの符号反転を防ぐ
		}

		protected function getDot(tick:int):int {
			var c:String = getChar();
			var intick:int = tick;
			while(c == '.') {
				next();
				intick /= 2;
				tick += intick;
				c = getChar();
			}
			return tick;
		}

		private function initMMLvariable():void {
			m_tempo = MTrack.DEFAULT_BPM;
			m_totalTicks = 0;
			m_totalOvFlow = false;
			m_keyoff = 1;
			m_length = len2tick(4);
			m_form = DEF_FORM;
			m_subForm = DEF_SUBFORM;
			m_gate = 16;
			m_maxGate = 16;
			m_pwmNum   = DEF_PWMNUM;
			m_pwmDenom = DEF_PWMDNM;
			m_noiseModDest = DEF_NZMOD;
			m_delayCountMax = 0;		//ディレイエフェクトの最大サンプル数。０でディレイ無効。

			m_octave = 4;
			m_noteShift = 0;
			m_beforeNote = 0;
			m_portamento = 0;

			m_VXscaleMax = DEF_VSMAX;
			m_VXscaleRate = DEF_VSRATE;
			m_volume = DEF_VOL;
			m_expression = DEF_EXPRS;

			m_AEnvLvRdMode = 0;			//音量ENVレベルの丸めモード。0 は滑らかモード。
			m_AEnvLvDenom = 0.0;		//音量ENVレベルの分母指定。0.0 は特例で分母にm_VXscaleMaxを採用するモード。
			m_AEnvLvOffset = 0.0;		//音量ENVレベルへのオフセット。
		}
		public function createTrack():MTrack {
			initMMLvariable();
			return new MTrack();
		}

		protected function begin():void {
			m_letter = 0;
		}

		protected function process():void {
			begin();
			while(m_letter < m_string.length) {
				firstLetter();
			}
			//最終トラックがセミコロンで終了しなかった場合に向けた終端処理
			if (m_tracks[m_trackNo].getNumEvents() > 0) {
				finalizeTrack();
			}
		}

		protected function processRepeat():void {
			m_string = m_string.toLowerCase();
			begin();
			var repeat:Array = new Array();
			var origin:Array = new Array();
			var start:Array = new Array();
			var last:Array = new Array();
			var nest:int = -1;
			while(m_letter < m_string.length) {
				var c:String = getCharNext();
				switch(c) {
				case '/':
					if (getChar() == ':') {
						next();
						origin[++nest] = m_letter - 2;
						repeat[nest] = getUInt(2);
						start[nest] = m_letter;
						last[nest] = -1;
					}
					else if (nest >= 0) {
						last[nest] = m_letter - 1;
						m_string = m_string.substring(0, m_letter-1) + m_string.substring(m_letter);
						m_letter--;
					}
					else {
					}
					break;
				case ':':
					if (getChar() == '/' && nest >= 0) {
						next();
						var contents:String = m_string.substring(start[nest], m_letter - 2);
						var newstr:String = m_string.substring(0, origin[nest]);
						for (var i:int = 0; i < repeat[nest]; i++) {
							if (i < repeat[nest]-1 || last[nest] < 0) newstr += contents;
							else newstr += m_string.substring(start[nest], last[nest]);
						}
						var l:int = newstr.length;
						newstr += m_string.substring(m_letter);
						m_string = newstr;
						m_letter = l;
						nest--;
					}
					break;
				default:
					break;
				}
			}
			if (nest >= 0) warning("", MWarning.UNCLOSED_REPEAT, "");
		}

		protected function getIndex(idArr:Array, id:String):int {
			for(var i:int = 0; i < idArr.length; i++)
				if (((String)(idArr[i])) == id) return i;
			return -1;
		}

		protected function replaceMacro(macroTable:Array):Boolean {
			for each(var macro:Object in macroTable){
				if(m_string.substr(m_letter, macro.id.length) == macro.id){
					var start:int = m_letter, last:int = m_letter + macro.id.length, code:String = macro.code;
					m_letter += macro.id.length;
					var c:String = getCharNext();
					while(StringUtil.isWhitespace(c) || c == '　'){
						c = getCharNext();
					}
					var args:Array = new Array();
					var q:int = 0;
					
					// 引数が0個の場合は引数処理をスキップするように変更
					if (macro.args.length > 0)
					{
						if(c == "{"){
							c = getCharNext();
							while (q == 1 || (c != "}" && c != "")) {
								if (c == '"') q = 1 - q;
								if(c == "$"){
									replaceMacro(macroTable);
								}
								c = getCharNext();
							}
							last = m_letter;
							var argstr:String = m_string.substring(start + macro.id.length + 1, last - 1);
							var curarg:String = "", quoted:Boolean = false;
							for(var pos:int = 0; pos < argstr.length; pos++){
								if(!quoted && argstr.charAt(pos) == '"'){
									quoted = true;
								}else if(quoted && (pos + 1) < argstr.length && argstr.charAt(pos) == '\\' && argstr.charAt(pos + 1) == '"'){
									curarg += '"';
									pos++;
								}else if(quoted && argstr.charAt(pos) == '"'){
									quoted = false;
								}else if(!quoted && argstr.charAt(pos) == ','){
									args.push(curarg);
									curarg = "";
								}else{
									curarg += argstr.charAt(pos);
								}
							}
							args.push(curarg);
							if(quoted){
								warning("", MWarning.UNCLOSED_ARGQUOTE, "");
							}
						}
						// 引数への置換
						for(var i:int = 0; i < code.length; i++){
							for(var j:int = 0; j < args.length; j++){
								if(j >= macro.args.length){
									break;
								}
								if(code.substr(i, macro.args[j].id.length + 1) == ("%" + macro.args[j].id)){
									code = code.substring(0, i) + code.substring(i).replace("%" + macro.args[j].id, args[macro.args[j].index]);
									i += args[macro.args[j].index].length - 1;
									break;
								}
							}
						}
					}

					m_string = m_string.substring(0, start - 1) + code + m_string.substring(last);
					m_letter = start - 1;
					//trace(m_string.substring(m_letter));
					return true;
				}
			}
			return false;
		}

		protected function processMacro():void {
			var exp:RegExp;
			var s:String;
			var i:int;
			var j:int;
			var n:Number;
			var matched:Array;

			// 無限リピート受け付け状態(static)初期化
			MTrack.s_infiniteRepeatF = false;

			// REPORT TOTAL TICKS (EVERY TRACK)
			{
				//デフォルト設定
				s_reportTotalTicks = false;
				
				matched = findMetaDescV("REPORT TOTAL TICKS");
				if (matched.length > 0) {
					s_reportTotalTicks = true;
				}
				matched = findMetaDescV("report total ticks");		//全小文字でも受付
				if (matched.length > 0) {
					s_reportTotalTicks = true;
				}
			}

			// OCTAVE REVERSE
			{
				matched = findMetaDescV("OCTAVE REVERSE");
				if (matched.length > 0) {
					m_relativeDir = true;
				}
				else {
					//デフォルト設定
					m_relativeDir = false;
				}
			}

			// VOLUME REVERSE
			{
				matched = findMetaDescV("VOLUME REVERSE");
				if (matched.length > 0) {
					m_vDir = true;
				}
				else {
					//デフォルト設定
					m_vDir = false;
				}
			}

			// TUNING
			{
				//デフォルト設定
				MChannel.s_BaseNote = 57.0;
				MChannel.s_BaseFreq = 440.0;
				
				matched = findMetaDescV("TUNING");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					if (s.length > 0) {
						matched = s.split(",");
						i = int(matched[0]);
						n = Number(matched[1]);
						var testfreq:Number = n * Math.pow(2.0, ( (57.0 - Number(i)) / (12.0) ) );
						if ((i >= 0) && (testfreq >= 200.0) && (testfreq <= 550.0)) {
							MChannel.s_BaseNote = Number(i);
							MChannel.s_BaseFreq = n;
						}
						else {
							i = (-1);
						}
					}
					else {
						i = (-1);
					}
					if (i < 0) {
						m_warning += "#TUNINGの指定内容で、o4a周波数が200Hz～550Hz範囲外のため、既定o4a=440Hzから変更しません。(" + s + ")\n";
					}
				}
			}

			// TICKUNIT
			{
				//デフォルト設定
				s_tickUnit = 192.0;
				
				matched = findMetaDescV("TICKUNIT");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					if (s.length > 0) {
						i = int(s);
						if ((i >= 48) && (i <= 3072) && ((i % 4) == 0)) {
							s_tickUnit = Number(i);
						}
						else {
							i = (-1);
						}
					}
					else {
						i = (-1);
					}
					if (i < 0) {
						m_warning += "#TICKUNITの設定が規定（48以上、3072以下の４で割り切れる数）外のため、既定192から変更しません。(" + s + ")\n";
					}
				}
				setSignalInterval((int(s_tickUnit)) / 4);
			}

			// MULOVSWM :Multiple of oversampling of WAVEMEM
			{
				//デフォルト設定
				MOscWaveMem.s_OverSmpMultiple = 4.0;
				
				matched = findMetaDescV("MULOVSWM");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					if (s.length > 0) {
						i = int(s);
						switch(i) {
						case 2:
						case 4:
						case 8:
							MOscWaveMem.s_OverSmpMultiple = Number(i);
							break;
						default:
							i = (-1);
						}
					}
					else {
						i = (-1);
					}
					if (i < 0) {
						m_warning += "#MULOVSWMの設定が規定（2 / 4 / 8）外のため、既定 4 から変更しません。(" + s + ")\n";
					}
				}
			}

			// ENVCLOCK
			{
				//デフォルト設定
				MEnvelope.s_envClockMode = false;
				MEnvelope.s_envClockMgnf = (1.0);
				MEnvelope.s_envClock = (1.0 / 120.0);
				
				matched = findMetaDescV("ENVCLOCK");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					matched = s.split(",");
					switch (matched.length) {
					case 1:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = (1.0);
						}
						else {
							i = 0;			//固定時間
							n = 1.0 / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 2:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = 1.0 / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 3:
					default:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n  = Number(matched[2]) / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 0:
						i = (-1);		//error status
						break;
					}
					if ( (i >= 0) && (isNaN(n) == false) ) { 
						MEnvelope.s_envClockMode = ((i == 0) ? false : true       );
						MEnvelope.s_envClockMgnf = ((i == 0) ? (1.0) : n          );
						MEnvelope.s_envClock =     ((i == 0) ? n     : (1.0/120.0));
					}
					else {
						m_warning += "#ENVCLOCKの設定が規定外のため、既定から変更しません。(" + s + ")\n";
					}
				}
			}

			// ENV RESOLUTION
			{
				//デフォルト設定
				MEnvelope.s_envResolMode = (-1);
				MEnvelope.s_envResolMgnf = 1.0;
				MEnvelope.s_envResol = 1.0;
				
				matched = findMetaDescV("ENVRESOL");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					matched = s.split(",");
					switch (matched.length) {
					case 1:
						if (matched[0] == "=") {
							i = (-1);		//最大解像度
							n = (1.0);
						}
						else if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = (1.0);
						}
						else {
							i = 0;			//固定時間
							n = 1.0 / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-9);		//error status
						}
						break;
					case 2:
						if (matched[0] == "=") {
							i = (-1);		//最大解像度
							n = (1.0);
						}
						else if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = 1.0 / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-9);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-9);		//error status
						}
						break;
					case 3:
					default:
						if (matched[0] == "=") {
							i = (-1);		//最大解像度
							n = (1.0);
						}
						else if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n  = Number(matched[2]) / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-9);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_E_CLK) || (n < DEF_MIN_E_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-9);		//error status
						}
						break;
					case 0:
						i = (-1);		//error status
						break;
					}
					if ( i != (-9) ) {
						if ( i == 0 ) {		//固定時間
							MEnvelope.s_envResolMode = 0;
							MEnvelope.s_envResolMgnf = 1.0;
							MEnvelope.s_envResol = 44100.0 * n;
						}
						else if (i == 1) {	//tickカウント依存
							MEnvelope.s_envResolMode = 1;
							MEnvelope.s_envResolMgnf = n;
							MEnvelope.s_envResol = 44100.0 * n;		//暫定数値
						}
						else {				//解像度無効（最大解像度）
							MEnvelope.s_envResolMode = (-1);
							MEnvelope.s_envResolMgnf = 1.0;
							MEnvelope.s_envResol = 1.0;
						}
					}
					else {
						m_warning += "#ENVRESOLの設定が規定外のため、既定から変更しません。(" + s + ")\n";
					}
				}
			}

			// LFOCLOCK
			{
				//デフォルト設定
				MChannel.s_LFOclockMode = true;
				MChannel.s_LFOclockMgnf = (1.0);
				MChannel.s_LFOclock = (1.0 / 120.0);
				
				matched = findMetaDescV("LFOCLOCK");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					matched = s.split(",");
					switch (matched.length) {
					case 1:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = (1.0);
						}
						else {
							i = 0;			//固定時間
							n = 1.0 / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 2:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = 1.0 / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 3:
					default:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n  = Number(matched[2]) / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 0:
						i = (-1);		//error status
						break;
					}
					if ( (i >= 0) && (isNaN(n) == false) ) { 
						MChannel.s_LFOclockMode = ((i == 0) ? false : true);
						MChannel.s_LFOclockMgnf = ((i == 0) ? (1.0) : n   );
						MChannel.s_LFOclock =     ((i == 0) ? n     : (1.0/120.0));
					}
					else {
						m_warning += "#LFOCLOCKの設定が規定外のため、既定から変更しません。(" + s + ")\n";
					}
				}
			}

			// LFO RESOLUTION
			{
				//デフォルト設定
				MChannel.s_lfoDeltaMode = false;
				MChannel.s_lfoDeltaMgnf = (1.0 / 300.0);
				MChannel.s_lfoDelta = int(44100.0 * MChannel.s_lfoDeltaMgnf);
				
				matched = findMetaDescV("LFORESOL");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					matched = s.split(",");
					switch (matched.length) {
					case 1:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = (1.0);
						}
						else {
							i = 0;			//固定時間
							n = 1.0 / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 2:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n = 1.0 / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 3:
					default:
						if (matched[0] == "%") {
							i = 1;			//tickカウント数依存
							n  = Number(matched[2]) / Number(matched[1]);
							if ( (n <= 0.0) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						else {
							i = 0;			//固定時間
							n  = Number(matched[1]) / Number(matched[0]);
							if ( (n > DEF_MAX_L_CLK) || (n < DEF_MIN_L_CLK) || (isNaN(n)==true) || (isFinite(n)==false) ) i = (-1);		//error status
						}
						break;
					case 0:
						i = (-1);		//error status
						break;
					}
					if ( (i >= 0) && (isNaN(n) == false) ) { 
						MChannel.s_lfoDeltaMode = ((i == 0) ? false           : true       );
						MChannel.s_lfoDeltaMgnf = ((i == 0) ? (1.0)           : n          );
						MChannel.s_lfoDelta =     ((i == 0) ? int(44100.0 * n): (1.0/120.0));
					}
					else {
						m_warning += "#LFORESOLの設定が規定外のため、既定から変更しません。(" + s + ")\n";
					}
				}
			}

			// LFO TABLE
			{
				exp = /^#LFOTABLE[ \t]*(\d+)\s*{([^}]*)}/gm;
				matched = m_string.match(exp);
				m_string = m_string.replace(exp, "");
				
				var lfotable:Array;
				var lfotableset:int;
				for (i = 0; i < matched.length; i++) {
					lfotable = matched[i].match(/^#LFOTABLE[ \t]*(\d+)\s*{([^}]*)}/m);
					lfotableset = MOscLTable.setTable(int(lfotable[1]), lfotable[2]);
					if (lfotableset != 0) {
						warning("", MWarning.ERR_LFOTABLE, "No.:" + lfotable[1] + " CODE:" + String(lfotableset));
					}
				}
			}

			// LFO TABLE PROCESS MODE
			{
				//デフォルト設定
				MOscLTable.s_Pmode = 0;
				
				matched = findMetaDescV("LFOTPM");
				if (matched.length > 0) {
					s = String(matched[0]);
					s = s.replace(/\s+/gm, "");
					if (s.length > 0) {
						i = int(s);
						if (i != 0) i = 1;
						MOscLTable.s_Pmode = i;
					}
				}
			}

			// POLY MODE
			{
				var usePoly:String = findMetaDescN("USING\\s+POLY");
				usePoly = usePoly.replace("\r",  "");
				usePoly = usePoly.replace("\n", " ");
				usePoly = usePoly.toLowerCase();
				if (usePoly.length > 0) {
					var ss:Array = usePoly.split(" ");
					if (ss.length < 1) {
						m_usingPoly = false;
					}
					else {
						m_usingPoly = true;
						m_polyVoice = Math.min(Math.max(1, int(ss[0])), MAX_POLYVOICE); // 1～MAX_POLYVOICE
					}
					for (i = 1; i < ss.length; i++) {
						if (ss[i] == "force") {
							m_polyForce = true;
						}
					}
					if (m_polyVoice <= 1) {
						m_usingPoly = false;
						m_polyForce = false;
					}
					// trace("using poly = " + m_usingPoly + ", max voice = " + m_polyVoice + ", force = " + m_polyForce);
				}
				else {
					//デフォルト設定
					m_usingPoly = false;
					m_polyForce = false;
				}
			}

			// meta informations
			{
				m_metaTitle   = findMetaDescN("TITLE"  );	// #TITLE
				m_metaArtist  = findMetaDescN("ARTIST" );	// #ARTIST
				m_metaComment = findMetaDescN("COMMENT");	// #COMMENT
				m_metaCoding  = findMetaDescN("CODING" );	// #CODING
				findMetaDescN("PRAGMA");	// #PRAGMA
			}

			// FM Desc
			{
				exp = /^#FM@[ \t]*(\d+)\s*{([^}]*)}/gm;
				matched = m_string.match(exp);
				m_string = m_string.replace(exp, "");
				
				var fmm:Array;
				for (i = 0; i < matched.length; i++) {
					fmm = matched[i].match(/^#FM@[ \t]*(\d+)\s*{([^}]*)}/m);
					MOscOPMS.loadToneOPM(int(fmm[1]), fmm[2]);
				}
				fmm = null;
				
				exp = /^#FMS@[ \t]*(\d+)\s*{([^}]*)}/gm;
				matched = m_string.match(exp);
				m_string = m_string.replace(exp, "");
				
				var fms:Array;
				for (i = 0; i < matched.length; i++) {
					fms = matched[i].match(/^#FMS@[ \t]*(\d+)\s*{([^}]*)}/m);
					MOscOPMS.loadToneOPMS(int(fms[1]), fms[2]);
				}
				fms = null;
			}

			// WAVE MEMORY(SINGLE CYCLE) (ex. "#WAVEM 0,1,4,0123456789abcdeffedcba9876543210")
			{
				var wav:Array;
				var wavs:String;
				var arg:Array;
				var waveNo:int;
				exp = /^#WAVEM\s.*$/gm;
				matched = m_string.match(exp);
				if (matched) {
					for(i = 0; i < matched.length; i++) {
						m_string = m_string.replace(exp, "");
						//trace(matched[i]);
						wav = matched[i].split(" ");
						wavs = "";
						for(j = 1; j < wav.length; j++) wavs += wav[j];
						arg = wavs.split(",");
						if ( (int(arg[0]) >= 0) && (int(arg[1]) > 0) && (int(arg[2]) > 0) && (arg[3].length > 0) ) {
							waveNo = int(arg[0]);
							if (waveNo >= MOscWaveMem.MAX_WAVE) waveNo = MOscWaveMem.MAX_WAVE-1;
							var charWidth:int = int(arg[1]);
							if (charWidth > 2) charWidth = 2;
							var bitWidth:int = int(arg[2]);
							if (bitWidth > 8) bitWidth = 8;
							if ((charWidth == 1) && (bitWidth > 4)) bitWidth = 4;
							//trace(waveNo+":",arg[1].toLowerCase());
							if (charWidth == 1) {
								MOscWaveMem.setWave1c(waveNo,bitWidth,arg[3]);
							}
							else {
								MOscWaveMem.setWave2c(waveNo,bitWidth,arg[3]);
							}
						}
					}
				}
			}

			// DPCM WAVE (ex. "#DPCM 0,64,0,1,mA==")
			{
				exp = /^#DPCM\s.*$/gm;
				matched = m_string.match(exp);
				if (matched) {
					for(i = 0; i < matched.length; i++) {
						m_string = m_string.replace(exp, "");
						//trace(matched[i]);
						wav = matched[i].split(" ");
						wavs = "";
						for(j = 1; j < wav.length; j++) wavs += wav[j];
						arg = wavs.split(",");
						if (	(int(arg[0]) >= 0) && 
								(int(arg[1]) >= 0) && 
								(int(arg[2]) >= 0) && 
								(int(arg[3]) >= 0) && 
								(arg[4].length > 0)			)
						{
							waveNo = int(arg[0]);
							if (waveNo >= MOscSmpDPCM.MAX_WAVE) waveNo = MOscSmpDPCM.MAX_WAVE-1;
							var intVol:int = int(arg[1]);
							if (intVol > 127) intVol = 127;
							var loopFg:int = int(arg[2]);
							if (loopFg > 1) loopFg = 1;
							var decMode:int = int(arg[3]);
							if (decMode > 1) decMode = 1;
							MOscSmpDPCM.setWave(waveNo, intVol, loopFg, decMode, arg[4]);
						}
					}
				}
			}

			// unsigned 8bit PCM WAVE (ex. "#U8PCM 0,44100,0,0,808080808080808080")
			{
				exp = /^#U8PCM\s.*$/gm;
				matched = m_string.match(exp);
				if (matched) {
					for(i = 0; i < matched.length; i++) {
						m_string = m_string.replace(exp, "");
						//trace(matched[i]);
						wav = matched[i].split(" ");
						wavs = "";
						for(j = 1; j < wav.length; j++) wavs += wav[j];
						arg = wavs.split(",");
						if (	(int(arg[0]) >= 0) && 
								(Number(arg[1]) >= 2000.0) && 
								(int(arg[2]) >= -1) && 
								(int(arg[3]) >= 0) && 
								(arg[4].length > 0)			)
						{
							waveNo = int(arg[0]);
							if (waveNo >= MOscSmpU8PCM.MAX_WAVE) waveNo = MOscSmpU8PCM.MAX_WAVE-1;
							var sFreq:Number = Number(arg[1]);
							if (sFreq > 88200.0) sFreq = 88200.0;
							var loopPt:int = int(arg[2]);
							if (loopPt > MOscSmpU8PCM.MAX_LENGTH) loopPt = MOscSmpU8PCM.MAX_LENGTH;
							decMode = int(arg[3]);
							if (decMode > 1) decMode = 1;
							MOscSmpU8PCM.setWave(waveNo, sFreq, loopPt, decMode, arg[4]);
						}
					}
				}
			}

			// macro
			begin();
			var top:Boolean = true;
			var macroTable:Array = new Array();
			var regTrimHead:RegExp = /^\s*/m;
			var regTrimFoot:RegExp = /\s*$/m;
			while(m_letter < m_string.length) {
				var c:String = getCharNext();
				switch(c) {
					case '$':
						if(top){
							var last:int = m_string.indexOf(";", m_letter);
							if(last > m_letter){
								var nameEnd:int = m_string.indexOf("=", m_letter);
								if(nameEnd > m_letter && nameEnd < last){
									var start:int = m_letter;
									var argspos:int = m_string.indexOf("{");
									if(argspos < 0 || argspos >= nameEnd){
										argspos = nameEnd;
									}
									var idPart:String = m_string.substring(start, argspos);
									var regexResult:Array = idPart.match("[a-zA-Z_][a-zA-Z_0-9#\+\(\)]*");
									if(regexResult != null){
										var id:String = regexResult[0];
										idPart = idPart.replace(regTrimHead, '').replace(regTrimFoot, '');	// idString.Trim();
										if (idPart != id) {
											warning("", MWarning.INVALID_MACRO_NAME, idPart);
										}
										if(id.length > 0){
											var args:Array = new Array();
											if(argspos < nameEnd){
												var argstr:String = m_string.substring(argspos + 1, m_string.indexOf("}", argspos));
												args = argstr.split(",");
												for(i = 0; i < args.length; i++){
													var argid:Array = args[i].match("[a-zA-Z_][a-zA-Z_0-9#\+\(\)]*");
													args[i] = { id: (argid != null ? argid[0] : ""), index: i };
												}
												args.sort(function (a:Object, b:Object):int {
													if(a.id.length > b.id.length)  return -1;
													if(a.id.length == b.id.length) return  0;
													return 1;
												});
											}
											m_letter = nameEnd + 1;
											c = getCharNext();
											while(m_letter < last){
												if(c == "$"){
													if(!replaceMacro(macroTable)){
														if(m_string.substr(m_letter, id.length) == id){
															m_letter--;
															m_string = remove(m_string, m_letter, m_letter + id.length);
															warning("", MWarning.RECURSIVE_MACRO, id);
														}
													}
													last = m_string.indexOf(";", m_letter);
												}
												c = getCharNext();
											}
											var pos:int = 0;
											for(; pos < macroTable.length; pos++){
												 if(macroTable[pos].id == id){
													 macroTable.splice(pos, 1);
													 pos--;
													 continue;
												 }
												if(macroTable[pos].id.length < id.length){
													break;
												}
											}
											macroTable.splice(pos, 0, { id: id, code: m_string.substring(nameEnd + 1, last), args: args });
											m_string = remove(m_string, start - 1, last);
											m_letter = start - 1;
										}
									}
								}else{
									// macro use
									replaceMacro(macroTable);
									top = false;
								 }
							}else{
								// macro use
								replaceMacro(macroTable);
								top = false;
							}
						}else{
							// macro use
							replaceMacro(macroTable);
							top = false;
						}
						break;
					case ';':
						top = true;
						break;
					default:
						if(!StringUtil.isWhitespace(c) && c != '　'){
							top = false;
						}
						break;
				}
			}
		}
		
		// 指定されたメタ記述を引き抜いてくる（複数該当の記述は配列で返す）
		protected function findMetaDescV(sectionName:String):Array {
			var i:int;
			var matched:Array;
			var mm:Array;
			var e1:RegExp;
			var e2:RegExp;
			var tt:Array = new Array();
			
			e1 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$", "gm"); // global multi-line
			e2 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$",  "m"); //        multi-line
			
			matched = m_string.match(e1);
			if (matched) {
				m_string = m_string.replace(e1, "");
				for(i = 0; i < matched.length; i++) {
					mm = matched[i].match(e2);
					if (mm.length >= 3) { 
						tt.push(mm[2]);
					}
				}
				// trace(sectionName + " = " + tt);
			}
			return tt;
		}
		
		// 指定されたメタ記述を引き抜いてくる（複数該当の記述は改行区切りで連結した文字列で返す）
		protected function findMetaDescN(sectionName:String):String {
			var i:int;
			var matched:Array;
			var mm:Array;
			var e1:RegExp;
			var e2:RegExp;
			var tt:String = "";
			
			e1 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$", "gm"); // global multi-line
			e2 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$",  "m"); //        multi-line
			
			matched = m_string.match(e1);
			if (matched) {
				m_string = m_string.replace(e1, "");
				for(i = 0; i < matched.length; i++) {
					mm = matched[i].match(e2);
					if (mm.length >= 3) { 
						tt += mm[2];
						if (i + 1 < matched.length) {
							tt += "\r\n";
						}
					}
				}
				// trace(sectionName + " = " + tt);
			}
			return tt;
		}
		
		protected function processComment(str:String):void {
			m_string = str;
			begin();
			var commentStart:int = -1;
			while(m_letter < m_string.length) {
				var c:String = getCharNext();
				switch(c) {
				case '/':
					if (getChar() == '*') {
						if (commentStart < 0) commentStart = m_letter - 1;
						next();
					}
					break;
				case '*':
					if (getChar() == '/') {
						if (commentStart >= 0) {
							m_string = remove(m_string, commentStart, m_letter);
							m_letter = commentStart;
							commentStart = -1;
						}
						else {
							warning("", MWarning.UNOPENED_COMMENT, "");
						}
					}
					break;
				default:
					break;
				}
			}
			if (commentStart >= 0) warning("", MWarning.UNCLOSED_COMMENT, "");

			// 外部プログラム用のクォーテーション
			begin();
			commentStart = -1;
			while(m_letter < m_string.length) {
				if (getCharNext() == '`') {
					if (commentStart < 0) {
						commentStart = m_letter - 1;
					}
					else {
						m_string = remove(m_string, commentStart, m_letter-1);
						m_letter = commentStart;
						commentStart = -1;
					}
				}
			}
			// trace(m_string);
		}

		protected function processGroupNotes():void {
			var GroupNotesStart:int = -1;
			var GroupNotesEnd:int;
			var noteCount:int = 0;
			var repend:int, len:int, tick:int, tick2:int, tickdiv:Number, noteTick:int, noteOn:int;
			var lenMode:int;
			var defLen:int = 96;
			var newstr:String;
			begin();
			while (m_letter < m_string.length) {
				var c:String = getCharNext();
				switch(c) {
					case 'l':
						defLen = len2tick(getUInt(0));
						defLen = getDot(defLen);
						break;
					case '{':
						GroupNotesStart = m_letter - 1;
						noteCount = 0;
						break;
					case '}':
						repend = m_letter;
						if (GroupNotesStart < 0) {
							warning("", MWarning.UNOPENED_GROUPNOTES, "");
						}
						tick = 0;
						while (1) {
							if (getChar() != '%') {
								lenMode = 0;
							}
							else {
								lenMode = 1;
								next();
							}
							len = getUInt(0);
							if (len == 0) {
								if (tick == 0) tick = defLen;
								break;
							}
							tick2 = (lenMode ? len : len2tick(len));
							tick2 = getDot(tick2);
							tick += tick2;
							if (getChar() != '&') {
								break;
							}
							next();
						}
						GroupNotesEnd = m_letter;
						m_letter = GroupNotesStart + 1;
						newstr = m_string.substring(0, GroupNotesStart);
						tick2 = 0;
						tickdiv = Number(tick) / Number(noteCount);
						noteCount = 1;
						noteOn = 0;
						while (m_letter < repend) {
							c = getCharNext();
							switch (c) {
								case '+':
								case '#':
								case '-':
									break;

								default:
									if ((c >= 'a' && c <= 'g') || c == 'r') {
										if (noteOn == 0) {
											noteOn = 1;
											break;
										}
									}
									if (noteOn == 1) {
										noteTick = Math.round(Number(noteCount) * tickdiv - Number(tick2));
										noteCount++;
										tick2 += noteTick;
										if (tick2 > tick) {
											noteTick -= (tick2 - tick);
											tick2 = tick;
										}
										newstr += "%";
										newstr += String(noteTick);
									}
									noteOn = 0;
									if ((c >= 'a' && c <= 'g') || c == 'r') {
										noteOn = 1;
									}
									break;
							}
							if (c != '}') {
								newstr += c;
							}
						}
						m_letter = newstr.length;
						newstr += m_string.substring(GroupNotesEnd);
						m_string = newstr;
						GroupNotesStart = -1;
						break;
					default:
						if ((c >= 'a' && c <= 'g') || c == 'r') {
							noteCount++;
						}
						break;
				}
			}
			if (GroupNotesStart >= 0) warning("", MWarning.UNCLOSED_GROUPNOTES, "");
		}

		static public function removeWhitespace(str:String):String {
			return str.replace(new RegExp("[ 　\n\r\t\f]+","g"),"");
		}

		static public function remove(str:String, start:int, end:int):String {
			return str.substring(0, start) + str.substring(end+1);
		}

		public function play(str:String):Boolean {
			if (m_sequencer == null) {
				return false;
			}
			if (m_sequencer.isPaused()) {
				m_sequencer.play();
				return true;
			}
			m_sequencer.disconnectAll();
			m_warning = new String();
			m_tracks = new Vector.<MTrack>();

			//全トラックに適用される変数のみ初期化。トラックごとの初期化はcreateTrack()に移動。
			m_tempo  = MTrack.DEFAULT_BPM;

			m_form = MOscillator.PULSE;		//MOscillator.asで初期化されるのでここは形式的。

			m_usingPoly = false;
			m_polyVoice = 1;
			m_polyForce = false;

			m_metaTitle   = "";
			m_metaArtist  = "";
			m_metaCoding  = "";
			m_metaComment = "";


			//システム管理用トラックの確保。兼、関連スタティック領域のスタンバイ（メタデータ処理前の準備）。
			m_tracks[0] = createTrack();

			//ＭＭＬ解析の準備
			processComment(str);
			//trace(m_string+"\n\n");
			processMacro();
			//trace(m_string);
			m_string = removeWhitespace(m_string);
			processRepeat();
			//trace(m_string);
			processGroupNotes();
			//trace(m_string);

			//第１トラックを確保し、ＭＭＬ解析開始
			m_tracks[MTrack.FIRST_TRACK] = createTrack();
			m_trackNo = MTrack.FIRST_TRACK;
			MTrack.s_IRRequestLastTrack = 0;		//無限リピート要求用のスタティック変数を念のため初期化
			process();


			// omit
			if (m_tracks[m_tracks.length-1].getNumEvents() == 0) m_tracks.pop();

			//各トラックの累積デルタを締め切る。（タイで終了する場合など、最終累積デルタが確定していない場合を想定）
			for (i = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
				if (i > MTrack.TEMPO_TRACK) {
					m_tracks[i].recNOP();		//終端を揃えるためのnop
				}
			}

			// 無限リピートに問題がないかチェック
			checkIRepeatERR();

			// conduct ：テンポトラックに書き込まれたテンポを同時刻の各トラックに配信。
			m_tracks[MTrack.TEMPO_TRACK].conduct(m_tracks);

			// report要求に応じた表示
			if (s_reportTotalTicks == true) {
				reportTotalTicksEveryTrack();
			}

			// 再生時間の制限確認
			var playtimeMSec:uint = m_tracks[MTrack.TEMPO_TRACK].getTotalMSec();
			if (playtimeMSec >= (24.0 * 3600.0 * 1000.0)) {
				//無限リピートせずに２４時間以上の再生はエラー扱い
				m_warning += "再生時間が、無限リピートせずに２４時間を超えるため異常終了します。\n";
				dispatchEvent(new MMLEvent(MMLEvent.COMPILE_COMPLETE, false, false, 0, 0));
				return false;
			}

			// 無限リピート要求に対する処理
			processIRepeat();

			// post process
			for(var i:int = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
				if (i > MTrack.TEMPO_TRACK) {
					if (m_usingPoly && (m_polyForce || m_tracks[i].findPoly())) {
						m_tracks[i].usingPoly(m_polyVoice);
					}
				}
				m_tracks[i].recRestMSec(4000);
				m_tracks[i].recClose();
				m_tracks[i].recEOT();
				m_sequencer.connect(m_tracks[i]);
			}
			m_tracks[MTrack.TEMPO_TRACK].addTotalMSec(4000);		//上記recRestMSec()と同じだけ指定すること

			// dispatch event
			dispatchEvent(new MMLEvent(MMLEvent.COMPILE_COMPLETE, false, false, 0, 0));

			// play start
			m_sequencer.play();

			return true;
		}

		public function stop():void {
			m_sequencer.stop();
		}

		public function pause():void {
			m_sequencer.pause();
		}

		public function resume():void {
			m_sequencer.play();
		}

		public function setMasterVolume(vol:int):void {
			m_sequencer.setMasterVolume(vol);
		}

		public function getGlobalTick():uint {
			return m_sequencer.getGlobalTick();
		}

		public function isPlaying():Boolean {
			return m_sequencer.isPlaying();
		}

		public function isPaused():Boolean {
			return m_sequencer.isPaused();
		}

		public function getTotalMSec():uint {
			return m_tracks[MTrack.TEMPO_TRACK].getTotalMSec();
		}
		public function getTotalTimeStr():String {
			return m_tracks[MTrack.TEMPO_TRACK].getTotalTimeStr();
		}
		public function getNowMSec():uint {
			return m_sequencer.getNowMSec();
		}
		public function getNowTimeStr():String {
			return m_sequencer.getNowTimeStr();
		}
		public function getVoiceCount():int {
			var i:int;
			var c:int = 0;
			for (i = 0; i < m_tracks.length; i++) {
				c += m_tracks[i].getVoiceCount();
			}
			return c;
		}		
		public function getMetaTitle():String {
			return m_metaTitle;
		}
		public function getMetaComment():String {
			return m_metaComment;
		}
		public function getMetaArtist():String {
			return m_metaArtist;
		}
		public function getMetaCoding():String {
			return m_metaCoding;
		}

		public function checkIRepeatERR():void {
			var i:int;
			var tt0:uint;
			var tt1:uint;
			var tmatch:Boolean;
			
			//空の無限リピート指定への対策
			tmatch = true;
			for (i = MTrack.FIRST_TRACK; i < m_tracks.length; i++) {
				if (m_tracks[i].m_IRepeatF == true) {
					tt0 = m_tracks[i].reportTotalTicks();
					tt1 = m_tracks[i].m_IRepeatGtReq;
					if (tt0 == tt1) {
						m_warning += "[Track:" + i + "] 無限リピート配置後からトラック終端までに、音符または休符がありません。\n";
						tmatch = false;
					}
				}
			}
			if (tmatch == false) {
				m_warning += "曲全体の無限リピート指定を無効にします。\n";
				for (i = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
					m_tracks[i].m_IRepeatF = false;
				}
			}
		}

		public function processIRepeat():void {
			var i:int;
			var tt0:uint;
			var tt1:uint;
			var tmatch:Boolean;
			var ireptEntryGT:uint;
			var ireptEntryPT:int;

			//前準備として無限リピート受付完了フラグをfalseにしておく
			MTrack.s_infiniteRepeatF = false;

			//無限リピート要求が１個も無かったら終了。
			if (m_tracks[MTrack.TEMPO_TRACK].m_IRepeatF == false) {
				return;
			}

			//無限リピート用トラックチェック。厳密モードかどうかで場合分け
			if (m_tracks[MTrack.TEMPO_TRACK].m_IRCheckStrictlyF == true) {
				
				//厳密チェックモード（テンポ設定が先頭以外にもある場合）
				//無限リピート要求中の各トラックの、累積ticks数が一致してなければ、一致を促して終了。
				tmatch = true;
				tt0 = m_tracks[MTrack.TEMPO_TRACK].reportTotalTicks();
				for (i = MTrack.FIRST_TRACK; i < m_tracks.length; i++) {
					tt1 = m_tracks[i].reportTotalTicks();
					if (m_tracks[i].m_IRepeatF == false) {
						if (tt1 <= tt0) {
							continue;
						}
						else {
							tmatch = false;
							m_warning += "[厳密MODE]無限リピート対象外トラックは、対象トラックの累積tickカウント数以下のticks数にしてください。track:" + i + "\n";
							reportTotalTicksEveryTrack();
							break;
						}
					}
					else if (tt1 != tt0) {
						tmatch = false;
						m_warning += "[厳密MODE]無限リピートは、対象各トラックで累積tickカウント数が一致している場合に受け付けます。\n";
						m_warning += "（TEMPO MANAGE TRACKは、最長ticksトラックに合わされ、リピート末尾の基準になります）\n";
						reportTotalTicksEveryTrack();
						break;
					}
				}
				if (tmatch == false) {
					m_warning += "曲全体の無限リピート指定を無効にします。\n";
					return;
				}
				
				//無限リピート対象ラックのリピートエントリ位置が同じglobalticksかどうか確認
				tmatch = true;
				tt0 = m_tracks[MTrack.TEMPO_TRACK].m_IRepeatGtReq;			//最終記録状態をマスターとする。
				for (i = MTrack.FIRST_TRACK; i < m_tracks.length; i++) {
					if (m_tracks[i].m_IRepeatF == true) {
						tt1 = m_tracks[i].m_IRepeatGtReq;
						if (tt0 != tt1) {
							tmatch = false;
							m_warning += "[厳密MODE]無限リピートは、他のトラックとエントリ位置（ticks数）が一致している場合に受け付けます。track:" + i + "\n";
							reportTotalTicksEveryTrack();
							break;
						}
					}
				}
				if (tmatch == false) {
					m_warning += "曲全体の無限リピート指定を無効にします。\n";
					return;
				}
				
				//各トラックへのリピートエントリ登録
				for (i = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
					if (m_tracks[i].m_IRepeatF == true) {
						ireptEntryGT = m_tracks[i].m_IRepeatGtReq;
						//リピートエントリになるイベントを挿入
						m_tracks[i].recRepeatEntry(ireptEntryGT);
						m_tracks[i].recNOPforIRepeat(ireptEntryGT);		//ゲートタイム等のdeltaを吸収
						//リピートエントリポインタ登録
						ireptEntryPT = m_tracks[i].getIRepeatPointer(ireptEntryGT);
						m_tracks[i].m_IRepeatPt = ireptEntryPT;
						m_tracks[i].m_IRepeatGt = ireptEntryGT;
						//無限リピート用ジャンプコマンド挿入（セット済みポインタへ飛ぶコマンド）
						m_tracks[i].recJumpToRept();
					}
				}
				MTrack.s_infiniteRepeatF = true;		//無限リピート受付完了
			}
			else {
				//規制緩和モードでの無限リピート処理
				//トータルticks数、エントリ位置の制限なく、各トラックへのリピートエントリ登録
				for (i = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
					if (m_tracks[i].m_IRepeatF == true) {
						ireptEntryGT = m_tracks[i].m_IRepeatGtReq;
						//リピートエントリになるイベントを挿入
						m_tracks[i].recRepeatEntry(ireptEntryGT);
						m_tracks[i].recNOPforIRepeat(ireptEntryGT);		//ゲートタイム等のdeltaを吸収
						//リピートエントリポインタ登録
						ireptEntryPT = m_tracks[i].getIRepeatPointer(ireptEntryGT);
						m_tracks[i].m_IRepeatPt = ireptEntryPT;
						m_tracks[i].m_IRepeatGt = ireptEntryGT;
						//無限リピート用ジャンプコマンド挿入（セット済みポインタへ飛ぶコマンド）
						m_tracks[i].recJumpToRept();
					}
				}
				MTrack.s_infiniteRepeatF = true;		//無限リピート受付完了
			}
		}

		public function reportTotalTicksEveryTrack():void {
			var tt:uint;
			var re:uint;
			var rt:uint;
			m_warning += "<report> Total Ticks\n";
			for (var i:int = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
				tt = m_tracks[i].reportTotalTicks();
				m_warning += "Track" + i + " : " + tt;
				if (i == MTrack.TEMPO_TRACK) {
					if (m_tracks[i].m_IRepeatF == true) {
						re = m_tracks[i].m_IRepeatGtReq;
						rt = tt - re;
						if (m_tracks[i].m_IRCheckStrictlyF == true) {
							m_warning += " / repEntry:" + re + ", repTotal:" + rt + "【無限リピート厳密モード】";
						}
						else {
							m_warning += " / repEntry:" + re + ", repTotal:" + rt + "【無限リピート規制緩和モード】";
						}
					}
					else {
						m_warning += " / no Repeat";
					}
					m_warning += " (for SYSTEM:TEMPO MANAGE TRACK)";
				}
				else {
					if (m_tracks[i].m_IRepeatF == true) {
						re = m_tracks[i].m_IRepeatGtReq;
						rt = tt - re;
						m_warning += " / repEntry:" + re + ", repTotal:" + rt;
					}
					else {
						m_warning += " / no Repeat";
					}
				}
				m_warning += "\n";
			}
		}

	}
}
