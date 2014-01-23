package com.flmml {
	import __AS3__.vec.Vector;

	/*
	 * チャンネルボイス・インターフェース
	 */
	public interface IChannel {
		function noteOn(noteNo:int,pdif:uint):void;
		function noteOff(noteNo:int):void;
		function setNoteNo(noteNo:int, tie:Boolean = true):void;
		function setDetune(detune:int, rate:int):void;
		function setEnvTimeUnit(spt:Number):void;
		function setLfoResolution(spt:Number):void;
		function setMixingVolume(m_vol:Number):void;
		function setVolMode(max:int, rate:Number, mode:int):void;
		function setVolume(vol:Number):void;
		function setPan(pan:Number):void;
		function setPanLegacy(lgPan:int):void;
		function setForm(form:int, sub:int):void;
		function setSubForm(subform:int):void;
		function setPhaseRMode(mode:int, phase:Number):void;
		function setEnvelope(dest:int, lvRd_mode:int, atk_mode:Boolean, initlevel:Number, evPoints:Array):void;
		function setLFO(target:int, paramA:Array, spt:Number):void;
		function setLFOrestart(target:int):void;
		function setLPF(swt:int, paramA:Array):void;
		function setFormant(vowel:int):void;
		function setPWM(pwm:Number, mode:int):void;
		function setOPMHwLfo(data:int):void;
		function setYControl(m:int, f:int, n:Number):void;
		function setPortamento(depth:int, len:Number):void;
		function setMidiPort(mode:int):void;
		function setMidiPortRate(rate:Number):void;
		function setPortBase(base:int):void;
		function getVoiceCount():int;
		function setVoiceLimit(voiceLimit:int):void;
		function setFade(time:Number, range:Number, mode:int):void;
		function allocDelayBuffer(reqbuf:int):void;
		function setDelay(cnt:int, lv:Number):void;
		function close():void;
		function setSoundOff():void;
		function reset():void;
		function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void;

		/*
		 * End Interface Definition
		 */
	}
}
