package com.txt_nifty.sketch.fmgenAs 
{
    import __AS3__.vec.Vector;
	/**
	 * JaggArrayじゃなくてJaggVectorじゃねーかって突っ込みはナシで。
	 * @author ALOE
	 */
	internal final class JaggArray
	{
		public static function I2(s1:int, s2:int):Vector.<Vector.<int>> {
			var a:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(s1);
			for (var i:int = 0; i < s1; i++) {
				a[i] = new Vector.<int>(s2);
			}
			return a;
		}
		
		public static function I3(s1:int, s2:int, s3:int):Vector.<Vector.<Vector.<int>>> {
			var a:Vector.<Vector.<Vector.<int>>> = new Vector.<Vector.<Vector.<int>>>(s1);
			for (var i:int = 0; i < s1; i++) {
				a[i] = new Vector.<Vector.<int>>(s2);
				for (var j:int = 0; j < s2; j++) {
					a[i][j] = new Vector.<int>(s3);
				}
			}
			return a;
		}
	}

}