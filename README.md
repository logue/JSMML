JSMML customized
============

JSMML customizedは、おー氏のFLMMLのLinearDrive氏による派生版であるFLMML CustomizedをJavaScriptから叩けるようにしたMMLシーケンサ＋アナログシンセサイザです。

## 使い方
```js
<script type="text/javascript" src="JSMML.js"></script>
<script type="text/javascript">
JSMML.swfurl = 'JSMML_customized.swf';
// onLoad に関数を入れておくと、SWF のロード完了時に呼ばれる。
// SWF が未ロード時に new JSMML() するとエラーる 
JSMML.onLoad = function() {
	var mml = new JSMML();
	mml.onFinish = function() { alert('finish!') };
	mml.play('t60l16 o5r cdefedc8 efgagfe8 c4 c4 c4 c4 ccddeeffe8d8c4');
}
</script>
```
関連情報
--------
[FLMML customized] : http://flmmlcustomized.codeplex.com/

## ライセンス
Licensed under the MIT License.