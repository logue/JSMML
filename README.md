JSMML
============

JSMMLは、おー氏のFLMMLをJavaScriptから叩けるようにしたMMLシーケンサ＋アナログシンセサイザです。

## 使い方
```js
<script type="text/javascript" src="JSMML.js"></script>
<script type="text/javascript">
JSMML.swfurl = 'JSMML.swf'; // default
// onLoad に関数を入れておくと、SWF のロード完了時に呼ばれる。
// SWF が未ロード時に new JSMML() するとエラーる 
JSMML.onLoad = function() {
	var mml = new JSMML();
	mml.onFinish = function() { alert('finish!') };
	mml.play('t60l16 o5r cdefedc8 efgagfe8 c4 c4 c4 c4 ccddeeffe8d8c4');
}
</script>
```

## ライセンス
Licensed under the MIT License.