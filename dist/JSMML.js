/*
 * JSMML
 * Author: Yuichi Tateno
 * http://rails2u.com/
 *
 * Modified by Logue
 * http://logue.be/
 *
 * The MIT Licence.
 */

JSMML = (function() {
	return function(swfurl) {
		this.mmlPlayer = document.getElementById(JSMML.mmlID);
		this.initialize.call(this);
	}
})();

JSMML.VESION = '1.2.5';
JSMML.setSWFVersion = function(v) { JSMML.SWF_VERSION = v };
JSMML.SWF_VERSION = 'JSMML is not loaded, yet.';
JSMML.toString = function() {
	return 'JSMML VERSION: ' + JSMML.VESION + ', SWF_VERSION: ' + JSMML.SWF_VERSION;
};

JSMML.swfurl = 'JSMML.swf';
JSMML.mmlID = 'jsmml';
JSMML.onLoad = function() {};
JSMML.loaded = false;
JSMML.instances = {};

JSMML.init = function(swfurl) {
	if (! document.getElementById(JSMML.mmlDivID)) {
		var div = document.createElement('div');
		div.id = JSMML.mmlID;
		try{
			document.body.appendChild(div);
		}catch(e){}	// エラー消し
		if (!document.location.protocol.match(/http/i)){
			document.getElementById(JSMML.mmlID).innerHTML = "JSMML is not running! Please execute this in HTTP protocol.";
		}else{
			// init

			if (!swfobject) {
				var js = document.createElement('script');
				js.type = 'text/javascript';
				js.async = true;
				js.src = url;
				var s = document.getElementsByTagName('script')[0];
				s.parentNode.insertBefore('http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js', s);
			}
			var swfname = (swfurl ? swfurl : JSMML.swfurl) + '?' + (new Date()).getTime();
			swfobject.embedSWF(swfname, JSMML.mmlID, "1", "1", "10.0.0","expressInstall.swf", '', 
				{'bgcolor':'#FFFFFF','quality':'high','allowScriptAccess':'always', 'style':'display:inline;'},
				{id:JSMML.mmlID}
			);
		}
	}
}

// call from swf
JSMML.initASFinish = function() {
	JSMML.loaded = true;
	JSMML.onLoad();
}

JSMML.eventInit = function() {
	JSMML.init();
}

JSMML.prototype = {
	/**
	 * 初期化イベント
	 */
	initialize: function() {
		this.onFinish = function() {};
		this.pauseNow = false;
	},
	/**
	 * MMLプレイヤーの番号
	 * @return number
	 */
	uNum: function() {
		if (!this._uNum) {
			this._uNum = this.mmlPlayer._create();
			JSMML.instances[this._uNum] = this;
		}
		return this._uNum;
	},
	/**
	 * 再生
	 * @param string _mml MMLデーター
	 * @return void
	 */
	play: function(_mml) {
		if (!_mml && this.pauseNow) {
			this.mmlPlayer._play(this.uNum());
		} else {
			if (_mml) this.score = _mml;
			this.mmlPlayer._play(this.uNum(), this.score);
		}
		this.pauseNow = false;
	},
	/**
	 * 停止
	 * @return void
	 */
	stop: function() {
		this.mmlPlayer._stop(this.uNum());
	},
	/**
	 * 一時停止
	 * @return void
	 */
	pause: function() {
		this.pauseNow = true;
		this.mmlPlayer._pause(this.uNum());
	},
	/**
	 * 削除（メモリ解放）
	 * @return void
	 */
	destroy: function() {
		this.mmlPlayer._destroy(this.uNum());
		delete JSMML.instances[this.uNum()];
	},
	// Add
	/**
	 * 再生中か？
	 * @retun boolean
	 */
	isPlaying: function(){
		return this.mmlPlayer._isPlaying(this.uNum());
	},
	/**
	 * 一時停止中か？
	 * @return boolean
	 */
	isPaused: function(){
		return this.mmlPlayer._isPaused(this.uNum());
	},
	/**
	 * マスターボリューム
	 * @param number volume ボリューム
	 * @return void
	 */
	setMasterVolume: function(volume){
		return this.mmlPlayer._setMasterVolume(this.uNum(), volume);
	},
	/**
	 * 構文エラーを取得
	 * @return string
	 */
	getWarnings: function(){
		return this.mmlPlayer._getWarnings(this.uNum());
	},
	/**
	 * MMLの全マイクロ秒を取得
	 * @return number
	 */
	getTotalMSec: function(){
		return this.mmlPlayer._getTotalMSec(this.uNum());
	},
	/**
	 * MMLの全演奏時間を取得
	 * @return string
	 */
	getTotalTimeStr: function(){
		return this.mmlPlayer._getTotalTimeStr(this.uNum());
	},
	/**
	 * MMLの現在のマイクロ秒を取得
	 * @return number
	 */
	getNowMSec: function(){
		return this.mmlPlayer._getNowMSec(this.uNum());
	},
	/**
	 * MMLの現在の時間を取得
	 * @return string
	 */
	getNowTimeStr: function(){
		return this.mmlPlayer._getNowTimeStr(this.uNum());
	},
	/**
	 * MMLのタイトルを取得
	 * @return string
	 */
	getMetaTitle: function(){
		return this.mmlPlayer._getMetaTitle(this.uNum());
	},
	/**
	 * MMLのアーティスト名を取得
	 * @return string
	 */
	getMetaArtist: function(){
		return this.mmlPlayer._getMetaArtist(this.uNum());
	},
	/**
	 * MMLのコーダー名を取得
	 * @return string
	 */
	getMetaCoding: function(){
		return this.mmlPlayer._getMetaCoding(this.uNum());
	},
	
	getVoiceCount: function(){
		return this.mmlPlayer._getVoiceCount(this.uNum());
	}
};

FastInit.addOnLoad(JSMML.eventInit);