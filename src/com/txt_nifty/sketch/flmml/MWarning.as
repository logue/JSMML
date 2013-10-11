package com.txt_nifty.sketch.flmml {
    public final class MWarning {
        public static const UNKNOWN_COMMAND:int      = 0;
        public static const UNCLOSED_REPEAT:int      = 1;
        public static const UNOPENED_COMMENT:int     = 2;
        public static const UNCLOSED_COMMENT:int     = 3;
        public static const RECURSIVE_MACRO:int      = 4;
        public static const UNCLOSED_ARGQUOTE:int    = 5;
		public static const UNCLOSED_GROUPNOTES:int  = 6;
		public static const UNOPENED_GROUPNOTES:int  = 7;
		public static const INVALID_MACRO_NAME:int   = 8;
        public static const s_string:Array = [
                                              "対応していないコマンド '%s' があります。",
                                              "終わりが見つからない繰り返しがあります。",
                                              "始まりが見つからないコメントがあります。",
                                              "終わりが見つからないコメントがあります。",
                                              "マクロが再帰的に呼び出されています。",
                                              "マクロ引数指定の \"\" が閉じられていません",
											  "終りが見つからない連符があります",
											  "始まりが見つからない連符があります",
											  "マクロ名に使用できない文字が含まれています。'%s'"
                                              ];
        public static function getString(warnId:int, str:String):String {
            return s_string[warnId].replace("%s", str);
        }
    }
}
