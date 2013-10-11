package com.txt_nifty.sketch.flmml {
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
        public var onSignal:Function = null;
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
        protected var m_trackArr:Array;
        protected var m_signalArr:Array;
        protected var m_signalPtr:int;
        protected var m_globalTick:uint;
        protected var m_status:int;
        protected var m_signalInterval:int;
        protected var m_stopTimer:Timer; //! 停止処理キック用のタイマー
        protected var m_buffTimer:Timer; //! 一時停止＆バッファリング処理キック用のタイマー
        protected var m_procTimer:Timer; //! バッファ書き込み処理キック用のタイマー
        protected var m_multiple:int;
        protected var m_startTime:uint;
        protected var m_pausedPos:Number;
        protected var m_restTimer:Timer;
        protected var m_debugDate:Date;

        public function MSequencer(multiple:int = 32) {
            m_multiple = multiple;
            m_output = false;
            MChannel.boot(MSequencer.BUFFER_SIZE * m_multiple);
            MOscillator.boot();
            MEnvelope.boot();
            m_trackArr = new Array();
            m_signalArr = new Array(3);
            for(var i:int = 0; i < m_signalArr.length; i++) {
                m_signalArr[i] = new MSignal(i);
                m_signalArr[i].setFunction(onSignalHandler);
            }
            m_signalPtr = 0;
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
            m_pausedPos = 0;
            setMasterVolume(100);
            m_signalInterval = 96;
            stop();
            m_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
            m_restTimer = null;
        }

        public function play():void {
            if (m_status != STATUS_PAUSE) {
                stop();
                m_globalTick = 0;
                for (var i:int = 0; i < m_trackArr.length; i++) {
                    m_trackArr[i].seekTop();
                }
                m_status = STATUS_BUFFERING;
                processStart();
            }
            else {
                m_status = STATUS_PLAY;
                m_soundChannel = m_sound.play(m_pausedPos);
                m_startTime = getTimer();
                var totl:uint = getTotalMSec();
                var rest:uint = (totl > m_pausedPos) ? (totl - m_pausedPos) : 0;
                m_restTimer = new Timer(rest, 1);
                m_restTimer.addEventListener(TimerEvent.TIMER, onStopReq);
                m_restTimer.start();
            }
            m_debugDate = new Date();
        }

        public function stop():void {
            m_stopTimer = new Timer(0, 1);
            m_stopTimer.addEventListener(TimerEvent.TIMER, onStopReq);
            m_buffTimer = new Timer(0, 1);
            m_buffTimer.addEventListener(TimerEvent.TIMER, onBufferingReq);
            m_procTimer = new Timer(2, 1);
            m_procTimer.addEventListener(TimerEvent.TIMER_COMPLETE, processAll);
            if (m_restTimer) m_restTimer.stop();
            if (m_soundChannel) m_soundChannel.stop();
            m_status = STATUS_STOP;
            m_pausedPos = 0;
        }

        public function pause():void {
            if (m_restTimer) m_restTimer.stop();
            if (m_soundChannel) m_soundChannel.stop();
            m_pausedPos = getNowMSec();
            m_status = STATUS_PAUSE;
        }

        public function setMasterVolume(vol:int):void {
            m_soundTransform.volume = vol * (1.0 / 127.0);
            SoundMixer.soundTransform = m_soundTransform;
        }

        public function isPlaying():Boolean {
            return (m_status > STATUS_PAUSE);
        }

        public function isPaused():Boolean {
            return (m_status == STATUS_PAUSE);
        }

        public function disconnectAll():void {
            while(m_trackArr.pop()) { }
            m_status = STATUS_STOP;
        }

        public function connect(track:MTrack):void {
            track.m_signalInterval = m_signalInterval;
            m_trackArr.push(track);
        }

        public function getGlobalTick():uint {
            return m_globalTick;
        }

        public function setSignalInterval(interval:int):void {
            m_signalInterval = interval;
        }

        protected function onSignalHandler(globalTick:uint, event:int):void {
            m_globalTick = globalTick;
            if (onSignal != null) onSignal(globalTick, event);
        }

        private function reqStop():void {
            m_stopTimer.start();
        }
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
            var nLen:int = m_trackArr.length;
            var i:int;
            var buffer:Vector.<Number> = m_buffer[1 - m_playSide];
            var beginProcTime:Number = (new Date()).getTime();
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
                if (nLen > 0) {
                    var track:MTrack = m_trackArr[MTrack.TEMPO_TRACK];
                    track.onSampleData(buffer, 0, sLen, m_signalArr[m_signalPtr]);
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
                        m_step++;
                        break;
                    } else {
                        m_trackArr[m_processTrack].onSampleData(buffer, m_processOffset, m_processOffset + bLen);
                        m_processOffset += bLen;
                        if (m_processOffset >= sLen) {
                            m_processTrack++;
                            m_processOffset = 0;
                            if (m_status == STATUS_BUFFERING) {
                                dispatchEvent(new MMLEvent(MMLEvent.BUFFERING, false, false, 0, 0, (m_processTrack+1) * 100 / (nLen+1)));
                            }
                        }
                    }
                } while(beginProcTime + 5 >= (new Date()).getTime()); // 5msくらいはキックせず連続で処理をする
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
                    m_startTime = getTimer();
                    var totl:uint = getTotalMSec();
                    var rest:uint = (totl > m_pausedPos) ? (totl - m_pausedPos) : 0;
                    m_restTimer = new Timer(rest, 1);
                    m_restTimer.addEventListener(TimerEvent.TIMER, onStopReq);
                    m_restTimer.start();
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
                    if (m_trackArr[MTrack.TEMPO_TRACK].isEnd()) {
                        m_status = STATUS_LAST;
                    }
                }
            }
            var buffer:Vector.<Number> = m_buffer[m_playSide];
            var base:int = (BUFFER_SIZE * m_playSize) * 2;
            var i:int, len:int = BUFFER_SIZE << 1;
            for(i = 0; i < len; i++) {
                e.data.writeFloat(buffer[base + i]);
            }
            m_playSize++;
            //m_signalArr[(m_signalPtr + m_signalArr.length-1) % m_signalArr.length].start();
            m_signalPtr = (++m_signalPtr) % m_signalArr.length;
            m_output = false;
        }
        public function createPipes(num:int):void {
            MChannel.createPipes(num);
        }
        public function createSyncSources(num:int):void {
        	MChannel.createSyncSources(num);
        }
        public function getTotalMSec():uint {
            return m_trackArr[MTrack.TEMPO_TRACK].getTotalMSec();
        }
        public function getNowMSec():uint {
            var now:uint = 0;
            var tot:uint = getTotalMSec();
            switch (m_status) {
                case STATUS_PLAY:
                case STATUS_LAST:
                now = getTimer() - m_startTime + m_pausedPos;
                return (now < tot) ? now : tot;
                default:
                return m_pausedPos;
            }
            return 0;
        }
        public function getNowTimeStr():String {
            var sec:int = Math.ceil(Number(getNowMSec()) / 1000);
            var smin:String = "0" + int(sec / 60);
            var ssec:String = "0" + (sec % 60);
            return smin.substr(smin.length-2, 2) + ":" + ssec.substr(ssec.length-2, 2);
        }
    }
}
