package com.txt_nifty.sketch.flmml 
{
    import __AS3__.vec.Vector;
    import com.txt_nifty.sketch.fmgenAs.*;
    
    /**
     * FM音源ドライバ MOscOPM for AS3
     * @author ALOE
     */
    public class MOscOPM extends MOscMod
    {
        // 音色メモリ数
        public static const MAX_WAVE:int     = 128;
        // 動作周波数 (Hz)
        public static const OPM_CLOCK:int    = 3580000; // 4000000;
        // 3.58MHz(基本)：動作周波数比 (cent)
        public static const OPM_RATIO:Number = 0; //-192.048495012562; // 1200.0*Math.Log(3580000.0/OPM_CLOCK)/Math.Log(2.0); 
        // パラメータ長
        public static const TIMB_SZ_M:int    = 55;	// #OPM
        public static const TIMB_SZ_N:int    = 51;	// #OPN
        // パラメータタイプ
        public static const TYPE_OPM:int     = 0;
        public static const TYPE_OPN:int     = 1;
        
        private var m_fm:OPM = new OPM();
        private var m_oneSample:Vector.<Number> = new Vector.<Number>(1,true);
        private var m_opMask:int;
        private var m_velocity:int = 127;
        private var m_al:int = 0;
        private var m_tl:Vector.<int> = new Vector.<int>(4,true);
        
        private static var s_init:int = 0;
        private static var s_table:Vector.<Vector.<int>>;
        private static var s_comGain:Number = 14.25;
        
        // YM2151 アプリケーションマニュアル Fig.2.4より
        private static var kctable:Vector.<int> = Vector.<int>([
          // C   C#  D   D#  E   F   F#  G   G#  A   A#  B  
            0xE,0x0,0x1,0x2,0x4,0x5,0x6,0x8,0x9,0xA,0xC,0xD, // 3.58MHz         
        ]);
        
        // スロットのアドレス
        private static var slottable:Vector.<int> = Vector.<int>([
           0, 2, 1, 3 
        ]);
        
        // キャリアとなるOP
        private static var carrierop:Vector.<int> = Vector.<int>([
        //   c2   m2   c1   m1
            0x40,                // AL 0
            0x40,                // AL 1
            0x40,                // AL 2
            0x40,                // AL 3
            0x40     |0x10,      // AL 4
            0x40|0x20|0x10,      // AL 5
            0x40|0x20|0x10,      // AL 6
            0x40|0x20|0x10|0x08, // AL 7
        ]);     

        private static var defTimbre:Vector.<int> = Vector.<int>([
        /*  AL FB */
            4, 5,
        /*  AR DR SR RR SL TL KS ML D1 D2 AM　*/
            31, 5, 0, 0, 0,23, 1, 1, 3, 0, 0, 
            20,10, 3, 7, 8, 0, 1, 1, 3, 0, 0, 
            31, 3, 0, 0, 0,25, 1, 1, 7, 0, 0, 
            31,12, 3, 7,10, 2, 1, 1, 7, 0, 0, 
        //  OM,
            15,
        //  WF LFRQ PMD AMD
             0,  0,  0,  0, 
        //  PMS AMS
             0,  0,
        //  NE NFRQ
             0,  0,     
        ]);

        private static var zeroTimbre:Vector.<int> = Vector.<int>([
        /*  AL FB */
             0, 0,
        /*  AR DR SR RR SL TL KS ML D1 D2 AM　*/
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        //  OM,
            15,
        //  WF LFRQ PMD AMD
             0,  0,  0,  0, 
        //  PMS AMS
             0,  0,
        //  NE NFRQ
             0,  0,     
        ]);
        
        public function MOscOPM() { 
            super();
            boot();
            m_fm.Init(OPM_CLOCK, MSequencer.RATE44100);
            m_fm.Reset();
            m_fm.SetVolume(s_comGain);
            setOpMask(15);
            setWaveNo(0);           
        }
        
        public static function boot():void {
            if (s_init != 0) return;
			s_table = new Vector.<Vector.<int>>(MAX_WAVE);
			s_table[0] = defTimbre;
			FM.MakeLFOTable();
			s_init = 1;         
        }
        
		public static function clearTimber():void {
			for (var i:int = 0; i < s_table.length; i++) {
				if (i == 0) s_table[i] = defTimbre;
				else 		s_table[i] = null;
			}
		}
		
		// AS版のみ
        private static function trim(str:String):String {
            var regexHead:RegExp = /^[,]*/m;
            var regexFoot:RegExp = /[,]*$/m;
            return str.replace(regexHead, '').replace(regexFoot, '');
        }       
        
        public static function setTimber(no:int, type:int, s:String):void {
            if (no < 0 || MAX_WAVE <= no) return;
            
            s = s.replace(/[,;\s\t\r\n]+/gm, ",");
            s = trim(s);
            var a:Array = s.split(",");
            var b:Vector.<int> = new Vector.<int>(TIMB_SZ_M);
            
            // パラメータの数の正当性をチェック
            switch (type) {
            case TYPE_OPM: if (a.length < 2+11*4) return; // 足りない
                break;
            case TYPE_OPN: if (a.length < 2+10*4) return; // 足りない
                break;
            default: return; // んなものねぇよ
            }           
            
            var i:int, j:int, l:int;

            switch (type) {
            case TYPE_OPM:
				l = Math.min(TIMB_SZ_M, a.length);
                for (i=0;i<l;i++) {
                    b[i] = parseInt(a[i]);
                }
                for (;i<TIMB_SZ_M;i++) {
                    b[i] = zeroTimbre[i];
                }
                break;

            case TYPE_OPN:
                // AL FB
                for (i=0,j=0;i<2;i++,j++) {
                    b[i] = parseInt(a[j]);
                }
                // AR DR SR RR SL TL KS ML DT AM 4セット
                for (;i<46;i++) {
                    if ((i-2)%11==9) b[i] = 0; // DT2
                    else             b[i] = parseInt(a[j++]);
                }
				l = Math.min(TIMB_SZ_N, a.length);
				for (;j<l;i++,j++) {
					b[i] = parseInt(a[j]);
				}				
                for (;i<TIMB_SZ_M;i++) {
                    b[i] = zeroTimbre[i];
                }
                break;
            }           
        
            // 格納
            s_table[no] = b;            
        }
        
        protected function loadTimbre(p:Vector.<int>):void {
            SetFBAL(p[1],p[0]);
            
            var i:int, s:int;
            for (i = 2, s = 0; s < 4; s++, i+=11) {
                SetDT1ML(slottable[s], p[i+8], p[i+7]);
                m_tl[s] = p[i+5];
                SetTL   (slottable[s], p[i+5]);
                SetKSAR (slottable[s], p[i+6], p[i+0]);
                SetDRAMS(slottable[s], p[i+1], p[i+10]);
                SetDT2SR(slottable[s], p[i+9], p[i+2]);
                SetSLRR (slottable[s], p[i+4], p[i+3]);
            }

            setVelocity(m_velocity);
            setOpMask(p[i+0]);
            setWF    (p[i+1]);
            setLFRQ  (p[i+2]);
            setPMD   (p[i+3]);
            setAMD   (p[i+4]);
            setPMSAMS(p[i+5],p[i+6]);
            setNENFRQ(p[i+7],p[i+8]);
        }
        
        public static function setCommonGain(gain:Number):void {
            s_comGain = gain;
        }
        
        // レジスタ操作系 (非公開)
        private function SetFBAL(fb:int, al:int):void {
            var pan:int = 3;
            m_al = al&7;
            m_fm.SetReg(0x20,((pan&3)<<6)|((fb&7)<<3)|(al&7));
        }
        private function SetDT1ML(slot:int, DT1:int, MUL:int):void {
            m_fm.SetReg((2<<5)|((slot&3)<<3), ((DT1&7)<<4)|(MUL&15));
        }
        private function SetTL(slot:int, TL:int):void {
            if (TL <   0) TL =   0;
            if (TL > 127) TL = 127;         
            m_fm.SetReg((3<<5)|((slot&3)<<3), TL&0x7F);
        }
        private function SetKSAR(slot:int, KS:int, AR:int):void {
            m_fm.SetReg((4<<5)|((slot&3)<<3), ((KS &3)<<6)|(AR&0x1f));
        }
        private function SetDRAMS(slot:int, DR:int, AMS:int):void {
            m_fm.SetReg((5<<5)|((slot&3)<<3), ((AMS&1)<<7)|(DR&0x1f));
        }
        private function SetDT2SR(slot:int, DT2:int, SR:int):void {
            m_fm.SetReg((6<<5)|((slot&3)<<3), ((DT2&3)<<6)|(SR&0x1f));
        }
        private function SetSLRR(slot:int, SL:int, RR:int):void {
            m_fm.SetReg((7<<5)|((slot&3)<<3), ((SL&15)<<4)|(RR&0x0f));
        }

        // レジスタ操作系 (公開)
        public function setPMSAMS(PMS:int, AMS:int):void {
            m_fm.SetReg(0x38,((PMS&7)<<4)|((AMS&3)));
        }
        public function setPMD(PMD:int):void {
            m_fm.SetReg(0x19, 0x80|(PMD&0x7f));
        }
        public function setAMD(AMD:int):void {
            m_fm.SetReg(0x19, 0x00|(AMD&0x7f));
        }
        public function setNENFRQ(NE:int, NFQR:int):void {
            m_fm.SetReg(0x0f, ((NE&1)<<7)|(NFQR&0x1F));
        }
        public function setLFRQ(f:int):void {
            m_fm.SetReg(0x18, f&0xff);
        }
        public function setWF(wf:int):void {
            m_fm.SetReg(0x1b, wf&3);
        }
        public function noteOn():void {
            m_fm.SetReg(0x01, 0x02); // LFOリセット
            m_fm.SetReg(0x01, 0x00);
            m_fm.SetReg(0x08, m_opMask<<3);
        }
        public function noteOff():void {
            m_fm.SetReg(0x08, 0x00);
        }       
        
		// 音色選択
        public override function setWaveNo(waveNo:int):void {
            if (waveNo >= MAX_WAVE) waveNo = MAX_WAVE-1;
            if (s_table[waveNo] == null) waveNo = 0;
            m_fm.SetVolume(s_comGain); // コモンゲイン適用
            loadTimbre(s_table[waveNo]);
        }

		// ノートオン
        public override function setNoteNo(noteNo:int):void {
            noteOn();
        }

		// オペレータマスク
        public function setOpMask(mask:int):void {
            m_opMask = mask & 0xF;
        }
        
		// 0～127のベロシティを設定 (キャリアのトータルレベルが操作される)
        public function setVelocity(vel:int):void {
            m_velocity = vel;
            if ((carrierop[m_al]&0x08) != 0) SetTL(slottable[0], m_tl[0]+(127-m_velocity)); else SetTL(slottable[0], m_tl[0]); 
            if ((carrierop[m_al]&0x10) != 0) SetTL(slottable[1], m_tl[1]+(127-m_velocity)); else SetTL(slottable[1], m_tl[1]); 
            if ((carrierop[m_al]&0x20) != 0) SetTL(slottable[2], m_tl[2]+(127-m_velocity)); else SetTL(slottable[2], m_tl[2]); 
            if ((carrierop[m_al]&0x40) != 0) SetTL(slottable[3], m_tl[3]+(127-m_velocity)); else SetTL(slottable[3], m_tl[3]); 
        }       

        // 0～1.0のエクスプレッションを設定
        public function setExpression(ex:Number):void {
            m_fm.SetExpression(ex);
        }       
        
        public override function setFrequency(frequency:Number):void {
            if (m_frequency == frequency) {
                return;
            }
            super.setFrequency(frequency);

            // 指示周波数からMIDIノート番号(≠FlMMLノート番号)を逆算する（まったくもって無駄・・）
            var n:int = (int)(1200.0*Math.log(frequency/440.0)*Math.LOG2E+5700.0+OPM_RATIO+0.5);
            var note:int = n / 100;
            var cent:int = n % 100;

            // key flaction
            var kf:int = (int)(64.0*cent/100.0+0.5);
            // key code
            //           ------ octave ------   -------- note ---------
            var kc:int = (((note-1)/12) << 4) | kctable[(note+1200)%12];

            m_fm.SetReg(0x30, kf << 2);
            m_fm.SetReg(0x28, kc);
        }

        public override function getNextSample():Number {
            m_fm.Mix(m_oneSample, 0, 1);
            return m_oneSample[0];
        }

        public override function getNextSampleOfs(ofs:int):Number {
            m_fm.Mix(m_oneSample, 0, 1);
            return m_oneSample[0];
        }

        public override function getSamples(samples:Vector.<Number>, start:int, end:int):void {
            m_fm.Mix(samples, start, end - start);            
        }

        public function IsPlaying():Boolean {
            return m_fm.IsOn(0);
        }   
        
        /*
         * End Class Definition
         */     
    }
}