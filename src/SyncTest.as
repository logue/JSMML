package {
	import flash.display.*;
	import flash.text.*;
	import com.txt_nifty.sketch.flmml.*;

	public class SyncTest extends Sprite {
		private var m_mml:MML;
		private var m_cnt:int;
		private var m_label:TextField;

		public function SyncTest() {
			m_mml = new MML();
			m_mml.onSignal = onSignal;
			m_mml.setSignalInterval(48); // quater note: 96ticks
			play("t150v12o4l8@4@e1,0,6,0,0 /:8 @n50v12c @n v11c @e1,0,15,0,0@n32v13c @e1,0,6,0,0@n v11c :/");
			m_label = new TextField();
			m_label.text = "";
			addChild(m_label);
		}

		public function play(mml:String):void {
			m_mml.play(mml);
		}

		public function onSignal(tick:uint, event:int):void {
			m_label.text = tick.toString();
			var x:int = Math.random() * 400 + 60;
			var y:int = Math.random() * 200 + 60;
			var w:int = Math.random() * (10) + 6;
			var h:int = Math.random() * (10) + 6;
			if (tick < 96*2*8) {
				if ((tick / 96) % 2 == 1) {
					w += 30;
					h += 30;
				}
				graphics.beginFill(Math.random()*0xffffff);
				graphics.lineStyle(0, 0x000000);
				graphics.drawRect(x-w, y-h, w*2, h*2);
				graphics.endFill();
			}
		}
	}
}
