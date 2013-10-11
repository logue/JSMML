package com.txt_nifty.sketch.flmml {
    import flash.events.EventDispatcher;
    import flash.utils.*;
    
    import mx.utils.StringUtil;

    public class MML extends EventDispatcher {
        protected var m_sequencer:MSequencer;
        protected var m_tracks:Array;
        protected var m_string:String;
        protected var m_trackNo:int;
        protected var m_octave:int;
        protected var m_relativeDir:Boolean; //
        protected var m_velocity:int;        // default velocity
        protected var m_velDetail:Boolean;
        protected var m_velDir:Boolean;
        protected var m_length:int;          // default length
        protected var m_tempo:Number;
        protected var m_letter:int;
        protected var m_keyoff:int;
        protected var m_gate:int;
        protected var m_maxGate:int;
        protected var m_form:int;
        protected var m_noteShift:int;
        protected var m_warning:String;
        protected var m_maxPipe:int;
        protected var m_maxSyncSource:int;
		protected var m_beforeNote:int;
		protected var m_portamento:int;
		protected var m_usingPoly:Boolean;
		protected var m_polyVoice:int;
		protected var m_polyForce:Boolean;
		protected var m_metaTitle:String;
		protected var m_metaArtist:String;
		protected var m_metaCoding:String;
		protected var m_metaComment:String;
        protected static var MAX_PIPE:int = 3;
        protected static var MAX_SYNCSOURCE:int = 3;
		protected static var MAX_POLYVOICE:int = 64;

        public function MML() {
            m_sequencer = new MSequencer();
            var self:MML = this;
            m_sequencer.addEventListener(MMLEvent.COMPLETE, function(e:MMLEvent):void {
                    m_sequencer.stop();
                    self.dispatchEvent(new MMLEvent(MMLEvent.COMPLETE));
                });
            m_sequencer.addEventListener(MMLEvent.BUFFERING, function(e:MMLEvent):void {
                    self.dispatchEvent(new MMLEvent(MMLEvent.BUFFERING, false, false, 0, 0, e.progress));
                });
        }

        public function set onSignal(func:Function):void {
            // ex) function func(globalTick:uint, event:int):void {}
            m_sequencer.onSignal = func;
        }

        public function setSignalInterval(interval:int):void {
            m_sequencer.setSignalInterval(interval);
        }

        public function getWarnings():String {
            return m_warning;
        }

        protected function warning(warnId:int, str:String):void {
            m_warning += MWarning.getString(warnId, str) +"\n";
        }

        protected function len2tick(len:int):int {
            if (len == 0) return m_length;
            return 384/len;
        }

        protected function note(noteNo:int):void {
            //trace("note"+noteNo);
            noteNo += m_noteShift + getKeySig();
			if (getChar() == '*') {	// ポルタメント記号
				m_beforeNote = noteNo + m_octave * 12;
				m_portamento = 1;
				next();
			}
			else {
				var lenMode:int;
				var len:int;
				var tick:int = 0;
				var tickTemp:int;
				var tie:int = 0;
				var keyon:int = (m_keyoff == 0) ? 0 : 1;
				m_keyoff = 1;
				while (1) {
					if (getChar() != '%') {
						lenMode = 0;
					}
					else {
						lenMode = 1;
						next();
					}
					len = getUInt(0);
					if (tie == 1 && len == 0) {
						m_keyoff = 0;
						break;
					}
					tickTemp = (lenMode ? len : len2tick(len));
					tick += getDot(tickTemp);
					tie = 0;
					if (getChar() == '&') { // tie
						tie = 1;
						next();
					}
					else {
						break;
					}
				}
				if (m_portamento == 1) { // ポルタメントなら
					m_tracks[m_trackNo].recPortamento(m_beforeNote - (noteNo + m_octave * 12), tick);
				}
				m_tracks[m_trackNo].recNote(noteNo + m_octave * 12, tick, m_velocity, keyon, m_keyoff);
				if (m_portamento == 1) { // ポルタメントなら
					m_tracks[m_trackNo].recPortamento(0, 0);
					m_portamento = 0;
				}
			}
        }

        protected function rest():void {
            //trace("rest");
			var lenMode:int = 0;
			if (getChar() == '%') {
				lenMode = 1;
				next();
			}
            var len:int;
            len = getUInt(0);
            var tick:int = lenMode ? len : len2tick(len);
            tick = getDot(tick);
            m_tracks[m_trackNo].recRest(tick);
        }

        protected function atmark():void {
            var c:String = getChar();
            var o:int = 1, a:int = 0, d:int = 64, s:int = 32, r:int = 0, sens:int = 0, mode:int = 0;
			var w:int = 0, f:int = 0;
			var pmd:int, amd:int, pms:int, ams:int;
            switch(c) {
            case 'v': // Volume
                m_velDetail = true;
                next();
                m_velocity = getUInt(m_velocity);
                if (m_velocity > 127) m_velocity = 127;
                break;
            case 'x': // Expression
                next();
                o = getUInt(127);
                if (o > 127) o = 127;
                m_tracks[m_trackNo].recExpression(o);
                break;
            case 'e': // Envelope
            	{
            		var releasePos:int;
            		var t:Vector.<int> = new Vector.<int>(), l:Vector.<int> = new Vector.<int>();
                	next();
                	o = getUInt(o);
                	if (getChar() == ',') next();
                	a = getUInt(a);
                	releasePos = m_letter;
                	while(true){
	                	if (getChar() == ',') {
	                		next();
	                	}else{
	                		break;
	                	}
                		releasePos = m_letter - 1;
    	            	d = getUInt(d);
	                	if (getChar() == ',') {
	                		next();
	                	}else{
	                		m_letter = releasePos;
	                		break;
	                	}
            	    	s = getUInt(s);
            	    	t.push(d);
            	    	l.push(s);
            	    }
            	    if(t.length == 0){
            	    	t.push(d);
            	    	l.push(s);
            	    }
                	if (getChar() == ',') next();
                	r = getUInt(r);
                	//trace("A"+a+",D"+d+",S"+s+",R"+r);
                	m_tracks[m_trackNo].recEnvelope(o, a, t, l, r);
             	}
                break;
			case 'm':
				next();
				if (getChar() == 'h') {
					next();
					w = 0; f = 0; pmd = 0; amd = 0; pms = 0; ams = 0; s = 1;					
					do {
					w = getUInt(w);
					if (getChar() != ',') break;
					next();
					f = getUInt(f);
					if (getChar() != ',') break;
					next();
					pmd = getUInt(pmd);
					if (getChar() != ',') break;
					next();
					amd = getUInt(amd);
					if (getChar() != ',') break;
					next();
					pms = getUInt(pms);
					if (getChar() != ',') break;
					next();
					ams = getUInt(ams);
					if (getChar() != ',') break;
					next();
					s = getUInt(s);
					}
					while (false);
					m_tracks[m_trackNo].recHwLfo(w, f, pmd, amd, pms, ams, s);		
				}
				break;
            case 'n': // Noise frequency
                next();
                if (getChar() == 's') { // Note Shift (relative)
                    next();
                    m_noteShift += getSInt(0);
                }
                else {
                    o = getUInt(0);
                    if (o < 0 || o > 127) o = 0;
                    m_tracks[m_trackNo].recNoiseFreq(o);
                }
                break;
            case 'w': // pulse Width modulation
                next();
                o = getSInt(50);
				if (o < 0) {
					if (o > -1) o = -1;
					if (o < -99) o = -99;
				}
				else {
					if (o < 1) o = 1;
					if (o > 99) o = 99;
				}
                m_tracks[m_trackNo].recPWM(o);
                break;
            case 'p': // Pan
                next();
				if (getChar() == 'l') {	// poly mode
					next();
					o = getUInt(m_polyVoice);
					o = Math.max(0, Math.min(m_polyVoice, o));
					m_tracks[m_trackNo].recPoly(o);
				}
				else {
					o = getUInt(64);
					if (o < 1) o = 1;
					if (o > 127) o = 127;
					m_tracks[m_trackNo].recPan(o);
				}
                break;
            case '\'': // formant filter
                next();
                o = m_string.indexOf('\'', m_letter);
                if (o >= 0) {
                    var vstr:String = m_string.substring(m_letter, o);
                    var vowel:int = 0;
                    switch(vstr) {
                    case 'a': vowel = MFormant.VOWEL_A; break;
                    case 'e': vowel = MFormant.VOWEL_E; break;
                    case 'i': vowel = MFormant.VOWEL_I; break;
                    case 'o': vowel = MFormant.VOWEL_O; break;
                    case 'u': vowel = MFormant.VOWEL_U; break;
                    default: vowel = -1; break;
                    }
                    m_tracks[m_trackNo].recFormant(vowel);
                    m_letter = o + 1;
                }
                break;
            case 'd': // Detune
                next();
                o = getSInt(0);
                m_tracks[m_trackNo].recDetune(o);
                break;
            case 'l': // Low frequency oscillator (LFO)
                {
                    var dp:int = 0, wd:int = 0, fm:int = 1, sf:int = 0, rv:int = 1, dl:int = 0, tm:int = 0, cn:int = 0, sw:int = 0;
                    next();
                    dp = getUInt(dp);
                    if (getChar() == ',') next();
                    wd = getUInt(wd);
                    if (getChar() == ',') {
                        next();
                        if (getChar() == '-') { rv = -1; next(); }
                        fm = (getUInt(fm) + 1) * rv;
                    if (getChar() == '-') {
                        next();
                        sf = getUInt(0);
                    }
                        if (getChar() == ',') {
                            next();
                            dl = getUInt(dl);
                            if (getChar() == ',') {
                                next();
                                tm = getUInt(tm);
                                if (getChar() == ',') {
                                	next();
                                	sw = getUInt(sw);
                                }
                            }
                        }
                    }
                    //trace("DePth"+dp+",WiDth"+wd+",ForM"+fm+",DeLay"+dl+",TiMe"+tm);
                    m_tracks[m_trackNo].recLFO(dp, wd, fm, sf, dl, tm, sw);
                }
                break;
            case 'f': // Filter
                {
                    var swt:int = 0, amt:int = 0, frq:int = 0, res:int = 0;
                    next();
                    swt = getSInt(swt);
                    if (getChar() == ',') {
                        next();
                        amt = getSInt(amt);
                        if (getChar() == ',') {
                            next();
                            frq = getUInt(frq);
                            if (getChar() == ',') {
                                next();
                                res = getUInt(res);
                            }
                        }
                    }
                    m_tracks[m_trackNo].recLPF(swt, amt, frq, res);
                }
                break;
            case 'q': // gate time 2
                next();
                m_tracks[m_trackNo].recGate2(getUInt(2) * 2); // '*2' according to TSSCP
                break;
                case 'i': // Input
                {
                	sens = 0;
                    next();
                    sens = getUInt(sens);
                    if (getChar() == ',') {
                        next();
                        a = getUInt(a);
                        if (a > m_maxPipe) a = m_maxPipe;
                    }
                    m_tracks[m_trackNo].recInput(sens, a);
                }
                // @i[n],[m]   m:pipe no
                // if (n == 0) off
                // else sensitivity = n (max:8)
                break;
            case 'o': // Output
                {
                    mode = 0;
                    next();
                    mode = getUInt(mode);
                    if (getChar() == ',') {
                        next();
                        a = getUInt(a);
                        if (a > m_maxPipe) {
                            m_maxPipe = a;
                            if (m_maxPipe >= MAX_PIPE) m_maxPipe = a = MAX_PIPE;
                        }
                    }
                    m_tracks[m_trackNo].recOutput(mode, a);
                }
                // @o[n],[m]   m:pipe no
                // if (n == 0) off
                // if (n == 1) overwrite
                // if (n == 2) add
                break;
            case 'r': // Ring
                {
                	sens = 0;
                	next();
                	sens = getUInt(sens);
                	if (getChar() == ',') {
                		next();
                		a = getUInt(a);
                		if (a > m_maxPipe) a = m_maxPipe;
                	}
                	m_tracks[m_trackNo].recRing(sens, a);
                }
                break;
            case 's': // Sync
                {
                	mode = 0;
                	next();
                	mode = getUInt(mode);
                	if (getChar() == ',') {
                		next();
                		a = getUInt(a);
	                	if (mode == 1) {
            	    		// Sync out
            	    		if (a > m_maxSyncSource) {
            	    			m_maxSyncSource = a;
	            	    		if (m_maxSyncSource >= MAX_SYNCSOURCE) m_maxSyncSource = a = MAX_SYNCSOURCE;
	            	    	}
        	        	} else if (mode == 2) {
    	            		// Sync in
    	            		if (a > m_maxSyncSource) a = m_maxSyncSource;
                		}
                	}
                	m_tracks[m_trackNo].recSync(mode, a);
                }
                break;
			case 'u':	// midi風なポルタメント
				next();
				var rate:int;
				mode = getUInt(0);
				switch (mode) {
					case 0:
					case 1:
						m_tracks[m_trackNo].recMidiPort(mode);
						break;
					case 2:
						rate = 0;
						if (getChar() == ',') {
							next();
							rate = getUInt(0);
							if (rate < 0) rate = 0;
							if (rate > 127) rate = 127;
						}
						m_tracks[m_trackNo].recMidiPortRate(rate * 1);
						break;
					case 3:
						if (getChar() == ',') {
							next();
							var oct:int;
							var baseNote:int = -1;
							if (getChar() != 'o') {
								oct = m_octave;
							}
							else {
								next();
								oct = getUInt(0);
							}
							c = getChar();
							switch(c) {
								case 'c': baseNote = 0; break;
								case 'd': baseNote = 2; break;
								case 'e': baseNote = 4; break;
								case 'f': baseNote = 5; break;
								case 'g': baseNote = 7; break;
								case 'a': baseNote = 9; break;
								case 'b': baseNote = 11; break;
							}
							if (baseNote >= 0) {
								next();
								baseNote += m_noteShift + getKeySig();
								baseNote += oct * 12;
							}
							else {
								baseNote = getUInt(60);
							}
							if (baseNote < 0) baseNote = 0;
								if (baseNote > 127) baseNote = 127;
							m_tracks[m_trackNo].recPortBase(baseNote);
						}
						break;
				}
				break;
            default:
                m_form = getUInt(m_form);
                a = 0;
                if (getChar() == '-') {
                    next();
                    a = getUInt(0);
                }
                m_tracks[m_trackNo].recForm(m_form, a);
                break;
            }
        }

        protected function firstLetter():void {
            var c:String = getCharNext();
            var c0:String;
            var i:int;
            switch(c) {
            case "c": note(0);  break;
            case "d": note(2);  break;
            case "e": note(4);  break;
            case "f": note(5);  break;
            case "g": note(7);  break;
            case "a": note(9);  break;
            case "b": note(11); break;
            case "r": rest(); break;
            case "o": // Octave
                m_octave = getUInt(m_octave);
                if (m_octave < -2) m_octave = -2;
                if (m_octave >  8) m_octave =  8;
                break;
            case "v": // Volume
                m_velDetail = false;
                m_velocity = getUInt((m_velocity-7)/8) * 8 + 7;
                if (m_velocity < 0)   m_velocity = 0;
                if (m_velocity > 127) m_velocity = 127;
                break;
            case "(": // vol up/down
            case ")":
				i = getUInt(1);
                if (c == "(" && m_velDir ||
                    c == ")" && !m_velDir) { // up
                    m_velocity += (m_velDetail) ? (1 * i) : (8 * i);
                    if (m_velocity > 127) m_velocity = 127;
                }
                else { // down
                    m_velocity -= (m_velDetail) ? (1 * i) : (8 * i);
                    if (m_velocity < 0) m_velocity = 0;
                }
                break;
            case "l": // Length
                m_length = len2tick(getUInt(0));
                m_length = getDot(m_length);
                break;
            case "t": // Tempo
                m_tempo = getUNumber(m_tempo);
                if (m_tempo < 1) m_tempo = 1;
                m_tracks[MTrack.TEMPO_TRACK].recTempo(m_tracks[m_trackNo].getRecGlobalTick(), m_tempo);
                break;
            case "q": // gate time (rate)
                m_gate = getUInt(m_gate);
                m_tracks[m_trackNo].recGate(Number(m_gate) / Number(m_maxGate));
                break;
            case "<" : // octave shift
                if (m_relativeDir) m_octave++; else m_octave--;
                break;
            case ">": // octave shift
                if (m_relativeDir) m_octave--; else m_octave++;
                break;
            case ";": // end of track
                m_keyoff = 1;
                if (m_tracks[m_trackNo].getNumEvents() > 0) {
                	m_trackNo++;
                }
                m_tracks[m_trackNo] = createTrack();
                break;
            case "@":
                atmark();
                break;
            case "x":
                m_tracks[m_trackNo].recVolMode(getUInt(1));
                break;
            case "n":
                c0 = getChar();
                if (c0 == "s") { // Note Shift (absolute)
                    next();
                    m_noteShift = getSInt(m_noteShift);
                }
                else
                    warning(MWarning.UNKNOWN_COMMAND, c + c0);
                break;
			case '[':
				m_tracks[m_trackNo].recChordStart();
				break;
			case ']':
				m_tracks[m_trackNo].recChordEnd();
				break;
            default:
                {
                    var cc:int = c.charCodeAt(0);
                    if (cc < 128)
                        warning(MWarning.UNKNOWN_COMMAND, c);
                }
                break;
            }
        }

        protected function getCharNext():String {
            return (m_letter < m_string.length) ? m_string.charAt(m_letter++) : '';
        }

        protected function getChar():String {
            return (m_letter < m_string.length) ? m_string.charAt(m_letter) : '';
        }

        protected function next(i:int = 1):void {
            m_letter += 1;
        }

        protected function getKeySig():int {
            var k:int = 0;
            var f:int = 1;
            while(f) {
                var c:String = getChar();
                switch(c) {
                case "+": case "#": k++; next(); break;
                case "-":           k--; next(); break;
                default: f = 0; break;
                }
            }
            return k;
        }

        protected function getUInt(def:int):int {
            var ret:int = 0;
            var l:int = m_letter;
            var f:int = 1;
            while(f) {
                var c:String = getChar();
                switch(c) {
                case '0': ret = ret * 10 + 0; next(); break;
                case '1': ret = ret * 10 + 1; next(); break;
                case '2': ret = ret * 10 + 2; next(); break;
                case '3': ret = ret * 10 + 3; next(); break;
                case '4': ret = ret * 10 + 4; next(); break;
                case '5': ret = ret * 10 + 5; next(); break;
                case '6': ret = ret * 10 + 6; next(); break;
                case '7': ret = ret * 10 + 7; next(); break;
                case '8': ret = ret * 10 + 8; next(); break;
                case '9': ret = ret * 10 + 9; next(); break;
                default: f = 0; break;
                }
            }
            return (m_letter == l) ? def : ret;
        }

        protected function getUNumber(def:Number):Number {
            var ret:Number = getUInt(int(def));
            var l:Number = 1;
            if (getChar() == '.') {
                next();
                var f:Boolean = true;
                while(f) {
                    var c:String = getChar();
                    l *= 0.1;
                    switch(c) {
                        case '0': ret = ret + 0 * l; next(); break;
                        case '1': ret = ret + 1 * l; next(); break;
                        case '2': ret = ret + 2 * l; next(); break;
                        case '3': ret = ret + 3 * l; next(); break;
                        case '4': ret = ret + 4 * l; next(); break;
                        case '5': ret = ret + 5 * l; next(); break;
                        case '6': ret = ret + 6 * l; next(); break;
                        case '7': ret = ret + 7 * l; next(); break;
                        case '8': ret = ret + 8 * l; next(); break;
                        case '9': ret = ret + 9 * l; next(); break;
                        default: f = false; break;
                    }
                }
            }
            return ret;
        }

        protected function getSInt(def:int):int {
            var c:String = getChar();
            var s:int = 1;
            if      (c == '-') { s = -1; next(); }
            else if (c == '+') next();
            return getUInt(def) * s;
        }

        protected function getDot(tick:int):int {
            var c:String = getChar();
            var intick:int = tick;
            while(c == '.') {
                next();
                intick /= 2;
                tick += intick;
                c = getChar();
            }
            return tick;
        }

        public function createTrack():MTrack {
            m_octave = 4;
            m_velocity = 100;
            m_noteShift = 0;
            return new MTrack();
        }

        protected function begin():void {
            m_letter = 0;
        }

        protected function process():void {
            begin();
            while(m_letter < m_string.length) {
                firstLetter();
            }
        }

        protected function processRepeat():void {
            m_string = m_string.toLowerCase();
            begin();
            var repeat:Array = new Array();
            var origin:Array = new Array();
            var start:Array = new Array();
            var last:Array = new Array();
            var nest:int = -1;
            while(m_letter < m_string.length) {
                var c:String = getCharNext();
                switch(c) {
                case '/':
                    if (getChar() == ':') {
                        next();
                        origin[++nest] = m_letter - 2;
                        repeat[nest] = getUInt(2);
                        start[nest] = m_letter;
                        last[nest] = -1;
                    }
                    else if (nest >= 0) {
                        last[nest] = m_letter - 1;
                        m_string = m_string.substring(0, m_letter-1) + m_string.substring(m_letter);
                        m_letter--;
                    }
                    else {
                    }
                    break;
                case ':':
                    if (getChar() == '/' && nest >= 0) {
                        next();
                        var contents:String = m_string.substring(start[nest], m_letter - 2);
                        var newstr:String = m_string.substring(0, origin[nest]);
                        for (var i:int = 0; i < repeat[nest]; i++) {
                            if (i < repeat[nest]-1 || last[nest] < 0) newstr += contents;
                            else newstr += m_string.substring(start[nest], last[nest]);
                        }
                        var l:int = newstr.length;
                        newstr += m_string.substring(m_letter);
                        m_string = newstr;
                        m_letter = l;
                        nest--;
                    }
                    break;
                default:
                    break;
                }
            }
            if (nest >= 0) warning(MWarning.UNCLOSED_REPEAT, "");
        }

        protected function getIndex(idArr:Array, id:String):int {
            for(var i:int = 0; i < idArr.length; i++)
                if (((String)(idArr[i])) == id) return i;
            return -1;
        }

        protected function replaceMacro(macroTable:Array):Boolean {
            for each(var macro:Object in macroTable){
                if(m_string.substr(m_letter, macro.id.length) == macro.id){
                    var start:int = m_letter, last:int = m_letter + macro.id.length, code:String = macro.code;
                    m_letter += macro.id.length;
                    var c:String = getCharNext();
                    while(StringUtil.isWhitespace(c) || c == '　'){
                        c = getCharNext();
                    }
                    var args:Array = new Array();
					var q:int = 0;
					
					// 引数が0個の場合は引数処理をスキップするように変更
					if (macro.args.length > 0)
					{
						if(c == "{"){
							c = getCharNext();
							while (q == 1 || (c != "}" && c != "")) {
								if (c == '"') q = 1 - q;
								if(c == "$"){
									replaceMacro(macroTable);
								}
								c = getCharNext();
							}
							last = m_letter;
							var argstr:String = m_string.substring(start + macro.id.length + 1, last - 1);
							var curarg:String = "", quoted:Boolean = false;
							for(var pos:int = 0; pos < argstr.length; pos++){
								if(!quoted && argstr.charAt(pos) == '"'){
									quoted = true;
								}else if(quoted && (pos + 1) < argstr.length && argstr.charAt(pos) == '\\' && argstr.charAt(pos + 1) == '"'){
									curarg += '"';
									pos++;
								}else if(quoted && argstr.charAt(pos) == '"'){
									quoted = false;
								}else if(!quoted && argstr.charAt(pos) == ','){
									args.push(curarg);
									curarg = "";
								}else{
									curarg += argstr.charAt(pos);
								}
							}
							args.push(curarg);
							if(quoted){
								warning(MWarning.UNCLOSED_ARGQUOTE, "");
							}
						}
						// 引数への置換
						for(var i:int = 0; i < code.length; i++){
							for(var j:int = 0; j < args.length; j++){
								if(j >= macro.args.length){
									break;
								}
								if(code.substr(i, macro.args[j].id.length + 1) == ("%" + macro.args[j].id)){
									code = code.substring(0, i) + code.substring(i).replace("%" + macro.args[j].id, args[macro.args[j].index]);
									i += args[macro.args[j].index].length - 1;
									break;
								}
							}
						}
					}

                    m_string = m_string.substring(0, start - 1) + code + m_string.substring(last);
                    m_letter = start - 1;
                    //trace(m_string.substring(m_letter));
                    return true;
                }
            }
            return false;
        }

        protected function processMacro():void {
            var i:int;
			var matched:Array;
			// OCTAVE REVERSE
            var exp:RegExp = /^#OCTAVE\s+REVERSE\s*$/m;
            if (m_string.match(exp)) {
                m_string = m_string.replace(exp, "");
                m_relativeDir = false;
            }
            // VELOCITY REVERSE
            exp = /^#VELOCITY\s+REVERSE\s*$/m;
            if (m_string.match(exp)) {
                m_string = m_string.replace(exp, "");
                m_velDir = false;
            }
			// meta informations
			{
				m_metaTitle   = findMetaDescN("TITLE"  );	// #TITLE
				m_metaArtist  = findMetaDescN("ARTIST" );	// #ARTIST
				m_metaComment = findMetaDescN("COMMENT");	// #COMMENT
				m_metaCoding  = findMetaDescN("CODING" );	// #CODING
				findMetaDescN("PRAGMA");	// #PRAGMA
			}
			// FM Desc
			{
				exp = /^#OPM@(\d+)[ \t]*{([^}]*)}/gm;
				matched = m_string.match(exp);
				m_string = m_string.replace(exp, "");
				
				var fmm:Array;
				for (i = 0; i < matched.length; i++) {
					fmm = matched[i].match(/^#OPM@(\d+)[ \t]*{([^}]*)}/m);
					MOscOPM.setTimber(parseInt(fmm[1]), MOscOPM.TYPE_OPM, fmm[2]);
				}
				
				exp = /^#OPN@(\d+)[ \t]*{([^}]*)}/gm;
				matched = m_string.match(exp);
				m_string = m_string.replace(exp, "");
				
				var fmn:Array;
				for (i = 0; i < matched.length; i++) {
					fmn = matched[i].match(/^#OPN@(\d+)[ \t]*{([^}]*)}/m);
					MOscOPM.setTimber(parseInt(fmn[1]), MOscOPM.TYPE_OPN, fmn[2]);
				}				
				
				var fmg:Vector.<String> = findMetaDescV("FMGAIN");
				for (i = 0; i < fmg.length; i++) {
					MOscOPM.setCommonGain(20.0*parseInt(fmg[i])/127.0);
				}
			}
			// POLY MODE
			{
				var usePoly:String = findMetaDescN("USING\\s+POLY");
				usePoly = usePoly.replace("\r",  "");
				usePoly = usePoly.replace("\n", " ");
				usePoly = usePoly.toLowerCase();
				if (usePoly.length > 0) {
					var ss:Array = usePoly.split(" ");
					if (ss.length < 1) {
						m_usingPoly = false;
					}
					else {
						m_usingPoly = true;
						m_polyVoice = Math.min(Math.max(1, parseInt(ss[0])), MAX_POLYVOICE); // 1～MAX_POLYVOICE
					}
					for (i = 1; i < ss.length; i++) {
						if (ss[i] == "force") {
							m_polyForce = true;
						}
					}
					if (m_polyVoice <= 1) {
						m_usingPoly = false;
						m_polyForce = false;
					}
					// trace("using poly = " + m_usingPoly + ", max voice = " + m_polyVoice + ", force = " + m_polyForce);
				}
			}
            // GB WAVE (ex. "#WAV10 0,0123456789abcdeffedcba9876543210")
            {
                exp = /^#WAV10\s.*$/gm;
                matched = m_string.match(exp);
                if (matched) {
                    for(i = 0; i < matched.length; i++) {
                        m_string = m_string.replace(exp, "");
                        //trace(matched[i]);
                        var wav:Array = matched[i].split(" ");
                        var wavs:String = "";
                        for(var j:int = 1; j < wav.length; j++) wavs += wav[j];
                        var arg:Array = wavs.split(",");
                        var waveNo:int = parseInt(arg[0]);
                        if (waveNo < 0) waveNo = 0;
                        if (waveNo >= MOscGbWave.MAX_WAVE) waveNo = MOscGbWave.MAX_WAVE-1;
                        //trace(waveNo+":",arg[1].toLowerCase());
                        MOscGbWave.setWave(waveNo,
                                           (arg[1].toLowerCase()+"00000000000000000000000000000000").substr(0, 32));
                    }
                }
                exp = /^#WAV13\s.*$/gm;
                matched = m_string.match(exp);
                if (matched) {
                    for(i = 0; i < matched.length; i++) {
                        m_string = m_string.replace(exp, "");
                        //trace(matched[i]);
                        wav = matched[i].split(" ");
                        wavs = "";
                        for(j = 1; j < wav.length; j++) wavs += wav[j];
                        arg = wavs.split(",");
                        waveNo = parseInt(arg[0]);
                        if (waveNo < 0) waveNo = 0;
                        if (waveNo >= MOscWave.MAX_WAVE) waveNo = MOscWave.MAX_WAVE-1;
                        //trace(waveNo+":",arg[1].toLowerCase());
                        MOscWave.setWave(waveNo,arg[1].toLowerCase());
                    }
                }
			//2009.05.10 OffGao ADD START addDPCM
            // DPCM WAVE (ex. "#WAV9 0,0123456789abcdeffedcba9876543210")
                exp = /^#WAV9\s.*$/gm;
                matched = m_string.match(exp);
                if (matched) {
                    for(i = 0; i < matched.length; i++) {
                        m_string = m_string.replace(exp, "");
                        //trace(matched[i]);
                        wav = matched[i].split(" ");
                        wavs = "";
                        for(j = 1; j < wav.length; j++) wavs += wav[j];
                        arg = wavs.split(",");
                        waveNo = parseInt(arg[0]);
                        if (waveNo < 0) waveNo = 0;
                        if (waveNo >= MOscFcDpcm.MAX_WAVE) waveNo = MOscFcDpcm.MAX_WAVE-1;
                        var intVol:int = parseInt(arg[1]);
                        if (intVol < 0) intVol = 0;
                        if (intVol > 127)intVol = 127;
                        var loopFg:int = parseInt(arg[2]);
                        if (loopFg < 0) loopFg = 0;
                        if (loopFg > 1) loopFg = 1;
                        /*
                        var length:int = -1;
                        if (arg.length >= 5){
                            length = parseInt(arg[4]);
                            if (length < 1) length = 1;
                            if (length > 0xff) length = 0xff;
                        }
                        MOscFcDpcm.setWave(waveNo,intVol,loopFg,arg[3],length);
                        */
                        MOscFcDpcm.setWave(waveNo,intVol,loopFg,arg[3]);
                    }
                }
            }
			//2009.05.10 OffGao ADD END addDPCM
            // macro
            begin();
            var top:Boolean = true;
            var macroTable:Array = new Array();
			var regTrimHead:RegExp = /^\s*/m;
			var regTrimFoot:RegExp = /\s*$/m;			
            while(m_letter < m_string.length) {
                var c:String = getCharNext();
                switch(c) {
                    case '$':
                        if(top){
                            var last:int = m_string.indexOf(";", m_letter);
                            if(last > m_letter){
                                var nameEnd:int = m_string.indexOf("=", m_letter);
                                if(nameEnd > m_letter && nameEnd < last){
                                    var start:int = m_letter;
                                    var argspos:int = m_string.indexOf("{");
                                    if(argspos < 0 || argspos >= nameEnd){
                                        argspos = nameEnd;
                                    }
									var idPart:String = m_string.substring(start, argspos);
                                    var regexResult:Array = idPart.match("[a-zA-Z_][a-zA-Z_0-9#\+\(\)]*");
	                                if(regexResult != null){
	                                    var id:String = regexResult[0];
										idPart = idPart.replace(regTrimHead, '').replace(regTrimFoot, '');	// idString.Trim();								
										if (idPart != id) {
											warning(MWarning.INVALID_MACRO_NAME, idPart);
										}
	                                    if(id.length > 0){
	                                        var args:Array = new Array();
	                                        if(argspos < nameEnd){
	                                            var argstr:String = m_string.substring(argspos + 1, m_string.indexOf("}", argspos));
	                                            args = argstr.split(",");
	                                            for(i = 0; i < args.length; i++){
	                                                var argid:Array = args[i].match("[a-zA-Z_][a-zA-Z_0-9#\+\(\)]*");
	                                                args[i] = { id: (argid != null ? argid[0] : ""), index: i };
	                                            }
	                                            args.sort(function (a:Object, b:Object):int {
	                                                if(a.id.length > b.id.length)  return -1;
	                                                if(a.id.length == b.id.length) return  0;
	                                                return 1;
	                                            });
	                                        }
	                                        m_letter = nameEnd + 1;
	                                        c = getCharNext();
	                                        while(m_letter < last){
	                                            if(c == "$"){
 	                                                if(!replaceMacro(macroTable)){
                                                        if(m_string.substr(m_letter, id.length) == id){
                                                            m_letter--;
                                                            m_string = remove(m_string, m_letter, m_letter + id.length);
                                                            warning(MWarning.RECURSIVE_MACRO, id);
                                                        }
                                                    }
	                                                last = m_string.indexOf(";", m_letter);
	                                            }
	                                            c = getCharNext();
	                                        }
	                                        var pos:int = 0;
	                                        for(; pos < macroTable.length; pos++){
                                                 if(macroTable[pos].id == id){
                                                     macroTable.splice(pos, 1);
                                                     pos--;
                                                     continue;
                                                 }
	                                        	if(macroTable[pos].id.length < id.length){
	                                        		break;
	                                        	}
	                                        }
	                                        macroTable.splice(pos, 0, { id: id, code: m_string.substring(nameEnd + 1, last), args: args });
	                                        m_string = remove(m_string, start - 1, last);
	                                        m_letter = start - 1;
	                                    }
                                    }
                                }else{
                                    // macro use
                                    replaceMacro(macroTable);
                                    top = false;
                                 }
                            }else{
                                // macro use
                                replaceMacro(macroTable);
                                top = false;
                            }
                        }else{
                            // macro use
                            replaceMacro(macroTable);
                            top = false;
                        }
                        break;
                    case ';':
                        top = true;
                        break;
                    default:
                        if(!StringUtil.isWhitespace(c) && c != '　'){
                            top = false;
                        }
                        break;
                }
            }
        }
		
		// 指定されたメタ記述を引き抜いてくる
		protected function findMetaDescV(sectionName:String):Vector.<String> {
            var i:int;
			var matched:Array;
			var mm:Array;
			var e1:RegExp;
			var e2:RegExp;
			var tt:Vector.<String> = new Vector.<String>();
			
			e1 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$", "gm"); // global multi-line
			e2 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$",  "m"); //        multi-line
			
			matched = m_string.match(e1);
			if (matched) {
				m_string = m_string.replace(e1, "");
				for(i = 0; i < matched.length; i++) {
					mm = matched[i].match(e2);
					if (mm.length >= 3) { 
						tt.push(mm[2]);
					}
				}
				// trace(sectionName + " = " + tt);
			}			
			return tt;
		}			
		
		// 指定されたメタ記述を引き抜いてくる
		protected function findMetaDescN(sectionName:String):String {
            var i:int;
			var matched:Array;
			var mm:Array;
			var e1:RegExp;
			var e2:RegExp;
			var tt:String = "";
			
			e1 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$", "gm"); // global multi-line
			e2 = new RegExp("^#" + sectionName + "(\\s*|\\s+(.*))$",  "m"); //        multi-line
			
			matched = m_string.match(e1);
			if (matched) {
				m_string = m_string.replace(e1, "");
				for(i = 0; i < matched.length; i++) {
					mm = matched[i].match(e2);
					if (mm.length >= 3) { 
						tt += mm[2];
						if (i + 1 < matched.length) {
							tt += "\r\n";
						}
					}
				}
				// trace(sectionName + " = " + tt);
			}			
			return tt;
		}	
		
        protected function processComment(str:String):void {
            m_string = str;
            begin();
            var commentStart:int = -1;
            while(m_letter < m_string.length) {
                var c:String = getCharNext();
                switch(c) {
                case '/':
                    if (getChar() == '*') {
                        if (commentStart < 0) commentStart = m_letter - 1;
                        next();
                    }
                    break;
                case '*':
                    if (getChar() == '/') {
                        if (commentStart >= 0) {
                            m_string = remove(m_string, commentStart, m_letter);
                            m_letter = commentStart;
                            commentStart = -1;
                        }
                        else {
                            warning(MWarning.UNOPENED_COMMENT, "");
                        }
                    }
                    break;
                default:
                    break;
                }
            }
            if (commentStart >= 0) warning(MWarning.UNCLOSED_COMMENT, "");

            // 外部プログラム用のクォーテーション
            begin();
            commentStart = -1;
            while(m_letter < m_string.length) {
                if (getCharNext() == '`') {
                    if (commentStart < 0) {
                        commentStart = m_letter - 1;
                    }
                    else {
                        m_string = remove(m_string, commentStart, m_letter-1);
                        m_letter = commentStart;
                        commentStart = -1;
                    }
                }
            }
            // trace(m_string);
        }

		protected function processGroupNotes():void {
			var GroupNotesStart:int = -1;
			var GroupNotesEnd:int;
			var noteCount:int = 0;
			var repend:int, len:int, tick:int, tick2:int, tickdiv:Number, noteTick:int, noteOn:int;
			var lenMode:int;
			var defLen:int = 96;
			var newstr:String;
			begin();
			while (m_letter < m_string.length) {
				var c:String = getCharNext();
				switch(c) {
					case 'l':
						defLen = len2tick(getUInt(0));
						defLen = getDot(defLen);
						break;
					case '{':
						GroupNotesStart = m_letter - 1;
						noteCount = 0;
						break;
					case '}':
						repend = m_letter;
						if (GroupNotesStart < 0) {
							warning(MWarning.UNOPENED_GROUPNOTES, "");
						}
						tick = 0;
						while (1) {
							if (getChar() != '%') {
								lenMode = 0;
							}
							else {
								lenMode = 1;
								next();
							}
							len = getUInt(0);
							if (len == 0) {
								if (tick == 0) tick = defLen;
								break;
							}
							tick2 = (lenMode ? len : len2tick(len));
							tick2 = getDot(tick2);
							tick += tick2;
							if (getChar() != '&') {
								break;
							}
							next();
						}
						GroupNotesEnd = m_letter;
						m_letter = GroupNotesStart + 1;
						newstr = m_string.substring(0, GroupNotesStart);
						tick2 = 0;
						tickdiv = Number(tick) / Number(noteCount);
						noteCount = 1;
						noteOn = 0;
						while (m_letter < repend) {
							c = getCharNext();
							switch (c) {
								case '+':
								case '#':
								case '-':
									break;

								default:
									if ((c >= 'a' && c <= 'g') || c == 'r') {
										if (noteOn == 0) {
											noteOn = 1;
											break;
										}
									}
									if (noteOn == 1) {
										noteTick = Math.round(Number(noteCount) * tickdiv - Number(tick2));
										noteCount++;
										tick2 += noteTick;
										if (tick2 > tick) {
											noteTick -= (tick2 - tick);
											tick2 = tick;
										}
										newstr += "%";
										newstr += String(noteTick);
									}
									noteOn = 0;
									if ((c >= 'a' && c <= 'g') || c == 'r') {
										noteOn = 1;
									}
									break;
							}
							if (c != '}') {
								newstr += c;
							}
						}
						m_letter = newstr.length;
						newstr += m_string.substring(GroupNotesEnd);
						m_string = newstr;
						GroupNotesStart = -1;
						break;
					default:
						if ((c >= 'a' && c <= 'g') || c == 'r') {
							noteCount++;
						}
						break;
				}
			}
			if (GroupNotesStart >= 0) warning(MWarning.UNCLOSED_GROUPNOTES, "");
		}

        static public function removeWhitespace(str:String):String {
            return str.replace(new RegExp("[ 　\n\r\t\f]+","g"),"");
        }

        static public function remove(str:String, start:int, end:int):String {
            return str.substring(0, start) + str.substring(end+1);
        }

        public function play(str:String):void {
            if (m_sequencer.isPaused()) {
                m_sequencer.play();
                return;
            }
            m_sequencer.disconnectAll();
            m_tracks = new Array();
            m_tracks[0] = createTrack();
            m_tracks[1] = createTrack();
            m_warning = new String();

            m_trackNo = MTrack.FIRST_TRACK;
            m_octave = 4;
            m_relativeDir = true;
            m_velocity = 100;
            m_velDetail = true;
            m_velDir = true;
            m_length = len2tick(4);
            m_tempo  = 120;
            m_keyoff = 1;
            m_gate = 15;
            m_maxGate = 16;
            m_form = MOscillator.PULSE;
            m_noteShift = 0;
            m_maxPipe = 0;
            m_maxSyncSource = 0;
			m_beforeNote = 0;
			m_portamento = 0;
			m_usingPoly = false;
			m_polyVoice = 1;
			m_polyForce = false;
			
			m_metaTitle   = "";
			m_metaArtist  = "";
			m_metaCoding  = "";
            m_metaComment = "";
			
            processComment(str);
            //trace(m_string+"\n\n");
            processMacro();
            //trace(m_string);
            m_string = removeWhitespace(m_string);
            processRepeat();
            //trace(m_string);
			processGroupNotes();
			// trace(m_string);
            process();

            // omit
            if (m_tracks[m_tracks.length-1].getNumEvents() == 0) m_tracks.pop();

            // conduct
            m_tracks[MTrack.TEMPO_TRACK].conduct(m_tracks);

            // post process
            for(var i:int = MTrack.TEMPO_TRACK; i < m_tracks.length; i++) {
                if (i > MTrack.TEMPO_TRACK) {
					if (m_usingPoly && (m_polyForce || m_tracks[i].findPoly())) {
						m_tracks[i].usingPoly(m_polyVoice);
					}
                    m_tracks[i].recRestMSec(2000);
                    m_tracks[i].recClose();
                }
                m_sequencer.connect(m_tracks[i]);
            }

            // initialize modules
            m_sequencer.createPipes(m_maxPipe+1);
            m_sequencer.createSyncSources(m_maxSyncSource + 1);

            // dispatch event
            dispatchEvent(new MMLEvent(MMLEvent.COMPILE_COMPLETE, false, false, 0, 0));

            // play start
            m_sequencer.play();
        }

        public function stop():void {
            m_sequencer.stop();
        }

        public function pause():void {
            m_sequencer.pause();
        }

        public function resume():void {
            m_sequencer.play();
        }

        public function setMasterVolume(vol:int):void {
            m_sequencer.setMasterVolume(vol);
        }

        public function getGlobalTick():uint {
            return m_sequencer.getGlobalTick();
        }

        public function isPlaying():Boolean {
            return m_sequencer.isPlaying();
        }

        public function isPaused():Boolean {
            return m_sequencer.isPaused();
        }

        public function getTotalMSec():uint {
            return m_tracks[MTrack.TEMPO_TRACK].getTotalMSec();
        }
        public function getTotalTimeStr():String {
            return m_tracks[MTrack.TEMPO_TRACK].getTotalTimeStr();
        }
        public function getNowMSec():uint {
            return m_sequencer.getNowMSec();
        }
        public function getNowTimeStr():String {
            return m_sequencer.getNowTimeStr();
        }
        public function getVoiceCount():int {
			var i:int;
			var c:int = 0;
            for (i = 0; i < m_tracks.length; i++) {
				c += m_tracks[i].getVoiceCount();
			}
            return c;
        }		
        public function getMetaTitle():String {
            return m_metaTitle;
        }
        public function getMetaComment():String {
            return m_metaComment;
        }
        public function getMetaArtist():String {
            return m_metaArtist;
        }
        public function getMetaCoding():String {
            return m_metaCoding;
        }
    }
}
