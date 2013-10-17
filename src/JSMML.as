/**
 * JSMML
 * Copyright (c) 2007      Yuichi Tateno <http://rails2u.com/>,
 *               2008      inudaisho <http://inudaisho.sakura.ne.jp/>
 *               2009-2013 Logue <http://logue.be/>
 *
 * This software is released under the MIT License.
 * http://opensource.org/licenses/mit-license.php
 */
package {
	import flash.display.Sprite;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.events.Event;
	
	import com.flmml.MMLEvent;

	[SWF(frameRate="30")]
	public class JSMML extends Sprite {
		public static const VERSION:String = '1.2.6#19253';

//		private var debug:Boolean = false;

		public var mmlPlayers:Object = {};
		
		protected var m_timer:Timer;

		public function JSMML() {
			Security.allowDomain('*');
			initJS();
		}

		public const CALLBACKS:Array = [
			'create', 'play', 'stop' ,'pause', 'destroy',
			// Add
			'isPlaying', 'isPaused', 'setMasterVolume', 'getWarnings',
			'getTotalMSec','getTotalTimeStr','getNowMSec','getNowTimeStr',
			'getMetaTitle','getMetaComment','getMetaArtist', 'getMetaCoding',
			'getVoiceCount'
		];

		public function initJS():void {
			ExternalInterface.call('JSMML.setSWFVersion', JSMML.VERSION);
			for each(var cName:String in CALLBACKS) {
				ExternalInterface.addCallback('_' + cName, this[cName]);
			}
			ExternalInterface.call('JSMML.initASFinish()');
		}

		public function create():Number {
			var uNum:Number = getUNum();
			mmlPlayers[uNum] = new MMLPlayer();
			player(uNum).addEventListener(Event.COMPLETE,				onComplete(uNum));
			// Add
			player(uNum).addEventListener(MMLEvent.COMPILE_COMPLETE,	onCompileComplete(uNum));
			player(uNum).addEventListener(MMLEvent.BUFFERING,			onBuffering(uNum));	// TODO
			
//			m_timer[uNum] = new Timer(250*4, 0);
//			m_timer[uNum].addEventListener(TimerEvent.TIMER, onSecond);

//			if (debug) ExternalInterface.call('console.info("JSMML.swf : Create Player : ' + uNum + '")');
			return uNum;
		}

		public function getUNum(uNum:Number = NaN):Number {
			if (isNaN(uNum)) {
				uNum = (new Date).getTime();
			} else {
				uNum++;
			}

			if (mmlPlayers[uNum]) {
				return getUNum(uNum);
			} else {
				return uNum;
			}
		}

		public function onComplete(uNum:Number):Function {
			return function(e:*):void {
				ExternalInterface.call('JSMML.instances["' + uNum + '"].onFinish()');
//				if (debug) ExternalInterface.call('console.info("JSMML.swf : MML is finished: ' + uNum + '")');
			};
		}

		public function onCompileComplete(uNum:Number):Function {
			return function(e:*):void {
				ExternalInterface.call('JSMML.instances["' + uNum + '"].onCompiled()');
//				if (debug) ExternalInterface.call('console.info("JSMML.swf : Compile Complete.: ' + uNum + '")');
			};
		}

		public function onBuffering(uNum:Number):Function {
			return function(e:*):void {
				ExternalInterface.call('JSMML.instances["' + uNum + '"].onBuffering()');
//				if (debug) ExternalInterface.call('console.info("JSMML.swf : Buffering...: ' + uNum + '")');
			};
		}

		public function removeFinishCallback(uNum:Number, func:Function):void {
			player(uNum).removeEventListener(Event.COMPLETE, func);
		}

		public function play(uNum:Number, mml:String = undefined):void {
			player(uNum).play(mml);
//			if (debug) ExternalInterface.call('console.log("JSMML.swf : Play: ' + uNum + '")');
		}
/*
		public function setMML(uNum:Number, mml:String):void {
			player(uNum).setMML(mml);
		}
*/

		public function stop(uNum:Number):void {
			player(uNum).stop();
//			if (debug) ExternalInterface.call('console.log("JSMML.swf : Stop: ' + uNum + '")');
		}

		public function pause(uNum:Number):void {
			player(uNum).pause();
//			if (debug) ExternalInterface.call('console.log("JSMML.swf : Pause: ' + uNum + '")');
		}

		public function destroy(uNum:Number):void {
			stop(uNum);
//			if (debug) ExternalInterface.call('console.log("JSMML.swf : Destory: ' + uNum + '")');
			delete mmlPlayers[uNum];
		}

		public function player(uNum:Number):MMLPlayer {
			if (!mmlPlayers[uNum]){
				new Error("Player is not found: " + uNum);
//				if (debug) ExternalInterface.call('console.error("JSMML.swf : Player is not found: ' + uNum + '")');
			}
			return mmlPlayers[uNum];
		}

/* Add */
		public function isPlaying(uNum:Number):Boolean {
			return player(uNum).isPlaying();
//			if (debug)  ExternalInterface.call('console.info("JSMML.swf : Player is Playing: ' + uNum + '")');
		}

		public function isPaused(uNum:Number):Boolean {
			return player(uNum).isPaused();
//			if (debug) ExternalInterface.call('console.info("JSMML.swf : Player is Pasueing: ' + uNum + '")');
		}

		public function setMasterVolume(uNum:Number,vol:int):void {
			player(uNum).setMasterVolume(vol);
		}

		public function getWarnings(uNum:Number):String {
			return player(uNum).getWarnings();
//			if (debug) ExternalInterface.call('console.info("JSMML.swf :' + player(uNum).getWarnings() + '")');
		}

		public function getTotalMSec(uNum:Number):uint {
			return player(uNum).getTotalMSec();
		}
		public function getTotalTimeStr(uNum:Number):String {
			return player(uNum).getTotalTimeStr();
		}
		public function getNowMSec(uNum:Number):uint {
			return player(uNum).getNowMSec();
		}
		public function getNowTimeStr(uNum:Number):String {
			return player(uNum).getNowTimeStr();
		}
/* r38797 */
		public function getMetaTitle(uNum:Number):String {
			return player(uNum).getMetaTitle();
		}
		public function getMetaComment(uNum:Number):String {
			return player(uNum).getMetaComment();
		}
		public function getMetaArtist(uNum:Number):String {
			return player(uNum).getMetaArtist();
		}
		public function getMetaCoding(uNum:Number):String {
			return player(uNum).getMetaCoding();
		}
/* r11884 */
		public function getVoiceCount(uNum:Number):int {
			return player(uNum).getVoiceCount();
		}
	}
}

import com.flmml.MML;
import com.flmml.MOscillator;
import flash.events.Event;

internal class MMLPlayer extends MML {
	public function MMLPlayer(mml:String = undefined) {
		super();
		var self:MMLPlayer = this;
		m_sequencer.addEventListener(Event.COMPLETE, function(e:Event):void {
			self.dispatchEvent(new Event(Event.COMPLETE));
		});
		/*if (mml) setMML(mml);*/
	}

	/*
	public function get time():Number {
		return m_sequencer.now;
	}
	*/

	// MML#proxy don't override because the method call on arg.
	public function _play():void {
		// play start
		m_sequencer.play();
	}

	public override function stop():void {
		super.stop();
		m_sequencer.disconnectAll();
	}
/*
	public function pause():void {
		m_sequencer.stop();
	}
*/

}

