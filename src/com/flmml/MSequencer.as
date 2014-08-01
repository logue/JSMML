package com.flmml {
	import __AS3__.vec.Vector;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.*;

	public class MSequencer extends EventDispatcher {
		public static const BUFFER_SIZE:int         = 8192;
		public static const RATE44100:int           = 44100;

		protected static const STATUS_STOP:int      = 0;
		protected static const STATUS_PAUSE:int     = 1;
		protected static const STATUS_BUFFERING:int = 2;
		protected static const STATUS_PLAY:int      = 3;
		protected static const STATUS_LAST:int      = 4;
		protected static const STEP_NONE:int     = 0;
		protected static const STEP_PRE:int      = 1;
		protected static const STEP_TRACK:int    = 2;
		protected static const STEP_POST:int     = 3;
		protected static const STEP_COMPLETE:int = 4;
		protected var m_sound:Sound;
		protected var m_soundChannel:SoundChannel;
		protected var m_soundTransform:SoundTransform;
		protected var m_buffer:Vector.<Vector.<Number>>;
		protected var m_playSide:int;
		protected var m_playSize:int;
		protected var m_step:int;
		protected var m_processTrack:int;
		protected var m_processOffset:int;
		protected var m_output:Boolean; //! 現在バッファ書き込み中かどうか
		protected var m_tracks:Vector.<MTrack>;
		protected var m_status:int;
		protected var m_stopTimer:Timer; //! 停止処理キック用のタイマー
		protected var m_buffTimer:Timer; //! 一時停止＆バッファリング処理キック用のタイマー
		protected var m_procTimer:Timer; //! バッファ書き込み処理キック用のタイマー
		protected var m_multiple:int;
		protected var m_startTime:Number;
		protected var m_pausedPos:Number;
		protected var m_restTimer:Timer;
		protected var m_debugDate:Date;
		protected var m_process1stTime:Boolean;

		public function MSequencer(multiple:int = 32) {
			m_multiple = multiple;
			m_output = false;
			MChannel.boot(MSequencer.BUFFER_SIZE * m_multiple);
			MOscillator.boot();
			MEnvelope.boot();
			m_tracks = new Vector.<MTrack>;
			m_buffer = new Vector.<Vector.<Number>>(2);
			m_buffer.fixed = true;
			m_buffer[0] = new Vector.<Number>(MSequencer.BUFFER_SIZE * m_multiple * 2); // * 2 stereo
			m_buffer[0].fixed = true;
			m_buffer[1] = new Vector.<Number>(MSequencer.BUFFER_SIZE * m_multiple * 2); //
			m_buffer[1].fixed = true;
			m_playSide = 1;
			m_playSize = 0;
			m_step = STEP_NONE;
			m_sound = new Sound();
			m_soundChannel = new SoundChannel();
			m_soundTransform = new SoundTransform();
			m_pausedPos = 0.0;
			setMasterVolume(100);
			stop();
			m_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			m_restTimer = null;
		}

		public function play():void {
			if (m_status != STATUS_PAUSE) {
				stop();
				m_process1stTime = true;
				for (var i:int = 0; i < m_tracks.length; i++) {
					m_tracks[i].seekTop();
				}
				m_status = STATUS_BUFFERING;
				processStart();
			}
			else {
				m_status = STATUS_PLAY;
				m_soundChannel = m_sound.play(m_pausedPos);
				m_startTime = Number(getTimer());
				var totl:Number = getTotalMSec();
				var rest:Number = (totl > m_pausedPos) ? (totl - m_pausedPos) : 0.0;
				var rpti:Boolean = MTrack.s_infiniteRepeatF;
				if (rpti == false) {
					m_restTimer = new Timer(rest, 1);
					m_restTimer.addEventListener(TimerEvent.TIMER, onStopReq);
					m_restTimer.start();
				}
			}
			//m_debugDate = new Date();
		}

		public function stop():void {
			m_stopTimer = new Timer(20.0, 1);
			m_stopTimer.addEventListener(TimerEvent.TIMER, onStopReq);
			m_buffTimer = new Timer(20.0, 1);
			m_buffTimer.addEventListener(TimerEvent.TIMER, onBufferingReq);
			m_procTimer = new Timer(20.0, 1);
			m_procTimer.addEventListener(TimerEvent.TIMER_COMPLETE, processAll);
			if (m_restTimer) m_restTimer.stop();
			if (m_soundChannel) m_soundChannel.stop();
			m_status = STATUS_STOP;
			m_pausedPos = 0.0;
		}

		public function pause():void {
			if (m_restTimer) m_restTimer.stop();
			if (m_soundChannel) m_soundChannel.stop();
			m_pausedPos = getNowMSec();
			m_status = STATUS_PAUSE;
		}

		public function setMasterVolume(vol:int):void {
			var v:Number;
			if (vol < 0) {
				v = 0.0;
			}
			else if (vol >= 100) {
				v = 1.0;
			}
			else {
				v = (Number(vol) / 100.0);
			}
			m_soundTransform.volume = v;
			SoundMixer.soundTransform = m_soundTransform;
		}

		public function isPlaying():Boolean {
			return (m_status > STATUS_BUFFERING);
		}
		public function isWorking():Boolean {
			return (m_status > STATUS_PAUSE);
		}

		public function isPaused():Boolean {
			return (m_status == STATUS_PAUSE);
		}

		public function disconnectAll():void {
			while(m_tracks.pop()) { }
			m_status = STATUS_STOP;
		}

		public function connect(track:MTrack):void {
			m_tracks.push(track);
		}

/*
		private function reqStop():void {
			m_stopTimer.start();
		}
*/
		private function onStopReq(e:Event):void {
			stop();
			dispatchEvent(new MMLEvent(MMLEvent.COMPLETE));
		}
		private function reqBuffering():void {
			//trace("reqBf");
			m_buffTimer.start();
		}
		private function onBufferingReq(e:Event):void {
			pause();
			m_status = STATUS_BUFFERING;
		}

		//! バッファ書き込みリクエスト
		private function processStart():void {
			m_step = STEP_PRE;
			m_processOffset = 0;
			m_procTimer.start();
		}
		//! 実際のバッファ書き込み
		// UIのフリーズを避けるため、数ステップに分けて処理を行う
		private function processAll(e:Event):void {
			var sLen:int = MSequencer.BUFFER_SIZE * m_multiple;
			var bLen:int = MSequencer.BUFFER_SIZE * 4;
			if (bLen > sLen) bLen = sLen;
			var nLen:int = m_tracks.length;
			var i:int;
			var buffer:Vector.<Number> = m_buffer[1 - m_playSide];
			var now:Date;
			var beginProcTime:Number;
			now = new Date();
			beginProcTime = now.getTime();
			switch(m_step) {
			case STEP_PRE:
				if (m_output) {
					//trace("pro1");
					m_procTimer.start();
					return;
				}
				for(i = sLen * 2 - 1; i >= 0; i--) {
					buffer[i] = 0.0;
				}
				m_processTrack = MTrack.FIRST_TRACK;
				m_processOffset = 0;
				m_step++;
				m_procTimer.start();
				break;
			case STEP_TRACK:
				if (m_output) {
					//trace("pro2");
					m_procTimer.start();
					return;
				}
				do {
					if (m_processTrack >= nLen) {
						//trace("m_buffer[" + (1 - m_playSide) + "] filled");
						m_step = STEP_POST;
						break;
					} else {
						m_tracks[m_processTrack].onSampleData(buffer, m_processOffset, m_processOffset + bLen);
						m_processOffset += bLen;
						if (m_processOffset >= sLen) {
							m_processTrack++;
							m_processOffset = 0;
							if (m_status == STATUS_BUFFERING) {
								dispatchEvent(new MMLEvent(MMLEvent.BUFFERING, false, false, 0, 0, (m_processTrack+1) * 100 / (nLen+1)));
							}
						}
					}
					now = new Date();
				} while( (beginProcTime + 10.0) >= now.getTime() ); // 10msくらいはキックせず連続で処理をする（5ms -> 10ms）
				m_procTimer.start();
				break;
			case STEP_POST:
				m_step = STEP_COMPLETE;
				if (m_status == STATUS_BUFFERING) {
					var date:Date = new Date();
					//trace((date.getTime() - m_debugDate.getTime()) + "msec.");
					m_status = STATUS_PLAY;
					m_playSide = 1 - m_playSide;
					m_playSize = 0;
					processStart();
					m_soundChannel = m_sound.play();
					//trace("play");
					m_startTime = Number(getTimer());
					var totl:Number = getTotalMSec();
					var rest:Number = (totl > m_pausedPos) ? (totl - m_pausedPos) : 0.0;
					var rpti:Boolean = MTrack.s_infiniteRepeatF;
					if (rpti == false) {
						m_restTimer = new Timer(rest, 1);
						m_restTimer.addEventListener(TimerEvent.TIMER, onStopReq);
						m_restTimer.start();
					}
				}
				break;
			default:
				break;
			}
		}

		//!
		private function onSampleData(e:SampleDataEvent):void {
			var latency:Number = e.position / 44.1 - m_soundChannel.position;
			//trace((e.position / 44.1) + "-" + (m_soundChannel.position) + "="+latency);
			//trace("e.pos:" + Math.round(e.position / 44.1) + "  -  c.pos:" + Math.round(m_soundChannel.position) + "  =  latency:" + Math.round(latency));
			
			m_output = true;
			if (m_playSize >= m_multiple) {
				// バッファ完成済みの場合
				if (m_step == STEP_COMPLETE) {
					m_playSide = 1 - m_playSide;
					m_playSize = 0;
					processStart();
				}
				// バッファが未完成の場合
				else {
					m_output = false;
					reqBuffering();
					return;
				}
				if (m_status == STATUS_LAST) {
					m_output = false;
					//reqStop(); stopはrestTimerに任せる
					return;
				}
				else if (m_status == STATUS_PLAY) {
					if (m_tracks[MTrack.TEMPO_TRACK].isEnd()) {
						m_status = STATUS_LAST;
					}
				}
			}
			
			//異音回避のため、再生開始直後のみ、１バッファ分だけ無音をレンダリング
			if (m_process1stTime == true) {
				for(i = 0; i < BUFFER_SIZE; i++) {
					e.data.writeFloat(0.0);
					e.data.writeFloat(0.0);
				}
				m_output = false;
				m_process1stTime = false;
				return;
			}
			
			var buffer:Vector.<Number> = m_buffer[m_playSide];
			var base:int = (BUFFER_SIZE * m_playSize) * 2;
			var i:int, len:int = BUFFER_SIZE << 1;
			
			for(i = 0; i < len; i++) {
				e.data.writeFloat(buffer[base + i]);
			}
			m_playSize++;
			//trace("e.data.writeFloat(buffer[ " + base + " ]) / m_playSize=" + m_playSize + "  m_playSide=" + m_playSide);
			
			m_output = false;
		}
		public function getSndChannelPos():Number {
			if (m_soundChannel) {
				return m_soundChannel.position;
			}
			else {
				return 0.0;
			}
		}
		public function getTotalMSec():Number {
			return m_tracks[MTrack.TEMPO_TRACK].getTotalMSec();
		}
		public function getNowMSec():Number {
			var now:Number = 0.0;
			switch (m_status) {
				case STATUS_PLAY:
				case STATUS_LAST:
				now = Number(getTimer()) - m_startTime + m_pausedPos;
				return now;			//無限リピート機能搭載により常に現在時を返す
				default:
				return m_pausedPos;	//pause時
			}
			return 0;
		}
		public function getNowTimeStr():String {
			var sec:Number = Math.ceil(getNowMSec() / 1000.0);
			if (sec >= 86400.0) return "over24h";
			var shour:String = "0" + String(int(sec / 3600.0));
			var smin:String  = "0" + String(int((sec / 60.0) % 60.0));
			var ssec:String  = "0" + String(int(sec % 60.0));
			return shour.substr(shour.length - 2, 2) + ":" + smin.substr(smin.length - 2, 2) + ":" + ssec.substr(ssec.length - 2, 2);
		}
	}
}
