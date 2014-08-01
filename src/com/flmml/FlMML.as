package com.flmml {
	import mx.core.UIComponent;

	public class FlMML extends UIComponent {
		public static const TSTAT_BPM:int		= MTrack.TSTAT_BPM;
		public static const TSTAT_NOTE:int		= MTrack.TSTAT_NOTE;
		public static const TSTAT_NOTE_NOW:int	= MTrack.TSTAT_NOTE_NOW;
		public static const TSTAT_NOTE_ON:int	= MTrack.TSTAT_NOTE_ON;
		public static const TSTAT_DETUNE:int	= MTrack.TSTAT_DETUNE;
		public static const TSTAT_P_RESO:int	= MTrack.TSTAT_P_RESO;
		public static const TSTAT_MIXVOL:int	= MTrack.TSTAT_MIXVOL;
		public static const TSTAT_VMODE_MAX:int	= MTrack.TSTAT_VMODE_MAX;
		public static const TSTAT_VMODE_RT:int	= MTrack.TSTAT_VMODE_RT;
		public static const TSTAT_VMODE_VZ:int	= MTrack.TSTAT_VMODE_VZ;
		public static const TSTAT_VOL:int		= MTrack.TSTAT_VOL;
		public static const TSTAT_PAN:int		= MTrack.TSTAT_PAN;
		public static const TSTAT_PAN_NOW:int	= MTrack.TSTAT_PAN_NOW;
		public static const TSTAT_PANLG:int		= MTrack.TSTAT_PANLG;
		public static const TSTAT_FORM:int		= MTrack.TSTAT_FORM;
		public static const TSTAT_SUBFORM:int	= MTrack.TSTAT_SUBFORM;
		public static const TSTAT_LFO_P:int		= MTrack.TSTAT_LFO_P;
		public static const TSTAT_LFO_A:int		= MTrack.TSTAT_LFO_A;
		public static const TSTAT_LFO_B:int		= MTrack.TSTAT_LFO_B;
		public static const TSTAT_LFO_F:int		= MTrack.TSTAT_LFO_F;
		public static const TSTAT_LFO_Y:int		= MTrack.TSTAT_LFO_Y;
		public static const TSTAT_LPF:int		= MTrack.TSTAT_LPF;
		public static const TSTAT_FORMANT:int	= MTrack.TSTAT_FORMANT;
		public static const TSTAT_PWM:int		= MTrack.TSTAT_PWM;
		public static const TSTAT_FM_HLFO:int	= MTrack.TSTAT_FM_HLFO;
		public static const TSTAT_NOISE_W:int	= MTrack.TSTAT_NOISE_W;
		public static const TSTAT_NOISE_FC:int	= MTrack.TSTAT_NOISE_FC;
		public static const TSTAT_NOISE_GB:int	= MTrack.TSTAT_NOISE_GB;
		public static const TSTAT_NOISE_PSG:int	= MTrack.TSTAT_NOISE_PSG;
		public static const TSTAT_MIDIPORT:int	= MTrack.TSTAT_MIDIPORT;
		public static const TSTAT_POLY:int		= MTrack.TSTAT_POLY;
		public static const TSTAT_FADE:int		= MTrack.TSTAT_FADE;
		public static const TSTAT_DELAY:int		= MTrack.TSTAT_DELAY;
		public static const TSTAT_MAX:int		= MTrack.TSTAT_MAX;
		
		public static const TSTAT_NOTE_MAX:int	= MTrack.TSTAT_NOTE_MAX;
		
		private var m_mml:MML;

		public function FlMML() {
			m_mml = new MML();
			var self:FlMML = this;
			m_mml.addEventListener(MMLEvent.COMPILE_COMPLETE, function(e:MMLEvent):void {
					self.dispatchEvent(new MMLEvent(MMLEvent.COMPILE_COMPLETE));
				});
			m_mml.addEventListener(MMLEvent.COMPLETE, function(e:MMLEvent):void {
					self.dispatchEvent(new MMLEvent(MMLEvent.COMPLETE));
				});
			m_mml.addEventListener(MMLEvent.BUFFERING, function(e:MMLEvent):void {
					self.dispatchEvent(new MMLEvent(MMLEvent.BUFFERING, false, false, 0, 0, e.progress));
				});
		}

		public function play(mml:String, start:uint=0):Boolean {
			return m_mml.play(mml,start);
		}

		public function stop():void {
			m_mml.stop();
		}

		public function pause():void {
			m_mml.pause();
		}

		public function isPlaying():Boolean {
			return m_mml.isPlaying();
		}
		public function isWorking():Boolean {
			return m_mml.isWorking();
		}

		public function isPaused():Boolean {
			return m_mml.isPaused();
		}

		public function setMasterVolume(vol:int):void {
			m_mml.setMasterVolume(vol);
		}

		public function getWarnings():String {
			return m_mml.getWarnings();
		}

		public function getTotalMSec():Number {
			return m_mml.getTotalMSec();
		}
		public function getTotalTimeStr():String {
			return m_mml.getTotalTimeStr();
		}
		public function getSndChannelPos():Number {
			return m_mml.getSndChannelPos();
		}
		public function getNowMSec():Number {
			return m_mml.getNowMSec();
		}
		public function getNowTimeStr():String {
			return m_mml.getNowTimeStr();
		}
		public function getVoiceCount():int {
			return m_mml.getVoiceCount();
		}
		public function geTotalVoiceAlloc():int {
			return m_mml.getTotalVoiceAlloc();
		}
		public function getTotalTrackNum():int {
			return m_mml.getTotalTrackNum();
		}
		public function sequenceTrackInfo_init(ofs:Number):void {
			m_mml.sequenceTrackInfo_init(ofs);
		}
		public function sequenceTrackInfo(msec:Number):void {
			m_mml.sequenceTrackInfo(msec);
		}
		public function isExistTrackInfo(track:int):Boolean {
			if (isWorking() == false) return false;
			if (track > (getTotalTrackNum()-1)) return false;		//tempoトラックを総数から除くため-1する
			else return true;
		}
		public function isPolyTrack(track:int):Boolean {
			var poly:Number;
			if (isWorking() == false) return false;
			poly = m_mml.getTrackInfo(track)[TSTAT_POLY];
			if (poly > 1.0) return true;
			else return false;
		}
		public function getTrackInfo(track:int):Vector.<Number> {
			return m_mml.getTrackInfo(track);
		}
		public function getTrackPolyNoteOn(track:int):Vector.<Number> {
			return m_mml.getTrackPolyNoteOn(track);
		}
		public function getMetaTitle():String {
			return m_mml.getMetaTitle();
		}
		public function getMetaComment():String {
			return m_mml.getMetaComment();
		}
		public function getMetaArtist():String {
			return m_mml.getMetaArtist();
		}
		public function getMetaCoding():String {
			return m_mml.getMetaCoding();
		}
	}
}
