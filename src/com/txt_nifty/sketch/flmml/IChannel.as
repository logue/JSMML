package com.txt_nifty.sketch.flmml {
    import __AS3__.vec.Vector;

    /*
     * チャンネルボイス・インターフェース
     */
    public interface IChannel {
        function setExpression(ex:int):void;
        function setVelocity(velocity:int):void;
        function setNoteNo(noteNo:int, tie:Boolean = true):void;
        function setDetune(detune:int):void;
        function noteOn(noteNo:int, velocity:int):void;
        function noteOff(noteNo:int):void;
        function close():void;
        function setNoiseFreq(frequency:Number):void;
        function setForm(form:int, subform:int):void;
        function setEnvelope1Atk(attack:int):void;
        function setEnvelope1Point(time:int, level:int):void;
        function setEnvelope1Rel(release:int):void;
        function setEnvelope2Atk(attack:int):void;
        function setEnvelope2Point(time:int, level:int):void;
        function setEnvelope2Rel(release:int):void;
        function setPWM(pwm:int):void;
        function setPan(pan:int):void;
        function setFormant(vowel:int):void;
        function setLFOFMSF(form:int, subform:int):void;
        function setLFODPWD(depth:int, freq:Number):void;
        function setLFODLTM(delay:int, time:int):void;
        function setLFOTarget(target:int):void;
        function setLpfSwtAmt(swt:int, amt:int):void;
        function setLpfFrqRes(frq:int, res:int):void;
        function setVolMode(m:int):void;
        function setInput(i:int, p:int):void;
        function setOutput(o:int, p:int):void;
        function setRing(s:int, p:int):void;
        function setSync(m:int, p:int):void;
        function setPortamento(depth:int, len:Number):void;
        function setMidiPort(mode:int):void;
        function setMidiPortRate(rate:Number):void;
        function setPortBase(base:int):void;
        function setSoundOff():void;
        function getVoiceCount():int;
		function setVoiceLimit(voiceLimit:int):void;
		function setHwLfo(data:int):void;
        function reset():void;
        function getSamples(samples:Vector.<Number>, max:int, start:int, delta:int):void;

        /*
         * End Interface Definition
         */
    }
}
