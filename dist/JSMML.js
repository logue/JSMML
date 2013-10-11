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
		}catch(e){}	// �G���[����
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
	 * �������C�x���g
	 */
	initialize: function() {
		this.onFinish = function() {};
		this.pauseNow = false;
	},
	/**
	 * MML�v���C���[�̔ԍ�
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
	 * �Đ�
	 * @param string _mml MML�f�[�^�[
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
	 * ��~
	 * @return void
	 */
	stop: function() {
		this.mmlPlayer._stop(this.uNum());
	},
	/**
	 * �ꎞ��~
	 * @return void
	 */
	pause: function() {
		this.pauseNow = true;
		this.mmlPlayer._pause(this.uNum());
	},
	/**
	 * �폜�i����������j
	 * @return void
	 */
	destroy: function() {
		this.mmlPlayer._destroy(this.uNum());
		delete JSMML.instances[this.uNum()];
	},
	// Add
	/**
	 * �Đ������H
	 * @retun boolean
	 */
	isPlaying: function(){
		return this.mmlPlayer._isPlaying(this.uNum());
	},
	/**
	 * �ꎞ��~�����H
	 * @return boolean
	 */
	isPaused: function(){
		return this.mmlPlayer._isPaused(this.uNum());
	},
	/**
	 * �}�X�^�[�{�����[��
	 * @param number volume �{�����[��
	 * @return void
	 */
	setMasterVolume: function(volume){
		return this.mmlPlayer._setMasterVolume(this.uNum(), volume);
	},
	/**
	 * �\���G���[���擾
	 * @return string
	 */
	getWarnings: function(){
		return this.mmlPlayer._getWarnings(this.uNum());
	},
	/**
	 * MML�̑S�}�C�N���b���擾
	 * @return number
	 */
	getTotalMSec: function(){
		return this.mmlPlayer._getTotalMSec(this.uNum());
	},
	/**
	 * MML�̑S���t���Ԃ��擾
	 * @return string
	 */
	getTotalTimeStr: function(){
		return this.mmlPlayer._getTotalTimeStr(this.uNum());
	},
	/**
	 * MML�̌��݂̃}�C�N���b���擾
	 * @return number
	 */
	getNowMSec: function(){
		return this.mmlPlayer._getNowMSec(this.uNum());
	},
	/**
	 * MML�̌��݂̎��Ԃ��擾
	 * @return string
	 */
	getNowTimeStr: function(){
		return this.mmlPlayer._getNowTimeStr(this.uNum());
	},
	/**
	 * MML�̃^�C�g�����擾
	 * @return string
	 */
	getMetaTitle: function(){
		return this.mmlPlayer._getMetaTitle(this.uNum());
	},
	/**
	 * MML�̃A�[�e�B�X�g�����擾
	 * @return string
	 */
	getMetaArtist: function(){
		return this.mmlPlayer._getMetaArtist(this.uNum());
	},
	/**
	 * MML�̃R�[�_�[�����擾
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