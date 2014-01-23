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
		public static var s_envResolMode:int = (-1);				//-1:s_envResol未使用(最大解像度), 0:s_envResol固定時間, 1:s_envResolは1tick（テンポ依存）
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
		private var m_envResolCnt:Number;
		private var m_envResolVal:Number;
		private var m_releaseStartForDampOff:MEnvelopePoint;

		public function MEnvelope(id:int, attack:Number, atksus:Number, decay:Number, sustain:Number, release:Number, relsus:Number) {
			m_releaseStartPoint = new MEnvelopePoint(id);	//リリース先端を事前に作成。終端はあえて事前作成せず、ＭＭＬ側でリリース未記述をはじく。
			m_playing = false;
			m_currentVal = 0.0;
			m_envResolVal = 0.0;
			m_releasing = true;
			m_lvRoundM_Req = -1;
			m_lvRoundMode = 0;
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
			point.time = (r_mode) ? (int((Number(rate) * s_envClock) * 44100.0)) : 0;
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
					m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * s_envClock);
				}
				else {
					m_currentPoint.next.time = 0.0;
				}
			}
			else {
				m_currentPoint.next.time = m_currentPoint.next.rate * s_envClock * 44100.0;
			}
			m_step = (m_currentPoint.next.level - m_currentVal) / m_currentPoint.next.time;
			m_timeInSamples = 0;
			m_counter = 0;
			m_envResolCnt = s_envResol;		//解像度有効時triggerEnvelope()の直後の初回getNextAmplitudeLinear()で必ずリフレッシュさせるため
		}

		public function releaseEnvelope():void {
			m_releasing = true;
			m_currentPoint = m_releaseStartPoint;
			m_currentPoint.level = m_currentVal;
			if (m_currentPoint.next.r_mode == false) {
				if (m_currentPoint.next.rate != 0.0) {
					m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * s_envClock);
				}
				else {
					m_currentPoint.next.time = 0.0;
				}
			}
			else {
				m_currentPoint.next.time = m_currentPoint.next.rate * s_envClock * 44100.0;
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
								m_currentPoint.next.time = (Math.abs(m_currentPoint.next.level - m_currentVal) / (1.0 / m_currentPoint.next.rate)) * (44100.0 * s_envClock);
							}
							else {
								m_currentPoint.next.time = 0.0;
							}
						}
						else {
							m_currentPoint.next.time = m_currentPoint.next.rate * s_envClock * 44100.0;
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

			if (s_envResolMode < 0) {
				return m_currentVal;
			}
			else {
				m_envResolCnt += 1.0;
				if (m_envResolCnt > s_envResol) {
					m_envResolCnt -= s_envResol;
					m_envResolVal = m_currentVal;
				}
				return m_envResolVal;
			}
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
					
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
					ex = getNextAmplitudeLinear();
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

		public function isPlaying():Boolean {
			return m_playing;
		}

		public function isReleasing():Boolean {
			return m_releasing;
		}

	}
}
