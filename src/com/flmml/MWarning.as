package com.flmml {
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
		public static const ERR_LFOTABLE:int         = 9;
		public static const ERR_QUANTIZE:int         = 10;
		public static const ERR_PWM:int              = 11;
		public static const ERR_ENVELOPE:int         = 12;
		public static const ERR_LFO:int              = 13;
		public static const ERR_Y_CMD:int            = 14;
		public static const ERR_EFF_DELAY:int        = 15;
		public static const ERR_IREPEAT_TIMES:int    = 16;
		public static const s_string:Array = [
											  "対応していないコマンド '%s' があります。",
											  "終わりが見つからない繰り返しがあります。",
											  "始まりが見つからないコメントがあります。",
											  "終わりが見つからないコメントがあります。",
											  "マクロが再帰的に呼び出されています。",
											  "マクロ引数指定の \"\" が閉じられていません",
											  "終りが見つからない連符があります",
											  "始まりが見つからない連符があります",
											  "マクロ名に使用できない文字が含まれています。'%s'",
											  "#LFOTABLEの定義に失敗しました。'%s'",
											  "qの指定が規定外なので無視します。'%s'",
											  "@wの指定が規定外なので無視します。'%s'",
											  "エンベロープの指定に失敗しました。'%s'",
											  "ＬＦＯの指定に失敗しました。'%s'",
											  "Yコマンドの指定に失敗しました。",
											  "ディレイの遅延時間(4〜88200)またはレベル(-0.2〜-96)が規定外のため無視します。'%s'",
											  "無限リピートエントリは、トラック内で１回以下の指定が可能です。２回目以降は無視します。"
											  ];
		public static function getString(warnId:int, str:String):String {
			return s_string[warnId].replace("%s", str);
		}
	}
}
