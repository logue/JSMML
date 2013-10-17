package com.flmml {
	import __AS3__.vec.Vector;

	public class MOscMod {
		public    var m_modID:int;
		protected var m_frequency:Number;
		protected var m_freqShift:Number;
		protected var m_phase:Number;
		protected var m_phaseResetMode:int;
		protected var m_phaseResetPoint:Number;
		protected var m_phaseOnetimeResetReq:Boolean;
		protected var m_infoPdif:uint;
		protected var m_infoIsPlaying:Boolean;

		public function MOscMod() {
			setFrequency(440.0);
			//m_phase関連の初期化。setPhaseResetMode(),resetPhase(),resetPhasePos() への準備。
			m_phase = 0.0;						//位相位置０
			m_phaseResetMode = 1;				//ノートオンの都度フェーズリセット（負の値にしないこと）
			m_phaseResetPoint = 0.0;			//リセット位置０
			m_phaseOnetimeResetReq = false;		//ワンタイムフェーズリセット無し
			//通知される演奏情報の初期化。
			m_infoPdif = 1;
			m_infoIsPlaying = false;
		}

		public function setPhaseResetMode(mode:int, phase:Number):void {
			if (mode != m_phaseResetMode || phase != m_phaseResetPoint) {
				if (mode >= 0) {
					m_phaseResetMode = mode;
					
					if (phase >= 0.0) {
						m_phaseResetPoint = phase % 1.0;
					}
					else {
						m_phaseResetPoint = (-1.0);
					}
					
					//位相リセットモード設定を受け付けた場合、必ずワンタイムフェーズリセット要求を行う
					m_phaseOnetimeResetReq = true;
				}
				else {
					//モードがマイナス指定の場合はワンタイムフェーズリセット要求のみ行い、設定変更はしない。
					m_phaseOnetimeResetReq = true;
				}
			}
			/* 
			 * m_phaseResetModeとm_phaseResetPointのいずれも変更がなければ処理なし。
			 * モードがマイナス指定の場合はm_phaseResetModeに採用しないので、
			 * 常にm_phaseResetModeへの変更ありとみなされる仕様
			 */
		}

		public function setPlayingInfo(pdif:uint, isPlaying:Boolean):void {
			m_infoPdif = pdif;
			m_infoIsPlaying = isPlaying;
		}

		public function resetPhaseExec():void {
			if (m_phaseResetPoint >= 0.0) {
				m_phase = m_phaseResetPoint;
			}
			else {
				m_phase = Math.random();
			}
		}

		public function resetPhase():void {
			if (m_phaseOnetimeResetReq == true) {
				resetPhaseExec();
				m_phaseOnetimeResetReq = false;
			}
			else {
				switch (m_phaseResetMode) {
				case 0:
					break;
				case 1:
				default:
					resetPhaseExec();
					break;
				case 2:
					if (m_infoPdif != 0) resetPhaseExec();
					break;
				case 3:
					if (m_infoIsPlaying == false) resetPhaseExec();
					break;
				}
			}
		}

		public function addPhase(time:int):void {
			m_phase = (m_phase + (m_freqShift * Number(time))) % (1.0);
		}

		public function getNextSample():Number {
			return (0.0);
		}

		public function getSamples(samples:Vector.<Number>, start:int, end:int):void {
		}

		public function getFrequency():Number {
			return m_frequency;
		}

		public function setFrequency(frequency:Number):void {
			m_frequency = frequency;
			m_freqShift = frequency / 44100.0;
		}

		public function setNoiseFreq(index:Number):void {
		}

		public function setWaveNo(waveNo:int):void {
		}

		public function setNoteNo(noteNo:int):void {
		}

		public function setYControl(m:int, f:int, n:Number):void {
			//m:モジュール番号, f:機能番号, n:パラメータ
			//原則的に次の機能番号を共通とし、他は各自拡張する
			if (m_modID != m) return;
			switch (f) {
			default:
			case 0:		//func.0: No Operation
				break;
			case 1:		//func.1: setWaveNo
				break;
			case 2:		//func.2: setRenderFunc
				break;
			case 3:		//func.3: setDetune
				break;
			case 4:		//func.4: reserved
				break;
			}
		}

	}
}
