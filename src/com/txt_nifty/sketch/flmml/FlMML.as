package com.txt_nifty.sketch.flmml {
    import mx.core.UIComponent;

    public class FlMML extends UIComponent {
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

        public function play(mml:String):void {
            m_mml.play(mml);
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

        public function isPaused():Boolean {
            return m_mml.isPaused();
        }

        public function setMasterVolume(vol:int):void {
            m_mml.setMasterVolume(vol);
        }

        public function getWarnings():String {
            return m_mml.getWarnings();
        }

        public function getTotalMSec():uint {
            return m_mml.getTotalMSec();
        }
        public function getTotalTimeStr():String {
            return m_mml.getTotalTimeStr();
        }
        public function getNowMSec():uint {
            return m_mml.getNowMSec();
        }
        public function getNowTimeStr():String {
            return m_mml.getNowTimeStr();
        }
		public function getVoiceCount():int {
			return m_mml.getVoiceCount();
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
