/**!
 * JSMML
 * Copyright (c) 2007      Yuichi Tateno <http://rails2u.com/>,
 *               2008-2013 Logue <http://logue.be/>
 *
 * This software is released under the MIT License.
 * http://opensource.org/licenses/mit-license.php
 */

(function(document, window){
	JSMML = (function() {
		return function(swfurl) {
			this.mmlPlayer = document.getElementById(JSMML.mmlID);
			this.initialize.call(this);
		}
	})();
	JSMML.VESION = '1.2.6';
	JSMML.setSWFVersion = function(v) { this.SWF_VERSION = v };
	JSMML.SWF_VERSION = 'JSMML is not loaded, yet.';
	JSMML.toString = function() {
		return 'JSMML VERSION: ' + this.VESION + ', SWF_VERSION: ' + this.SWF_VERSION;
	};

	JSMML.swfurl = 'JSMML.swf';
	JSMML.mmlID = 'jsmml';
	JSMML.onLoad = function() {};
	JSMML.loaded = false;
	JSMML.instances = {};

	JSMML.init = function(swfurl) {
		if (! document.getElementById(this.mmlDivID)) {
			// init
			var swfname = (swfurl ? swfurl : this.swfurl) + '?' + (new Date()).getTime();
			var div = document.createElement('div');
			div.id = this.mmlDivID;
			div.style.display = 'inline';
			div.width = 1;
			div.height = 1;
			document.body.appendChild(div);

			if (navigator.plugins && navigator.mimeTypes && navigator.mimeTypes.length) {
				var o = document.createElement('object');
				o.id = this.mmlID;
				o.width = 1;
				o.height = 1;
				o.setAttribute('data', swfname);
				o.setAttribute('type', 'application/x-shockwave-flash');
				var p = document.createElement('param');
				p.setAttribute('name', 'allowScriptAccess');
				p.setAttribute('value', 'always');
				o.appendChild(p);
				div.appendChild(o);
			} else {
				// IE
				div.innerHTML =
					'<object id="' + this.mmlID + '" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="1" height="1">'+
					'<param name="movie" value="' + swfname + '" />'+
					'<param name="bgcolor" value="#FFFFFF" />'+
					'<param name="quality" value="high" />'+
					'<param name="allowScriptAccess" value="always" />'+
					'</object>'
				;
			}
		}
	}

	// call from swf
	JSMML.initASFinish = function() {
		this.loaded = true;
		this.onLoad();
	}

	JSMML.prototype = {
		/**
		 * 初期化イベント
		 */
		initialize: function() {
			// MMLの再生が終了した
			this.onFinish = function() {};
			// MMLのコンパイルが終了した
			this.onCompiled = function() {};
			// バッファリング中
			this.onBuffering = function() {};
			// 一時停止中
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
		 * @param number volume ボリューム（0~127）
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
		 * MMLのコメントを取得
		 * @return string
		 */
		getMetaComment: function(){
			return this.mmlPlayer._getMetaComment(this.uNum());
		},
		/**
		 * MMLのコーダー名を取得
		 * @return string
		 */
		getMetaCoding: function(){
			return this.mmlPlayer._getMetaCoding(this.uNum());
		},
		/**
		 * getVoiceCount
		 * @return number
		 */
		getVoiceCount: function(){
			return this.mmlPlayer._getVoiceCount(this.uNum());
		}
	};

	window.addEventListener('DOMContentLoaded', function() {
		JSMML.init();
	});
})(document, window);