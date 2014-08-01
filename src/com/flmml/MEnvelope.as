package com.flmml {
	import __AS3__.vec.Vector;

	// 多節エンベロープ機能
	public class MEnvelope {
		public static const EPM_NORMAL:int   = 0;
		public static const EPM_LOOP_ENT:int = 1;
		public static const EPM_REL_ENT:int  = 2;
		public static var s_envClockMode:Boolean = false;		//falseのとき、s_envClockは固定時間。trueのとき、s_envClockは1tick（テンポ依存）。
		public static var s_envClockMgnf:Number = 1.0;
		public static var s_envClock:Number = 1.0 / 120.0;
		public static var s_envResolMode:int = (-1);			//-1:s_envResol未使用(最大解像度), 0:s_envResol固定時間, 1:s_envResolは1tick（テンポ依存）
		public static var s_envResolMgnf:Number = 1.0;
		public static var s_envResol:Number = 1.0;

		private var m_atkContStart:Boolean;
		private var m_lvRoundM_Req:int;
		private var m_lvRoundMode:int;
		private var m_envelopeStartPoint:MEnvelopePoint;
		private var m_envelopeLoopPoint:MEnvelopePoint;
		private var m_envelopeLastPoint:MEnvelopePoint;
		private var m_releaseStartPoint:MEnvelopePoint;
		private var m_currentPoint:MEnvelopePoint;
		private var m_currentVal:Number;
		private var m_releasing:Boolean;
		private var m_step:Number;
		private var m_playing:Boolean;
		private var m_counter:int;
		private var m_timeInSamples:int;
		private var m_releaseStartForDampOff:MEnvelopePoint;
		
		private var m_envClockMode:Boolean;
		private var m_envClockMgnf:Number;
		private var m_envClock:Number;
		private var m_envResolMode:int;
		private var m_envResolMgnf:Number;
		private var m_envResol:Number;
		private var m_envResolCnt:Number;
		private var m_envResolVal:Number;

		public function MEnvelope(id:int, attack:Number, atksus:Number, decay:Number, sustain:Number, release:Number, relsus:Number) {
			m_releaseStartPoint = new MEnvelopePoint(id);	//リリース先端を事前に作成。終端はあえて事前作成せず、ＭＭＬ側でリリース未記述をはじく。
			m_playing = false;
			m_currentVal = 0.0;
			m_releasing = true;
			m_lvRoundM_Req = -1;
			m_lvRoundMode = 0;
			//static初期設定の引き継ぎ
			m_envClockMode = s_envClockMode;
			m_envClockMgnf = s_envClockMgnf;
			m_envClock = s_envClock;
			m_envResolMode = s_envResolMode;
			m_envResolMgnf = s_envResolMgnf;
			m_envResol = s_envResol;
			m_envResolCnt = m_envResol;
			m_envResolVal = 0.0;
			//初期エンベロープデータの作成
			newPoint(id, 0.0, true, 0);
			addPoint(id, true, attack, atksus, EPM_NORMAL);
			addPoint(id, true, decay, sustain, EPM_NORMAL);
			addPoint(id, true, release, relsus, EPM_REL_ENT);
			//強制消音用リリースポイントの作成
			m_releaseStartForDampOff      = new MEnvelopePoint(id);
			m_releaseStartForDampOff.next = new MEnvelopePoint(id);
			m_releaseStartForDampOff.next.index  = 1;
			m_releaseStartForDampOff.next.r_mode = false;
			m_releaseStartForDampOff.next.rate   = 1.0;
			m_releaseStartForDampOff.next.time   = (44100.0 / 2000.0);		//固定時間 1/2000sec で消音レベルに達する
			m_releaseStartForDampOff.next.level  = 0.0;
			m_releaseStartForDampOff.next.next   = null;
		}

		public static function boot():void {
		}

		public function newPoint(id:int, initlevel:Number, atk_mode:Boolean, lvRd_mode:int):void {
			m_envelopeStartPoint = new MEnvelopePoint(id);
			m_envelopeLastPoint = m_envelopeStartPoint;
			m_envelopeLoopPoint = null;
			m_envelopeStartPoint.r_mode = true;
			m_envelopeStartPoint.rate = 0.0;
			m_envelopeStartPoint.time = 0.0;
			m_envelopeStartPoint.level = initlevel;
			m_atkContStart = atk_mode;
			m_lvRoundM_Req = lvRd_mode;
		}
		public function addPoint(id:int, r_mode:Boolean, rate:Number, level:Number, p_mode:int):void {
			var point:MEnvelopePoint = new MEnvelopePoint(id);	//今回ポイント作成
			point.index = m_envelopeLastPoint.index + 1;
			point.r_mode = r_mode;
			point.rate = rate;
			point.time = (r_mode) ? (int((Number(rate) * m_envClock) * 44100.0)) : 0;
			point.level = level;
			switch (p_mode) {
			case EPM_NORMAL:		//通常エントリ登録
			default:
				m_envelopeLastPoint.next = point;	//前回ポイントの「次回」を今回ポイントにする。
				m_envelopeLastPoint = point;		//今回ポイントを追加末尾ポイントとして更新
				break;
			case EPM_LOOP_ENT:		//ループエントリ登録
				m_envelopeLoopPoint = point;		//ループエントリ登録
				m_envelopeLastPoint.next = point;	//前回ポイントの「次回」を今回ポイントにする。
				m_envelopeLastPoint = point;		//今回ポイントを追加末尾ポイントとして更新
				break;
			case EPM_REL_ENT:		//リリースエントリ登録
				m_releaseStartPoint.next = point;		//リリースエントリ登録
				if (m_envelopeLoopPoint == null) {
					//ループしない場合、前回ポイントの次を打ち止めし、サスティン終端とする
					m_envelopeLastPoint.next = null;
				}
				else {
					//ループする場合、前回ポイントの次をループエントリにする
					if (m_envelopeLastPoint != m_envelopeLoopPoint) {
						m_envelopeLastPoint.next = m_envelopeLoopPoint;
					}
					else {
						//自分自身にループするような場合はループ要求を無視する
						m_envelopeLastPoint.next = null;
					}
				}
				m_envelopeLastPoint = point;		//今回ポイントを追加末尾ポイントとして更新
				/*
				 * 過去仕様では、ノートオン中（タイ）でエンベロープ変更がかかった場合に、
				 * エンベロープシーケンスポイントを同位置に進めて、現在のボリュームを引継ぐ処理
				 * があったが、今仕様では廃止。
				 * タイ中にエンベロープ更新した場合、即時、指定エンベロープ先頭にトリガする。
				*/
				break;
			}
		}

		public function triggerEnvelope():void {
			m_playing = true;
			m_releasing = false;
			if (m_lvRoundM_Req >= 0) {
				m_lvRoundMode = m_lvRoundM_Req;
				m_lvRoundM_Req = -1;
			}
			m_currentPoint = m_envelopeStartPoint;
			if (m_atkContStart == false) {
				m_currentVal = m_currentPoint.level		//attack初期レベル強制初期化モードのとき、初期化
			}
			if (m_currentPoint.next.r_mode == false) {
				if (m_currentPoint.next.rate != 0.0) {
					m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * m_envClock);
				}
				else {
					m_currentPoint.next.time = 0.0;
				}
			}
			else {
				m_currentPoint.next.time = m_currentPoint.next.rate * m_envClock * 44100.0;
			}
			m_step = (m_currentPoint.next.level - m_currentVal) / m_currentPoint.next.time;
			m_timeInSamples = 0;
			m_counter = 0;
			m_envResolCnt = m_envResol;		//解像度有効時triggerEnvelope()の直後の初回getNextAmplitudeLinear()で必ずリフレッシュさせるため
		}

		public function releaseEnvelope():void {
			m_releasing = true;
			m_currentPoint = m_releaseStartPoint;
			m_currentPoint.level = m_currentVal;
			if (m_currentPoint.next.r_mode == false) {
				if (m_currentPoint.next.rate != 0.0) {
					m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * m_envClock);
				}
				else {
					m_currentPoint.next.time = 0.0;
				}
			}
			else {
				m_currentPoint.next.time = m_currentPoint.next.rate * m_envClock * 44100.0;
			}
			m_step = (m_currentPoint.next.level - m_currentVal) / m_currentPoint.next.time;
			m_counter = 0;
		}

		public function releaseEnvelopeForDampOff():void {
			m_releasing = true;
			m_currentPoint = m_releaseStartForDampOff;
			m_currentPoint.level = m_currentVal;
			m_step = (m_currentPoint.next.level - m_currentVal) / m_currentPoint.next.time;
			m_counter = 0;
		}

		public function soundOff():void {
			releaseEnvelopeForDampOff();
		}

		public function getNextAmplitudeLinear():Number {
			if (m_playing == false) return 0.0;
			
			if (m_currentPoint.next == null) {	// sustain phase
				m_currentVal = m_currentPoint.level;
			}
			else {
				var processed:Boolean = false;
				while (m_counter >= m_currentPoint.next.time) {
					m_counter = 0;
					m_currentPoint = m_currentPoint.next;		//エンベロープポイントを次に進める
					if (m_currentPoint.next == null) {
						m_currentVal = m_currentPoint.level;
						processed = true;
						break;
					}
					else {
						if (m_currentPoint.next.r_mode == false) {
							if (m_currentPoint.next.rate != 0.0) {
								m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * m_envClock);
							}
							else {
								m_currentPoint.next.time = 0.0;
							}
						}
						else {
							m_currentPoint.next.time = m_currentPoint.next.rate * m_envClock * 44100.0;
						}
						m_step = (m_currentPoint.next.level - m_currentPoint.level) / m_currentPoint.next.time;
						m_currentVal = m_currentPoint.level;
						processed = true;
					}
				}
				if (processed == false) {
					m_currentVal += m_step;
				}
				m_counter++;
			}
			if (m_currentVal > 1.0) m_currentVal = 1.0;		//上限値でクリッピング
			if (m_currentVal <= 0.0) {
				m_currentVal = 0.0;
				if (m_releasing == true) {
					m_playing = false;
				}
			}
			m_timeInSamples++;
			//if (m_currentVal > 1.0) trace("m_currentVal over 1.0");

			if (m_envResolMode < 0) {
				m_envResolVal = m_currentVal;		//毎回更新
			}
			else {
				m_envResolCnt += 1.0;
				if (m_envResolCnt > m_envResol) {
					m_envResolCnt -= m_envResol;
					m_envResolVal = m_currentVal;	//指定間隔更新
				}
			}
			
			return m_currentVal;
		}

		public function ampSamplesLinear(samples:Vector.<Number>, start:int, end:int, ampLevel:Number, mixLevel:Number, volLevel:Number, vRate:Number, vIndex:Number, vMax:Number):void {
			var i:int;
			var v:Number;
			var ex:Number;
			var amplitude:Number;
			
			switch (m_lvRoundMode) {
			case 0:
			default:
				//なめらかモード
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					ex = getNextAmplitudeLinear();
					
					amplitude = ex;		//amplitude = (ex * vIndex) / vIndex;
					
					if (amplitude > 1.0) amplitude = 1.0;
					if (amplitude < 0.0) amplitude = 0.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 1:
				//ガクガク整数モード（少数以下切り上げ）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.ceil(ex * vIndex);
					amplitude = v / vIndex;
					
					if (amplitude > 1.0) amplitude = 1.0;
					if (amplitude < 0.0) amplitude = 0.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 2:
				//ガクガク整数モード（TYPE-S）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.floor(ex * (vIndex + 1.0));
					if (v > vIndex) v = vIndex;
					amplitude = v / vIndex;
					
					if (amplitude > 1.0) amplitude = 1.0;
					if (amplitude < 0.0) amplitude = 0.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 3:
				//ガクガク整数モード（TYPE-Y）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.floor(ex * vIndex);
					amplitude = v / vIndex;
					
					if (amplitude > 1.0) amplitude = 1.0;
					if (amplitude < 0.0) amplitude = 0.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 4:
				//ガクガク整数モード（TYPE-D4）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					if (!m_releasing) {
						v = Math.floor(ex * vIndex);
						amplitude = v / vIndex;
						
						if (amplitude > 1.0) amplitude = 1.0;
						if (amplitude < 0.0) amplitude = 0.0;
						samples[i] *= (ampLevel * amplitude);
					}
					else {
						//リリース中にvolumeをキャンセル
						v = Math.floor(ex * vMax);
						amplitude = v / vMax
						
						if (amplitude > 1.0) amplitude = 1.0;
						if (amplitude < 0.0) amplitude = 0.0;
						samples[i] *= (mixLevel * amplitude);
					}
				}
				break;
			}
		}

		public function ampSamplesNonLinear(samples:Vector.<Number>, start:int, end:int, ampLevel:Number, mixLevel:Number, volLevel:Number, vRate:Number, vIndex:Number, vMax:Number):void {
			var i:int;
			var v:Number;
			var ex:Number;
			var amplitude:Number;
			
			switch (m_lvRoundMode) {
			case 0:
			default:
				//なめらかモード
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					ex = getNextAmplitudeLinear();
					
					if (ex > 0.0) { amplitude = Math.pow( 10.0, (((ex - 1.0) * vMax * vRate) / 20.0) ); }
					else          { amplitude = 0.0; }
					
					if (amplitude > 1.0) amplitude = 1.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 1:
				//ガクガク整数モード（少数以下切り上げ）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.ceil(ex * vIndex);
					if (v > 0.0) { amplitude = Math.pow( 10.0, (((v - vIndex) * vRate) / 20.0) ); }
					else         { amplitude = 0.0; }
					
					if (amplitude > 1.0) amplitude = 1.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 2:
				//ガクガク整数モード（TYPE-S）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.floor(ex * (vIndex + 1.0));
					if (v > vIndex) v = vIndex;
					if (v > 0.0) { amplitude = Math.pow( 10.0, (((v - vIndex) * vRate) / 20.0) ); }
					else         { amplitude = 0.0; }
					
					if (amplitude > 1.0) amplitude = 1.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 3:
				//ガクガク整数モード（TYPE-Y）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					
					v = Math.floor(ex * vIndex);
					if (v > 0.0) { amplitude = Math.pow( 10.0, (((v - vIndex) * vRate) / 20.0) ); }
					else         { amplitude = 0.0; }
					
					if (amplitude > 1.0) amplitude = 1.0;
					samples[i] *= (ampLevel * amplitude);
				}
				break;
			case 4:
				//ガクガク整数モード（TYPE-D4）
				for(i = start; i < end; i++){
					if (!m_playing) { samples[i] = 0.0; continue; }		//非演奏中は無音で満たす
					getNextAmplitudeLinear();
					ex = m_envResolVal;
					if (!m_releasing) {
						v = Math.floor(ex * vIndex);
						if (v > 0.0) { amplitude = Math.pow( 10.0, (((v - vIndex) * vRate) / 20.0) ); }
						else         { amplitude = 0.0; }
						
						if (amplitude > 1.0) amplitude = 1.0;
						samples[i] *= (ampLevel * amplitude);
					}
					else {
						//リリース中にvolumeをキャンセル
						v = Math.floor(ex * vMax);
						if (v > 0.0) { amplitude = Math.pow( 10.0, (((v - vMax) * vRate) / 20.0) ); }
						else         { amplitude = 0.0; }
						
						if (amplitude > 1.0) amplitude = 1.0;
						samples[i] *= (mixLevel * amplitude);
					}
				}
				break;
			}
		}

		public function followSPT(spt:Number):void {
			var envclk:Number;
			if (m_envClockMode == true) {
				envclk = ((spt * m_envClockMgnf) / 44100.0);
				if (envclk < (44.1 / 44100.0)) envclk = 44.1 / 44100.0;		//超高速モードにつきあう限界
				m_envClock = envclk;										//エンベロープ時間単位の追従
			}
			if (m_envResolMode == 1) {
				envclk = (spt * m_envResolMgnf);
				if (envclk < 44.1) envclk = 44.1;							//tick依存モードの解像度は1msを下限とする
				m_envResol = envclk;
			}
		}

		public function setEnvClockParam(mode:int, num:Number):void {
			m_envClockMode = ((mode == 0) ? false : true       );
			m_envClockMgnf = ((mode == 0) ? (1.0) : num        );
			m_envClock =     ((mode == 0) ? num   : (1.0/120.0));
		}

		public function setEnvResolParam(mode:int, num:Number):void {
			if (mode == 0) {		//固定時間
				m_envResolMode = 0;
				m_envResolMgnf = 1.0;
				m_envResol = 44100.0 * num;
			}
			else if (mode == 1) {	//tickカウント依存
				m_envResolMode = 1;
				m_envResolMgnf = num;
				m_envResol = 44100.0 * num;		//暫定数値
			}
			else {				//解像度無効（最大解像度）
				m_envResolMode = (-1);
				m_envResolMgnf = 1.0;
				m_envResol = 1.0;
			}
		}

		public function isPlaying():Boolean {
			return m_playing;
		}

		public function isReleasing():Boolean {
			return m_releasing;
		}

	}
}
