import flash.desktop.NativeApplication;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.NativeMenu;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.utils.Timer;

import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.events.FileEvent;
import mx.events.FlexEvent;

import spark.events.TextOperationEvent;

import actionscript.GifLoader;
import actionscript.Preferences;
import actionscript.Utilities;

import flashx.textLayout.operations.CopyOperation;
import flashx.textLayout.operations.FlowOperation;


[Bindable] private var copyright:String = "© axaio software gmbh 2015";

public var prefs_:Preferences = null;
public var fontFamilyCourier_:String = "Courier";

//private var listPositions:Array = null;
private var full_len:Number = 0;
private var short_len:Number = 0;
private var text_len:int = 0;
private var isFullDisplay:Boolean = false;
private var curDirectory:String = "";
private var lastSelectedPath:String = "";
private var isControlKey_:Boolean = false;
private var isAltKey_:Boolean = false;
private var imageViewWidth:int = 0;
private var imageViewHeight:int = 0;
private var textViewWidth:int = 0;
private var textViewHeight:int = 0;
private var textBinViewWidth:int = 0;
private var textBinViewHeight:int = 0;
private var newPosition_:int = -1;
private var newSelectedEntry_:String = "";
private var sound_:Sound = null;
private var channel_:SoundChannel = null;
private var playPosition_:int = 0;
private var peakValue_:int = 0;
private var wavePosition_:uint = 0;
private var waveLength_:int = -1; // the wave portion that is playing
private var enterFrameCount_:uint = 0; // for diagosis
private var alreadyPlayed_:uint = 0;   // position before the current data in ms
//private var isWaveRefDataLoaded_:Boolean = false;
private var numSamplesLoaded_:uint = 0;
private var isWaveFormatAiff_:Boolean = false;

private var player_:Video = null;
private var stream_:NetStream = null;

private var copySourceFs_:File = null;
private var copyDestFs_:File = null;
private var infoFileSize_:Number = 0;
private var infoFileCount_:int = 0;
private var infoDirCount_:int = 0;

private var thumbwindow_:ThumbnailView = null;
private var textWindow_:TextEditView = null;
private var gifloader_:GifLoader = null;

private var filesToCopy_:Array = null;
private var filesToMove_:Array = null;
private var askForMoveDialog_:Boolean = false;
private var fileToCopyMove_:Object = null; // kSource, kDestination
private var lastTargetFolder_:String = "";

//=======================================================

private function OnAppComplete():void
{
	//var plistTimer:Timer = new Timer(3000, 1);
	//plistTimer.addEventListener("timer", PrintJobListHandler);
	//plistTimer.start();
	//fs_importFiles.extensions = new Array("printjob","autojob");
	
	img.visible = false;
	img270.visible = false;
	txt.visible = false;
	
	Utilities.WriteDebugLogMessage("========================");
	Utilities.WriteDebugLogMessage("Initializing application");
	Utilities.WriteDebugLogMessage("========================");
	
	prefs_ = new Preferences();
	var w:int = prefs_.getWidth();
	var h:int = prefs_.getHeight();
	var x:int = prefs_.getXPos();
	var y:int = prefs_.getYPos();
	if (w > 0 && h > 0 && x != -1 && y != -1) {
		this.width = w;
		this.height = h;
		this.nativeWindow.x = x;
		this.nativeWindow.y = y;
	}
	var img_w:int = prefs_.getImageWidth();
	var img_h:int = prefs_.getImageHeight();
	var txt_w:int = prefs_.getTextWidth();
	var txt_h:int = prefs_.getTextHeight();
	var txtbin_w:int = prefs_.getTextBinWidth();
	var txtbin_h:int = prefs_.getTextBinHeight();
	if (img_w > 0 && img_h > 0) {
		imageViewWidth = img_w;
		imageViewHeight = img_h;
	}
	if (txt_w > 0 && txt_h > 0) {
		textViewWidth = txt_w;
		textViewHeight = txt_h;
	}
	if (txtbin_w > 0 && txtbin_h > 0) {
		textBinViewWidth = txtbin_w;
		textBinViewHeight = txtbin_h;
	}
	fs_importFiles.allowMultipleSelection = true;
	fs_importFiles.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnAppKeyDown);
	this.addEventListener (KeyboardEvent.KEY_UP, OnAppKeyUp);
	//txt.addEventListener (ScrollEvent.SCROLL, OnTextScrolling);
	//txt_nb.addEventListener (ScrollEvent.SCROLL, OnTextNBScrolling);
	//var r:Rectangle = txt.scrollRect;
	
	var defaultPath:String = fs_importFiles.directory.nativePath;
	if (defaultPath.substr(1, 2) == ":\\") {
		fontFamilyCourier_ = "Courier New";
	}
	txt.setStyle("fontFamily", fontFamilyCourier_);
	txt_nb.setStyle("fontFamily", fontFamilyCourier_);
	
	var dir:String = prefs_.getInitPath();
	Utilities.WriteDebugLogMessage("Restoring path at open:");
	Utilities.WriteDebugLogMessage(dir);
	if (dir.length > 0) {
		var dirFs:File = new File (dir);
		if (!dirFs.exists) {
			dirFs = File.desktopDirectory;
		}
		fs_importFiles.directory = dirFs;
	}

	fs_importFiles.selectedIndex = 0;
	fs_importFiles.setFocus();
	//tx_Busy.setStyle("fontSize", "14");
	
	if (NativeApplication.supportsMenu) {
		for (var ix:int = NativeApplication.nativeApplication.menu.numItems; ix > 1; ix--) {
			NativeApplication.nativeApplication.menu.removeItemAt(ix - 1);
		}
	}
	var tm:Timer = new Timer(50, 1);
	tm.addEventListener(TimerEvent.TIMER, OnAfterStartupTimer);
	tm.start();
}


private function OnAfterStartupTimer (event:TimerEvent):void
{
	OnFileChoose();
}


protected function OnApplicationClosing(event:Event):void
{
	if (prefs_ != null) {
		prefs_.setImageDimension (imageViewWidth, imageViewHeight);
		prefs_.setTextDimension (textViewWidth, textViewHeight);
		prefs_.setTextBinDimension (textBinViewWidth, textBinViewHeight);
		Utilities.WriteDebugLogMessage("Setting current path at close:");
		Utilities.WriteDebugLogMessage(fs_importFiles.directory.nativePath);
		prefs_.setInitPath (fs_importFiles.directory.nativePath);
		prefs_.save (this.nativeWindow.x, this.nativeWindow.y, this.width, this.height);
	}
}


//=======================================================

private function OnChooseConvertToAscii():void
{
	var isStr:Boolean = ch_CString.selected;
	var isBr:Boolean = ch_LineBreaks.selected;
	var isSpace:Boolean = ch_Spaces.selected;
	var path:String = fs_importFiles.selectedPath;

	var file:File = new File( path);
	if( file.isDirectory) {
		return;
	}
	var curext:String = "";
	if (file.extension != null) {
		curext = file.extension;
	}
	if (curext == "binhex") {
		Utilities.ConvertFromAscii (path);
	}
	else {
		Utilities.ConvertToAscii (isStr, isBr, isSpace, path);
	}
	fs_importFiles.refresh();
}

private function OnFileChoose():void
{
	full_len = 0;
	text_len = 0;
	tx_InfoMake.text = "";
	tx_InfoModel.text = "";
	tx_InfoLensMake.text = "";
	tx_InfoLensModel.text = "";
	tx_InfoDate.text = "";
	tx_InfoOrient.text = "";
	tx_InfoSens.text = "";
	tx_InfoExpo.text = "";
	tx_InfoFNum.text = "";
	tx_InfoFocal.text = "";
	tx_InfoProgram.text = "";
	tx_InfoFlash.text = "";
	tx_InfoMetering.text = "";
	tx_InfoWhitebal.text = "";
	tx_InfoBias.text = "";
	tx_InfoCSpace.text = "";
	tx_InfoExpomode.text = "";
	tx_InfoLightSource.text = "";
	tx_imgInfo2.text = "";
	tx_imgInfo.text = "Image:";
	tx_type.text = "";
	img.visible = false;
	img270.visible = false;
	if (gifloader_ != null) {
		gifloader_.stopGif();
		gifloader_ = null;
	}
	hideAudioPlayer();
	hideVideoPlayer();
	if (!txt.visible && !txt_nb.visible) {
		txt.visible = true;
	}
	var path:String = fs_importFiles.selectedPath;
	if (path == lastSelectedPath && isFullDisplay) {
		ShowFullContent();
		return;
	}
	lastSelectedPath = path;
	isFullDisplay = false;
	//if (txt.visible) {
		//txt.initialize(); // does nothing
		//txt.scrollToRange (0,0); // crashes
	if (path == null) {
		tx_size.text = "";
		tx_date.text = "[no info]";
		return;
	}
	try {
		var file:File = new File (path);
		if (file.isSymbolicLink) {
			tx_type.text = "Symbolic Link";
			tx_size.text = "";
			tx_date.text = "[no info]";
			txt.text = copyright;
			txt_nb.text = copyright;
			return;
		}
		var dt:Date = file.modificationDate;
		tx_date.text = dt.toLocaleString();
		
		if (file.isDirectory) {
			txt.text = copyright;
			txt_nb.text = copyright;
			tx_size.text = getDirContentInfo (file);
			if (file.isPackage) {
				tx_type.text = "Package";
			}
			return;
		}
		full_len = file.size;
		tx_size.text = getSizeStr (full_len) + " bytes";
		
		var curext:String = "";
		if (file.extension != null) {
			curext = file.extension;
		}
		var extU:String = curext.toLocaleUpperCase(); 
		//txt.text = "File extension is: " + ext;
		//var curLine:String = "";
		var fstr:FileStream = new FileStream();
		fstr.open (file, FileMode.READ);
		var len:Number = full_len;
		if (len == 0) {
			fstr.close();
			txt.text = copyright;
			txt_nb.text = copyright;
			return;
		}
		else if (len > 100000) {
			len = 100000;
		}
		short_len = len;
		var urlstr:String = "file://";
		urlstr += path;
		
		if (ch_Binary.selected) {
			txt_nb.visible = false;
			txt.visible = true;
			txt.setStyle("fontFamily", fontFamilyCourier_);
			ShowBinaryContent (fstr, len);
		}
		else if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
			txt.visible = false;
			txt_nb.visible = false;
			if (extU == "GIF") {
				gifloader_ = new GifLoader();
				gifloader_.loadGif (file, img);
				tx_imgInfo.text = "Image: " + gifloader_.getImageSize();
				tx_imgInfo2.text = gifloader_.getImageCount();
				return;
			}
			var rotate:Boolean = showExifInfo (fstr, full_len);
			fstr.close();

			var req:URLRequest = new URLRequest (urlstr);
			var ldr:Loader = new Loader();
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
			var context:LoaderContext = new LoaderContext();
			if (rotate) {
				img.loaderContext = null;
				img.source = null;
				img270.visible = true;
				img270.loaderContext = context;
			}
			else {
				img270.loaderContext = null;
				img270.source = null;
				img.visible = true;
				img.loaderContext = context;
			}
			ldr.load(req);
		}
		else if (extU == "MP3") {
			txt.visible = false;
			txt_nb.visible = false;
			showMP3Info (fstr, full_len);
			fstr.close();
			showAudioPlayer (path, false, false);
		}
		else if (extU == "WAV" || extU == "AIF" || extU == "AIFF") {
			txt.visible = false;
			txt_nb.visible = false;
			fstr.close();
			showAudioPlayer (path, true, extU != "WAV");
		}
		else if (extU == "MP4" || extU == "M4V" || extU == "F4V" || extU == "FLV" || extU == "MOV" ||
			     extU == "MP4V" || extU == "3GP" || extU == "3G2" || extU == "M4A" || extU == "AAC" ||
				 extU == "MTS" || extU == "AVI" || extU == "WMV" || extU == "VOB" || extU == "MPA")
		{
			txt.visible = false;
			txt_nb.visible = false;
			fstr.close();
			showVideoPlayer (urlstr);
		}
		else {
			//txt.setStyle("color", 0xFF0000);
			//txt.setStyle("fontFamily", "Courier");
			ShowTextContent (fstr, len);
		}
	}
	catch (error:Error) {
		//var msg:String = "Cannot read file !";
		//Alert.show (msg, "Error", Alert.OK, this);
		txt.text = copyright;
		txt_nb.text = copyright;
		tx_size.text = "";
		tx_date.text = "[no info*]";
	}
}

private function getDirContentInfo (file:File):String
{
	var retStr:String = "";
	var dirCount:int = 0;
	var fileCount:int = 0;
	try {
		var files:Array = file.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			if (f.isDirectory) {
				dirCount++;
			}
			else {
				fileCount++;
			}
		}
	}
	catch (error:Error) {
	}
	retStr = dirCount.toString() + " Subfolder(s), " + fileCount.toString() + " File(s)";
	
	return retStr;
}

private function ShowFullContent():void
{
	img.visible = false;
	img270.visible = false;
	txt.content = "";
	txt_nb.content = "";
	//txt.validateNow(); // crashes
	isFullDisplay = true;
	full_len = 0;
	text_len = 0;
	var path:String = fs_importFiles.selectedPath;
	if (path == null) {
		tx_size.text = "";
		tx_date.text = "[no info]";
		return;
	}
	try {
		var file:File = new File (path);
		full_len = file.size;
		
		var fstr:FileStream = new FileStream();
		fstr.open (file, FileMode.READ);
		var len:Number = full_len;
		if (len == 0) {
			fstr.close();
			txt.text = copyright;
			txt_nb.text = copyright;
			return;
		}
		if (ch_Binary.selected) {
			txt_nb.visible = false;
			txt.visible = true;
			txt.setStyle("fontFamily", fontFamilyCourier_);
			ShowBinaryContent (fstr, len);
			//txt.scrollToRange (0,0); // crashes
		}
		else {
			ShowTextContent (fstr, len);
		}
	}
	catch (error:Error) {
		txt.text = copyright;
		txt_nb.text = copyright;
		tx_size.text = "";
		tx_date.text = "[no info*]";
	}
}

private function ShowBinaryContent (fstr:FileStream, len:int):void
{
	var cl:int = 0;
	var tx:String = "";
	var content:String = "";
	
	for (var ixb:uint = 0; ixb < len; ixb++) {
		var b:uint = fstr.readUnsignedByte();
		if (cl == 0) {
			content += getFixString (ixb);
			content += "  ";
			content += getHex (b);
			content += " ";
		}
		else if (cl == 7) {
			content += getHex (b);
			content += "  ";
		}
		else {
			content += getHex (b);
			content += " ";
		}
		if (b < 32 || b > 126) {
			tx += ".";
		}
		else {
			tx += String.fromCharCode(b);
		}
		cl++;
		if (cl == 16 || ixb == len - 1) {
			for (var i:int = 0; i < 16 - cl; i++) {
				content += "   ";
				if (i == 7) {
					content += " ";
				}
			}
			cl = 0;
			content += "  ";
			content += tx;
			content += "\n";
			tx = "";
		}
	}
	txt.text = content;
	text_len = content.length;
	
}

private function ShowTextContent (fstr:FileStream, len:int):void
{
	var wasLF:Boolean = false;
	var wasCR:Boolean = false;
	var content:String = "";
	var lineLength:int = 0;
	var isWrap:Boolean = ch_Wrap.selected;
	if (isWrap) {
		txt_nb.visible = false;
		txt.visible = true;
	}
	else {
		txt.visible = false;
		txt_nb.visible = true;
	}

	for (var ix:uint = 0; ix < len; ix++, lineLength++) {
		var bt:int = fstr.readByte();
		if (bt == 10) {
			if (!wasCR) {
				content += "\n";
				lineLength = 0;
			}
			wasLF = true;
			wasCR = false;
		}
		else if (bt == 13) {
			//if (!wasLF) {
				content += "\n";
				lineLength = 0;
			//}
			wasCR = true;
			wasLF = false;
		}
		else if (bt == 9) {
			wasLF = false;
			wasCR = false;
			content += "    ";
		}
		else if (bt < 32 && bt != 127) {
			wasLF = false;
			wasCR = false;
			content += ".";
		}
		else {
			wasLF = false;
			wasCR = false;
			content += String.fromCharCode(bt);
		}
	}
	if (isWrap) {
		txt.text = content;
	}
	else {
		txt_nb.text = content;
	}
	text_len = content.length;	
}

private function showAudioPlayer (path:String, isWave:Boolean, isAIFF:Boolean):void
{
	bt_play.label = "PLAY";
	bt_play.visible = true;
	bt_play.enabled = false;
	sound_ = new Sound();
	//channel_ = new SoundChannel();
	sound_.addEventListener (Event.COMPLETE, onLoadSndComplete);
	// loadPCMFromByteArray(bytes:ByteArray, samples:uint, format:String = "float", stereo:Boolean = true, sampleRate:Number = 44100.0):void
	addEventListener(Event.ENTER_FRAME, onEnterFrame);
	if (isWave) {
		isWaveFormatAiff_ = isAIFF;
		wavePosition_ = 0;
		var numsamples:uint = 0;
		if (isWaveFormatAiff_) {
			numsamples = Utilities.readAiffFile (path); // numsamples per stereo channel
		}
		else {
			numsamples = Utilities.readWaveFile (path);
		}
		//trace("wave samples read: " +  numsamples);
		sound_.loadPCMFromByteArray (Utilities.wavechunk_1, numsamples);
		//var total:int = sound_.bytesTotal; // bytes for 1 stereo channel (samples * 4)
		waveLength_ = numsamples * 10 / 441; // in ms
		alreadyPlayed_ = 0;
		bt_play.enabled = true;
		enterFrameCount_ = 0;
		showTotalTime (Utilities.waveSizeMilliSecs_ / 1000);
		tx_year.text = "Channels:   " + Utilities.waveNumChannels_.toString();
		tx_genre.text = "Samples per second:   " + Utilities.waveSampleRate_.toString();
		tx_track.text = "Bits per sample:   " + Utilities.waveBitsPerSample_.toString();
		tx_year.visible = true;
		tx_genre.visible = true;
		tx_track.visible = true;
	}
	else {
		waveLength_ = -1;
		var urlstr:String = "file://";
		urlstr += path;
		var req:URLRequest = new URLRequest (urlstr);
		sound_.load (req, new SoundLoaderContext());
		tx_length.text = "Total Length:  ";
	}
	bt_fw1.visible = true;
	bt_fw2.visible = true;
	bt_fw3.visible = true;
	bt_bw1.visible = true;
	bt_bw2.visible = true;
	bt_bw3.visible = true;
	tx_playtime.text = "0:00:00";
	tx_playtime.visible = true;
	playPosition_ = 0;
	tx_peakvalue.text = "Peak:  ";
	tx_peakvalue.visible = true;
	tx_length.visible = true;
	progressbar.setProgress (0, 1);
	progressbar.visible = true;
	peakValue_ = 0;
}

private function hideAudioPlayer():void
{
	bt_play.visible = false;
	tx_playtime.visible = false;
	tx_peakvalue.visible = false;
	tx_songname.visible = false;
	tx_artist.visible = false;
	tx_album.visible = false;
	tx_year.visible = false;
	tx_genre.visible = false;
	tx_track.visible = false;
	tx_length.visible = false;
	bt_fw1.visible = false;
	bt_fw2.visible = false;
	bt_fw3.visible = false;
	bt_bw1.visible = false;
	bt_bw2.visible = false;
	bt_bw3.visible = false;
	progressbar.visible = false;
	if (channel_ != null) {
		channel_.stop();
	}
	removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	sound_ = null;
	channel_ = null;
	playPosition_ = 0;
	peakValue_ = 0;
	wavePosition_ = 0;
	waveLength_ = -1;
	enterFrameCount_ = 0;
	alreadyPlayed_ = 0;
	numSamplesLoaded_ = 0;
	Utilities.initializeWave();
}

private function showVideoPlayer (path:String):void
{
	// supported:
	// MP4, M4V, F4V, 3GPP, FLV
	// F4V, MP4, M4A, MOV, MP4V, 3GP, and 3G2
	videogroup.visible = true;
	vplayer.source = path;
	vplayer.videoObject.smoothing = true;
	vplayer.play();
	// videoObject : Video
}

private function netStatusHandler(event:NetStatusEvent):void 
{
}

private function hideVideoPlayer ():void
{
	if (stream_ != null && player_ != null) {
		stream_.close();
		videogroup.removeChild(player_);
		//videogroup.removeChildAt(0);
	}
	vplayer.stop();
	videogroup.visible = false;
}

private function onLoadSndComplete (event:Event):void
{
	bt_play.enabled = true;
	if (sound_ != null) {
		showTotalTime (sound_.length / 1000);
	}
}

private function showTotalTime (secs:int):void
{
	tx_length.text = "Total Length:   ";
	var hr:int = secs / 3600;
	var mn:int = (secs % 3600) / 60;
	var sc:int = (secs % 3600) % 60;
	var mn_str:String = mn.toString();
	var sc_str:String = sc.toString();
	if (mn_str.length < 2) {
		mn_str = "0" + mn_str;
	}
	if (sc_str.length < 2) {
		sc_str = "0" + sc_str;
	}
	tx_length.text += hr.toString() + ":" + mn_str + ":" + sc_str;
}

private function showMP3Info (fs:FileStream, len:int):void
{
	var record:Array = new Array();
	var idstr:String = "";
	var title:String = "";
	var artist:String = "";
	var album:String = "";
	var year:String = "";
	var genre:String = "";
	var track:String = "";
	var version:uint = 0;
	var framestr:String = "";

	var beginContent:uint = 0; 
	var lengthContent:uint = 0; 

	tx_songname.text = "Song name:   ";
	tx_artist.text = "Artist:   ";
	tx_album.text = "Album:   ";
	tx_year.text = "Year:   ";
	tx_genre.text = "Genre:   ";
	tx_track.text = "Track:   ";
	tx_songname.visible = true;
	tx_artist.visible = true;
	tx_album.visible = true;
	tx_year.visible = true;
	tx_genre.visible = true;
	tx_track.visible = true;
	
	if (len > 1000) {
		len = 1000;
	}
	for (var i:uint = 0; i < len; i++) {
		var b:uint = 0;
		b = fs.readUnsignedByte();
		record.push (b);
	}
	fs.position = 0;
	
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = 0;
		bt = fs.readUnsignedByte();
		if ( ix < 3) {
			idstr += String.fromCharCode (bt);
		}
		else if (ix == 3) {
			if (idstr != "ID3") {
				return;
			}
			version = bt;
			if (version < 2 || version > 3) {
				return;
			}
		}
		else if (ix >= 10) {
			if (bt > 0) {
				framestr += String.fromCharCode (bt);
				if (version == 2) {
					if (framestr.length == 3) {
						beginContent = ix + 5;
						if (framestr == "TAL" && album.length == 0) {
							album = getID3_V2Value (record, beginContent);
						}
						else if (framestr == "TT2" && title.length == 0) {
							title = getID3_V2Value (record, beginContent);
						}
						else if (framestr == "TP1" && artist.length == 0) {
							artist = getID3_V2Value (record, beginContent);
						}
						else if (framestr == "TRK" && track.length == 0) {
							track = getID3_V2Value (record, beginContent);
						}
						else if (framestr == "TYE" && year.length == 0) {
							year = getID3_V2Value (record, beginContent);
						}
						else if (framestr == "TCO" && genre.length == 0) {
							genre = getID3_V2Value (record, beginContent);
						}
						framestr = "";
					}
				}
				else { // version 3
					if (framestr.length == 4) {
						beginContent = ix + 1;
						if (framestr == "TALB" && album.length == 0) {
							album = getID3_V3Value (record, beginContent);
						}
						else if (framestr == "TIT2" && title.length == 0) {
							title = getID3_V3Value (record, beginContent);
						}
						else if (framestr == "TPE1" && artist.length == 0) {
							artist = getID3_V3Value (record, beginContent);
						}
						else if (framestr == "TRCK" && track.length == 0) {
							track = getID3_V3Value (record, beginContent);
						}
						else if (framestr == "TYER" && year.length == 0) {
							year = getID3_V3Value (record, beginContent);
						}
						else if (framestr == "TCON" && genre.length == 0) {
							genre = getID3_V3Value (record, beginContent);
						}
						framestr = "";
					}
				}
			}
			else {
				framestr = "";
			}
		}
	}
	tx_songname.text += title;
	tx_artist.text += artist;
	tx_album.text += album;
	tx_year.text += year;
	tx_genre.text += genre;
	tx_track.text += track;
}

private function getID3_V2Value (arr:Array, index:uint):String
{
	var retStr:String = "";
	for (var ix:int = index; ix < arr.length; ix++) {
		if (arr[ix] == 0) {
			break;
		}
		retStr += String.fromCharCode (arr[ix]);
	}
	return retStr;
}

private function getID3_V3Value (arr:Array, index:uint):String
{
	var pos:int = 0;
	var retStr:String = "";
	var len:int = arr[index + 3];
	for (var ix:int = index + 7; ix < arr.length; ix++) {
		retStr += String.fromCharCode (arr[ix]);
		if (retStr.length == len - 1 || arr[ix] == 0) { // the byte before the string is included in len
			break;
		}
	}
	return retStr;
}


private function OnPlayAudio():void
{
	if (sound_ == null) {
		return;
	}
	var pausePosition:int = 0;
	if (channel_ != null) {
		pausePosition = channel_.position;
	}
	
	if (bt_play.label == "PLAY") {
		channel_ = sound_.play (pausePosition);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		//channel_.addEventListener (Event.SOUND_COMPLETE,sndCompleteHandler);
		bt_play.label = "PAUSE";
	}
	else {
		if (channel_ != null) {
			channel_.stop();
		}
		//channel_.removeEventListener (Event.SOUND_COMPLETE,sndCompleteHandler);
		bt_play.label = "PLAY";
	}
}

private function OnForBack(event:MouseEvent):void
{
	if (sound_ == null || channel_ == null || Utilities.isReadingFile_) {
		return;
	}
	channel_.stop();
	var total:int = sound_.length;
	var curPosition:int = channel_.position;
	var increment:int = -60000; // button 1
	if (event.target.left > 420) {
		increment = 60000; // button 6
	}
	else if (event.target.left > 360) {
		increment = 15000; // button 5
	}
	else if (event.target.left > 300) {
		increment = 3000; // button 4
	}
	else if (event.target.left > 140) {
		increment = -3000; // button 3
	}
	else if (event.target.left > 80) {
		increment = -15000; // button 2
	}

	if (increment < 0) {
		playPosition_ = 0; // to update the time display
	}
	
	if (waveLength_ > 0) { // length of current portion
		var newCurPos:int = curPosition + increment;
		if (newCurPos >= 0 && newCurPos < waveLength_) {
			channel_ = sound_.play (newCurPos);
		}
		else {
			total = Utilities.waveSizeMilliSecs_;
			var curWavePosition:int = curPosition + alreadyPlayed_;
			var newPos:int = curWavePosition + increment;
			if (newPos < 0) {
				newPos = 0;
			}
			else if (newVal > total) {
				newPos = total;
			}
			//trace("OnForBack, curWavePosition = " +  curWavePosition);
			//trace("OnForBack, new WavePosition = " +  newPos);
			var result:Object = Utilities.getWaveDataAtPosition (newPos, ! isWaveFormatAiff_);
			numSamplesLoaded_ = result.kCount;

			if (numSamplesLoaded_ > 0) {
				var chunks:uint = newPos / 10000;
				alreadyPlayed_ = chunks * 10000;
				var diffpos:int = newPos % 10000;
				//trace("OnForBack, play position = " +  diffpos);
				sound_.loadPCMFromByteArray (result.kWave, numSamplesLoaded_);
				channel_ = sound_.play (diffpos);
			}
			else {
				channel_ = sound_.play (curPosition);
			}
		}
	}
	else {
		var newVal:int = curPosition + increment;
		if (newVal < 0) {
			newVal = 0;
		}
		else if (newVal > total) {
			newVal = total;
		}
		channel_ = sound_.play (newVal);
	}
}

private function onEnterFrame(event:Event):void 
{ 
	if (sound_ == null || channel_ == null) {
		return;
	}
	enterFrameCount_++;
	var position:int = channel_.position;
	var totalpos:int = alreadyPlayed_ + position;
	var curTotalLength:Number = sound_.length;
	
	if (waveLength_ > 0 && position > 0) {
		curTotalLength = Utilities.waveSizeMilliSecs_;
		if (position >= waveLength_) {
			channel_.stop();
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			//sound_.close(); // exception
			//trace("Stop playing, current position: " +  position);
			bt_play.label = "PLAY";
		}
		else if (position < 5000 && !Utilities.isReadingFile_) {
			//trace("onEnterFrame, current position: " +  position);
			if (isWaveFormatAiff_) {
				Utilities.readNextAiffChunk();
			}
			else {
				Utilities.readNextWaveChunk();
			}
			numSamplesLoaded_ = 0;
		}
		else if (position > 10000) {
			channel_.stop();
			alreadyPlayed_ += 10000;
			//trace("onEnterFrame position > 10000, alreadyPlayed_ = " +  alreadyPlayed_);
			var result:Object = Utilities.getWaveDataAtPosition (alreadyPlayed_, !isWaveFormatAiff_);
			numSamplesLoaded_ = result.kCount;
			if (numSamplesLoaded_ > 0) {
				position = channel_.position;
				var diffpos:int = position - 10000;
				sound_.loadPCMFromByteArray (result.kWave, numSamplesLoaded_);
				waveLength_ = numSamplesLoaded_ * 10 / 441; // in ms
				channel_ = sound_.play (diffpos);
			}
			else {
				alreadyPlayed_ -= 10000;
				channel_ = sound_.play (position);
			}
		}
	}
	var playpos:int = position / 1000;
	if (waveLength_ > 0) {
		playpos = totalpos / 1000;
		position = totalpos;
	}
	var lpeak:int = channel_.leftPeak * 100;
	var rpeak:int = channel_.rightPeak * 100;
	if (rpeak > lpeak) {
		lpeak = rpeak;
	}
	if (peakValue_ < lpeak) {
		peakValue_ = lpeak;
	}

	if (playpos > playPosition_) {
		playPosition_ = playpos;
		var hr:int = playPosition_ / 3600;
		var mn:int = (playPosition_ % 3600) / 60;
		var sc:int = (playPosition_ % 3600) % 60;
		var mn_str:String = mn.toString();
		var sc_str:String = sc.toString();
		if (mn_str.length < 2) {
			mn_str = "0" + mn_str;
		}
		if (sc_str.length < 2) {
			sc_str = "0" + sc_str;
		}
		tx_playtime.text = hr.toString() + ":" + mn_str + ":" + sc_str;
		tx_peakvalue.text = "Peak:   " + peakValue_.toString() + " %";
		if (bt_play.label == "PLAY") {
			bt_play.label = "PAUSE";
		}
	}
	progressbar.setProgress (position, curTotalLength);
}

private function sndCompleteHandler (event:Event):void
{
	channel_.removeEventListener (Event.SOUND_COMPLETE,sndCompleteHandler);
	bt_play.label = "PLAY";
	
}

private function showExifInfo (fs:FileStream, len:int):Boolean
{
	var isPortrait:Boolean = false;
	var record:Array = new Array();
	var idstr:String = "";
	var bt14:uint = 0;
	var bt_1:uint = 0; 
	var bigEnd:Boolean = false;
	var firstByte:Boolean = true;
	const make_id:uint = 0x010f;
	const model_id:uint = 0x0110;
	const orient_id:uint = 0x0112;
	const date_id:uint = 0x0132;
	const exposure_id:uint = 0x829a;
	const fnum_id:uint = 0x829d;
	const sens_id:uint = 0x8827;
	const iso_id:uint = 0x8833;
	const flash_id:uint = 0x9209;
	const focal_id:uint = 0x920a;
	const focal35_id:uint = 0xa405;
	const program_id:uint = 0x8822;
	const lensmake_id:uint = 0xa433;
	const lensmodel_id:uint = 0xa434;
	const metering_id:uint = 0x9207;
	const whitebal_id:uint = 0xA403;
	const bias_id:uint = 0x9204;
	const cspace_id:uint = 0xA001;
	const expomode_id:uint = 0xA402;
	const lightsource_id:uint = 0x9208;

	if (len > 10000) {
		len = 10000;
	}
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = 0;
		bt = fs.readUnsignedByte();
		if (ix > 5 && ix < 10) {
			idstr += String.fromCharCode (bt);
		}
		if (ix == 14) {
			bt14 = bt;
		}
		if (ix == 15) {
			if (bt14 == 0 && bt > 0) {
				bigEnd = false;
			}
			else if (bt14 > 0 && bt == 0) {
				bigEnd = true;
			}
			else {
				return isPortrait;
			}
			if (idstr != "Exif") {
				return isPortrait;
			}
		}
		if (ix > 11) {
			if (firstByte) {
				bt_1 = bt;
				firstByte = false;
			}
			else {
				if (bigEnd) {
					record.push (bt * 256 + bt_1);
				}
				else {
					record.push (bt_1 * 256 + bt);
				}
				firstByte = true;
			}
		}
	}
	var entry:Object = new Object();
	entry.kStr = "";
	entry.kStr2 = "";
	entry.kStr3 = "";
	entry.kStr4 = "";
	entry.kInt = 0;
	tx_InfoMake.text = "Make: ";
	if (getExifValueFromString (record, make_id, entry, bigEnd)) {
		tx_InfoMake.text += entry.kStr;
	}
	tx_InfoModel.text = "Model: ";
	if (getExifValueFromString (record, model_id, entry, bigEnd)) {
		tx_InfoModel.text += entry.kStr;
	}
	//if (getExifValueFromString (record, lensmake_id, entry, bigEnd)) {
	//	tx_InfoLensMake.text = "Lens Make: " + entry.kStr;
	//}
	tx_InfoLensMake.text = "Lens Model: ";
	if (getExifValueFromString (record, lensmodel_id, entry, bigEnd)) {
		tx_InfoLensModel.text = entry.kStr;
	}
	tx_InfoDate.text = "Date: ";
	if (getExifValueFromString (record, date_id, entry, bigEnd)) {
		tx_InfoDate.text += entry.kStr;
	}
	tx_InfoOrient.text = "Orientation: ";
	if (getExifValueFromShort (record, orient_id, entry, bigEnd)) {
		if (entry.kInt > 0 && entry.kInt < 5) {
			tx_InfoOrient.text += " landscape";
		}
		else if (entry.kInt > 0 && entry.kInt < 9) {
			tx_InfoOrient.text += " portrait";
			isPortrait = true;
		}
	}
	tx_InfoSens.text = "Sensitivity: ";
	if (getExifValueFromLong (record, iso_id, entry, bigEnd)) {
		tx_InfoSens.text += entry.kStr;
	}
	else if (getExifValueFromShort (record, sens_id, entry, bigEnd)) {
		tx_InfoSens.text += entry.kStr;
	}
	tx_InfoExpo.text = "Exposure time: ";
	if (getExifValueFromRational (record, exposure_id, entry, bigEnd)) {
		tx_InfoExpo.text += entry.kStr;
	}
	tx_InfoFNum.text = "F Number: ";
	if (getExifValueFromRational (record, fnum_id, entry, bigEnd)) {
		tx_InfoFNum.text += entry.kStr3;
	}
	tx_InfoFocal.text = "Focal length: ";
	if (getExifValueFromRational (record, focal_id, entry, bigEnd)) {
		tx_InfoFocal.text += entry.kStr2;
	}
	if (getExifValueFromShort (record, focal35_id, entry, bigEnd)) {
		tx_InfoFocal.text += " (equ " + entry.kStr + ")";
	}
	tx_InfoProgram.text = "Program: ";
	if (getExifValueFromShort (record, program_id, entry, bigEnd)) {
		if (entry.kInt == 0) {
			tx_InfoProgram.text += "undefined";
		}
		else if (entry.kInt == 1) {
			tx_InfoProgram.text += "manual";
		}
		else if (entry.kInt == 2) {
			tx_InfoProgram.text += "normal";
		}
		else if (entry.kInt == 3) {
			tx_InfoProgram.text += "aperture priority";
		}
		else if (entry.kInt == 4) {
			tx_InfoProgram.text += "shutter priority";
		}
		else if (entry.kInt == 5) {
			tx_InfoProgram.text += "creative";
		}
		else if (entry.kInt == 6) {
			tx_InfoProgram.text += "action";
		}
		else if (entry.kInt == 7) {
			tx_InfoProgram.text += "portrait";
		}
		else if (entry.kInt == 8) {
			tx_InfoProgram.text += "landscape";
		}
		else if (entry.kInt > 0) {
			tx_InfoProgram.text += "other (" + entry.kStr  + ")";
		}
	}
	tx_InfoFlash.text = "Flash used: ";
	if (getExifValueFromShort (record, flash_id, entry, bigEnd)) {
		if (entry.kInt % 2 > 0) { // bit 0 is set
			tx_InfoFlash.text += "Yes";
		}
		else {
			tx_InfoFlash.text += "No";
		}
	}
	tx_InfoMetering.text = "Metering mode: ";
	if (getExifValueFromShort (record, metering_id, entry, bigEnd)) {
		if (entry.kInt == 1) {
			tx_InfoMetering.text += "average";
		}
		else if (entry.kInt == 2) {
			tx_InfoMetering.text += "center weigh.";
		}
		else if (entry.kInt == 3) {
			tx_InfoMetering.text += "spot";
		}
		else if (entry.kInt == 4) {
			tx_InfoMetering.text += "multi-spot";
		}
		else if (entry.kInt == 5) {
			tx_InfoMetering.text += "pattern";
		}
		else if (entry.kInt == 6) {
			tx_InfoMetering.text += "partial";
		}
		else {
			tx_InfoMetering.text += "unknown";
		}
	}
	tx_InfoWhitebal.text = "White balance: ";
	if (getExifValueFromShort (record, whitebal_id, entry, bigEnd)) {
		if (entry.kInt == 0) {
			tx_InfoWhitebal.text += "auto";
		}
		else if (entry.kInt == 1) {
			tx_InfoWhitebal.text += "manual";
		}
	}
	tx_InfoBias.text = "Exposure bias: ";
	if (getExifValueFromRational (record, bias_id, entry, bigEnd)) {
		tx_InfoBias.text += entry.kStr4;
	}
	tx_InfoCSpace.text = "Color space: ";
	if (getExifValueFromShort (record, cspace_id, entry, bigEnd)) {
		if (entry.kInt == 1) {
			tx_InfoCSpace.text += "sRGB";
		}
		else {
			tx_InfoCSpace.text += "uncal.";
		}
	}
	tx_InfoExpomode.text = "Exposure mode: ";
	if (getExifValueFromShort (record, expomode_id, entry, bigEnd)) {
		if (entry.kInt == 0) {
			tx_InfoExpomode.text += "auto exp";
		}
		else if (entry.kInt == 1) {
			tx_InfoExpomode.text += "manual exp";
		}
		else if (entry.kInt == 2) {
			tx_InfoExpomode.text += "auto bracket";
		}
	}
	tx_InfoLightSource.text = "Light source: ";
	if (getExifValueFromShort (record, lightsource_id, entry, bigEnd)) {
		if (entry.kInt == 0) {
			tx_InfoLightSource.text += "auto";
		}
		else if (entry.kInt == 1) {
			tx_InfoLightSource.text += "daylight";
		}
		else if (entry.kInt == 2) {
			tx_InfoLightSource.text += "fluorescent";
		}
		else if (entry.kInt == 3) {
			tx_InfoLightSource.text += "tungsten";
		}
		else if (entry.kInt == 4) {
			tx_InfoLightSource.text += "flash";
		}
		else if (entry.kInt == 9) {
			tx_InfoLightSource.text += "fine weather";
		}
		else if (entry.kInt == 10) {
			tx_InfoLightSource.text += "cloudy w.";
		}
		else if (entry.kInt == 11) {
			tx_InfoLightSource.text += "shade";
		}
		else if (entry.kInt == 24) {
			tx_InfoLightSource.text += "ISO studio t.";
		}
		else {
			tx_InfoLightSource.text += "unknown light";
		}
	}
	return isPortrait;
}

private function getExifValueFromString (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 2) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len < 100) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (bigEnd) {
						offs = arr[pos + 4] + arr[pos + 5] * 65536;
					}
					else {
						offs = arr[pos + 4] * 65536 + arr[pos + 5];
					}
					for (var ix:int = offs / 2; ix < arlen; ix++) {
						if (bigEnd) {
							value.kStr += String.fromCharCode (arr[ix] % 256); // second byte at first
							value.kStr += String.fromCharCode (arr[ix] / 256);
						}
						else {
							value.kStr += String.fromCharCode (arr[ix] / 256);
							value.kStr += String.fromCharCode (arr[ix] % 256);
						}
						if (value.kStr.length >= len) {
							break;
						}
					}
					return true;
				}
			}
		}
		
	} while(pos > 0);
	return false;
}

private function getExifValueFromShort (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 3) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					value.kInt = arr[pos + 4];
					value.kStr = arr[pos + 4].toString();
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}

private function getExifValueFromLong (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 4 || arr[pos + 1] == 9) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					if (bigEnd) {
						value.kInt = arr[pos + 4] + arr[pos + 5] * 65536;
						value.kStr = value.kInt.toString();
					}
					else {
						value.kInt = arr[pos + 4] * 65536 + arr[pos + 5];
						value.kStr = value.kInt.toString();
					}
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}

private function getExifValueFromRational (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kStr2 = "";
	value.kStr3 = "";
	value.kStr4 = "";
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			var signed:int = -1;
			if (arr[pos + 1] == 5) {
				signed = 0;
			}
			else if (arr[pos + 1] == 10) {
				signed = 1;
			}
			if (signed >= 0) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (bigEnd) {
						offs = arr[pos + 4] + arr[pos + 5] * 65536;
					}
					else {
						offs = arr[pos + 4] * 65536 + arr[pos + 5];
					}
					
					var ix:int = offs / 2;
					var n1:Number = 0;
					var n2:Number = 0;
					var n3:Number = 0;
					if (signed) {
						var ras1:int = 0; 
						var ras2:int = 0; 
						if (bigEnd) {
							ras1 = int (arr[ix] + arr[ix + 1] * 65536);
							ras2 = int (arr[ix + 2] + arr[ix + 3] * 65536);
						}
						else {
							ras1 = int (arr[ix] * 65536 + arr[ix + 1]);
							ras2 = int (arr[ix + 2] * 65536 + arr[ix + 3]);
						}
						value.kStr4 = (ras1/ras2).toFixed(2);
						if (ras1 >= ras2) {
							value.kStr = value.kStr4;
						}
						else {
							n1 = ras2/ras1;
							if (n1 < 3) {
								value.kStr = "1/" + n1.toFixed(2);
							}
							else {
								value.kStr = "1/" + n1.toFixed(0);
							}
						}
						n1 = ras1;
						n2 = ras2;
						if (n2 != 0) {
							n3 = n1/n2;
							value.kStr2 = n3.toFixed(0);
							value.kStr3 = n3.toFixed(1);
						}
					}
					else {
						var ra1:uint = 0; 
						var ra2:uint = 0; 
						if (bigEnd) {
							ra1 = arr[ix] + arr[ix + 1] * 65536;
							ra2 = arr[ix + 2] + arr[ix + 3] * 65536;
						}
						else {
							ra1 = arr[ix] * 65536 + arr[ix + 1];
							ra2 = arr[ix + 2] * 65536 + arr[ix + 3];
						}
						value.kStr4 = (ra1/ra2).toFixed(2);
						if (ra1 >= ra2) {
							value.kStr = value.kStr4;
						}
						else {
							n1 = ra2/ra1;
							if (n1 < 3) {
								value.kStr = "1/" + n1.toFixed(2);
							}
							else {
								value.kStr = "1/" + n1.toFixed(0);
							}
						}
						n1 = ra1;
						n2 = ra2;
						if (n2 != 0) {
							n3 = n1/n2;
							value.kStr2 = n3.toFixed(0);
							value.kStr3 = n3.toFixed(1);
						}
					}
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}


private function OnLoadComplete (event:Event):void
{
	//var bmp:Bitmap = (evt.target as LoaderInfo).content as Bitmap;
	var loader:Loader = Loader(event.target.loader);
	var image:Bitmap = Bitmap(loader.content);
	tx_imgInfo.text = "Image: " + image.bitmapData.width.toString() + " x " + image.bitmapData.height.toString();
	image.smoothing = true;

	if (img.visible) {
		img.source = event.target.content;
	}
	else {
		img270.source = event.target.content;
	}
}


protected function OnWrap(event:Event):void
{
	OnFileChoose();
	fs_importFiles.setFocus();
}

protected function OnFont(event:Event):void
{
	if (ch_Font.selected) {
		txt.setStyle("fontFamily", "Arial");
		txt_nb.setStyle("fontFamily", "Arial");
	}
	else {
		txt.setStyle("fontFamily", fontFamilyCourier_);
		txt_nb.setStyle("fontFamily", fontFamilyCourier_);
	}
	OnFileChoose();
	fs_importFiles.setFocus();
}

protected function OnBinary(event:Event):void
{
	OnFileChoose();
	fs_importFiles.setFocus();
}

private function OnSetHomePath():void
{
	fs_importFiles.directory = File.desktopDirectory;
}

private function OnSetCustomPath (btn:int):void
{
	if (isAltKey_) {
		isAltKey_ = false;
		var p:String = "Do you want to save this path as preference ?\n\n";
		p += fs_importFiles.directory.nativePath;
		if (btn == 1) {
			Alert.show (p, "Save Path", 3, this, CustomPathDlgHandler1);
		}
		else {
			Alert.show (p, "Save Path", 3, this, CustomPathDlgHandler2);
		}
	}
	else {
		var dir:String = prefs_.getCustomPath2();
		if (btn == 1) {
			dir = prefs_.getCustomPath1();
		}
		if (dir.length > 0) {
			var dirFs:File = new File (dir);
			fs_importFiles.directory = dirFs;
		}
	}
}

private function CustomPathDlgHandler1 (event:CloseEvent):void
{
	if (event.detail == Alert.YES && prefs_ != null) {
		prefs_.setCustomPath1 (fs_importFiles.directory.nativePath);
	}
}

private function CustomPathDlgHandler2 (event:CloseEvent):void
{
	if (event.detail == Alert.YES && prefs_ != null) {
		prefs_.setCustomPath2 (fs_importFiles.directory.nativePath);
	}
}

private function getHex (b:uint):String
{
	var s:String = b.toString(16);
	if (s.length == 1) {
		s = "0" + s;
	}
	return s;
}

private function getFixString (b:uint):String
{
	var s:String = b.toString(10);
	if (s.length == 1) {
		s = "00000" + s;
	}
	else if (s.length == 2) {
		s = "0000" + s;
	}
	else if (s.length == 3) {
		s = "000" + s;
	}
	else if (s.length == 4) {
		s = "00" + s;
	}
	else if (s.length == 5) {
		s = "0" + s;
	}
	
	return s;
}


protected function OnKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey;
	var isAltKey:Boolean = event.altKey;
	var isShiftKey:Boolean = event.shiftKey;
	var key:uint = event.keyCode;
	//if (key == Keyboard.S && isControlKey) {

	
	//var msg:String = "Key pressed: ";
	//msg += key.toString(10);
	//Alert.show (msg, "Message", Alert.OK, this);
	
	if (key == Keyboard.LEFT) {
		if (fs_importFiles.canNavigateUp) {
			fs_importFiles.navigateUp();
			// scrollToIndex(index:int):Boolean
			StartAfterKeyTimer();
		}
	}
	else if (key == Keyboard.RIGHT) {
		var path:String = fs_importFiles.selectedPath;
		if (path != null) {
			var file:File = new File (path);
			if (file.isDirectory) {
				fs_importFiles.navigateDown();
				if (fs_importFiles.rowCount > 0) {
					fs_importFiles.selectedIndex = 0;
					StartAfterKeyTimer();
				}
			}
		}
	}
	else if (key == Keyboard.ENTER || key == Keyboard.SPACE) {
		if (bt_play.visible && bt_play.enabled) {
			OnPlayAudio();
		}
		else {
			doubleClickHandler_ (fs_importFiles.selectedPath);
		}
	}
	//else if (key == Keyboard.BACKSPACE && isControlKey) {
	else if (key == Keyboard.DELETE && isAltKey) {
		DeleteAction();
	}
	//else if (key == Keyboard.D && isAltKey) {
	else if (isControlKey && isAltKey) {
		var actionWindow:ChooseActionView = new ChooseActionView();
		actionWindow.open();
		isAltKey_ = false;
		return;
	}
	isAltKey_ = isAltKey;
}

private function DeleteAction():void
{
	var oldindex:int = fs_importFiles.selectedIndex;
	newPosition_ = oldindex;

	var paths:Array = fs_importFiles.selectedPaths;
	if (paths != null && paths.length > 0) {
		for (var ix:int = 0; ix < paths.length; ix++) {
			var fs:File = new File (paths[ix]);
			if (paths[ix].length > 7 && fs.exists) {
				try {
					fs.moveToTrash();
				}
				catch (error:Error) {
					Alert.show ("Error while deleting file.", "Exception");
					return;
				}
			}
		}
		fs_importFiles.refresh();
		StartAfterDelNewTimer();
	}
	
	//var p:String = fs_importFiles.selectedPath;
	//if (p != null) {
	//	var fs:File = new File (p);
	//	if (p.length > 7 && fs.exists) {
	//		if (p.substr(0, 8) == "/Volumes" || p.substr(0, 2) == "\\\\") {
	//			if (fs.isDirectory) {
	//				Alert.show ("Deleting a directory on a non-local path is not allowed.", "Delete File");
	//				return;
	//			}
	//		}
	//		try {
	//			fs.moveToTrash();
	//			fs_importFiles.refresh();
	//			StartAfterDelNewTimer();
	//		}
	//		catch (error:Error) {
	//			Alert.show ("The file cannot be moved to trash.\nDelete the file ?", "Delete File", 3, this, DeleteNonLocalHandler);
	//			return;
	//		}
	//	}
	//}
}

private function DeleteNonLocalHandler (event:CloseEvent):void
{
	if (event.detail == Alert.YES) {
		var p:String = fs_importFiles.selectedPath;
		if (p != null) {
			try {
				var fs:File = new File (p);
				fs.deleteFile();
				fs_importFiles.refresh();
				StartAfterDelNewTimer();
			}
			catch (error:Error) {
				Alert.show ("Error while deleting file.", "Exception");
			}
		}
	}
}


private function StartAfterDelNewTimer():void
{
	var tm:Timer = new Timer(50, 1);
	tm.addEventListener(TimerEvent.TIMER, OnAfterDelNewTimer);
	tm.start();
}

private function OnAfterDelNewTimer (event:TimerEvent):void
{
	var count:int = fs_importFiles.directory.getDirectoryListing().length;
	if (newPosition_ < 0) {
		fs_importFiles.selectedPath = newSelectedEntry_;
	}
	else if (newPosition_ < count) {
		fs_importFiles.selectedIndex = newPosition_;
	}
	else {
		fs_importFiles.selectedIndex = count - 1;
	}
	fs_importFiles.validateNow();
	fs_importFiles.scrollToIndex (fs_importFiles.selectedIndex);
	OnFileChoose();
}



protected function OnAppKeyDown(event:KeyboardEvent):void
{
	isAltKey_ = event.altKey;
	isControlKey_ = event.ctrlKey;
}

protected function OnAppKeyUp(event:KeyboardEvent):void
{
	isAltKey_ = false;
	isControlKey_ = false;
}

private function StartAfterKeyTimer():void
{
	var tm:Timer = new Timer(50, 1);
	tm.addEventListener(TimerEvent.TIMER, OnAfterKeyTimer);
	tm.start();
}

private function OnAfterKeyTimer(event:TimerEvent):void
{
	OnFileChoose();
}


public function SetKeyAfterChooseActionView (key:int):void
{
	var curext:String = "";
	var source:File = null;

	var curDir:File = fs_importFiles.directory;
	var selpath:String = fs_importFiles.selectedPath;
	if (selpath != null) {
		source = new File (selpath);
		if (source.extension != null) {
			curext = source.extension;
		}
	}
	var extU:String = curext.toLocaleUpperCase();

	if (key == Keyboard.F) {
		var fDlg:FolderDialog = new FolderDialog();
		fDlg.open();
		return;
	}
	else if (key == Keyboard.N) {
		NewFileAction();
		return;
	}

	if (selpath == null || source == null || curDir == null) {
		return;
	}
	var directory:File = curDir;

	if (key == Keyboard.D) {
		try {
			if (source.isDirectory || source.isSymbolicLink) {
				return;
			}
			var par:String = source.parent.nativePath;
			if (curext.length > 0) {
				curext = "." + curext;
			}
			var nm:String = source.name.substr(0, source.name.length - curext.length);
			nm += "_1";
			var targetpar:File = new File (par);
			var target:File = targetpar.resolvePath (nm + curext);
			while(target.exists) {
				nm += "1";
				if (nm.length > 200) {
					return;
				}
				target = targetpar.resolvePath (nm + curext);
			}
			source.copyTo (target, true);
			fs_importFiles.refresh();
		}
		catch (error:Error) {
			Alert.show ("Error while creating file.", "Exception");
		}
	}
	else if (key == Keyboard.X) {
		DeleteAction();
	}
	else if (key == Keyboard.R) {
		var nmWindow:FileNameView = new FileNameView();
		nmWindow.open();
		var path:String = fs_importFiles.selectedPath;
		if (path.length > 0) {
			var defFs:File = new File (path);
			var extnsn:String = "";
			if (defFs.extension != null && defFs.extension.length < 5) {
				extnsn = defFs.extension;
				extnsn = "." + extnsn;
			}
			var defName:String = defFs.name.substr(0, defFs.name.length - extnsn.length);
			nmWindow.SetDefaultName (defName);
		}
	}
	else if (key == Keyboard.E) {
		var extWindow:ExtensionView = new ExtensionView();
		extWindow.open();
	}
	else if (key == Keyboard.W) {
		if (extU == "WAV") {
			var wvWindow:EditWaveView = new EditWaveView();
			wvWindow.open();
		}
	}
	else if (key == Keyboard.Y) {
		if (lastTargetFolder_.length > 0) {
			var last1:File = new File (lastTargetFolder_);
			if (last1.exists) {
				directory = last1;
			}
		}
		try {
			directory.browseForDirectory("Select destination directory");
			directory.addEventListener(Event.SELECT, directorySelectedYCp);
		}
		catch (error:Error){
			//trace("Failed:", error.message);
		}
	}
	else if (key == Keyboard.I) {
		onGetInfo();
	}
	else if (key == Keyboard.T) {
		if (thumbwindow_ != null && thumbwindow_.visible) {
			thumbwindow_.nativeWindow.orderToFront();
		}
		else if (findAnyPicture()) {
			thumbwindow_ = new ThumbnailView();
			thumbwindow_.open();
			thumbwindow_.showThumbnails (source);
		}
	}
	else if (key == Keyboard.B) {
		if (source.size <= 20000000) {
			var binedit:TextEditBinView = new TextEditBinView();
			if (textBinViewWidth > 0 && textBinViewHeight > 0) {
				binedit.setSize (textBinViewWidth, textBinViewHeight);
			}
			binedit.open();
			binedit.loadTextFile (selpath);
		}
	}
	else if (key == Keyboard.C) {
		if (lastTargetFolder_.length > 0) {
			var last2:File = new File (lastTargetFolder_);
			if (last2.exists) {
				directory = last2;
			}
		}
		try {
			directory.browseForDirectory("Select destination directory");
			directory.addEventListener(Event.SELECT, directorySelectedCopy);
		}
		catch (error:Error){
			//trace("Failed:", error.message);
		}
	}
	else if (key == Keyboard.M) {
		if (lastTargetFolder_.length > 0) {
			var last3:File = new File (lastTargetFolder_);
			if (last3.exists) {
				directory = last3;
			}
		}
		try {
			directory.browseForDirectory("Select destination directory");
			directory.addEventListener(Event.SELECT, directorySelectedMove);
		}
		catch (error:Error){
			//trace("Failed:", error.message);
		}
	}
	else if (key == Keyboard.Z) {
		var delcount:int = Utilities.RemoveDSStoreFiles (selpath);
		var msg:String = "Files removed: " + delcount.toString();
		Alert.show (msg, ".DS_Store Cleanup");
	}
}

private function findAnyPicture():Boolean
{
	var curDir:File = fs_importFiles.directory;
	if (curDir != null) {
		try {
			var files:Array = curDir.getDirectoryListing();
			for (var i1:uint = 0; i1 < files.length; i1++) {
				var f:File = files[i1];
				if (!f.isDirectory) {
					var curext:String = "";
					if (f.extension != null) {
						curext = f.extension;
					}
					var extU:String = curext.toLocaleUpperCase();
					if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
						return true;
					}
				}
			}
		}
		catch (error:Error) {
		}
	}
	return false;
}

private function directorySelectedYCp(event:Event):void 
{
	var paths:Array = fs_importFiles.selectedPaths;
	if (paths != null && paths.length > 0) {
		try {
			var dest:File = event.target as File;

			for (var ix:int = 0; ix < paths.length; ix++) {
				var source:File = new File (paths[ix]);
				if (!copyRecursive (source, dest.resolvePath(source.name))) {
					Alert.show ("Could not copy file.", "Copy Action");
				}
			}
		}
		catch (error:Error) {
			Alert.show ("Error while copying file.", "Exception");
		}
	}
}

private function directorySelectedCopy(event:Event):void 
{
	var dest:File = event.target as File;
	directorySelectedCopyMove (dest, false);
}

private function directorySelectedMove(event:Event):void 
{
	var dest:File = event.target as File;
	directorySelectedCopyMove (dest, true);
}

private function directorySelectedCopyMove (dest:File, isMove:Boolean):void 
{
	if (dest == null || !dest.exists) {
		return;
	}
	if (filesToCopy_ == null) {
		filesToCopy_ = new Array();
	}
	if (filesToMove_ == null) {
		filesToMove_ = new Array();
	}
	filesToCopy_.length = 0;
	filesToMove_.length = 0;
	fileToCopyMove_ = new Object();
	lastTargetFolder_ = dest.nativePath;
	var paths:Array = fs_importFiles.selectedPaths;
	if (paths != null && paths.length > 0) {
		try {
			
			for (var ix:int = 0; ix < paths.length; ix++) {
				var source:File = new File (paths[ix]);
				var destFile:File = dest.resolvePath (source.name);
				if (destFile != null) {
					if (destFile.exists) {
						var obj:Object = new Object();
						obj.kSource = source;
						obj.kDestination = destFile;
						if (isMove) {
							filesToMove_.push(obj);
						}
						else {
							filesToCopy_.push(obj);
						}
					}
					else {
						source.copyTo (destFile);
						if (isMove) {
							source.moveToTrash();
						}
					}
				}
			}
		}
		catch (error:Error) {
			Alert.show ("Error while copying file.", "Exception");
		}
	}
	if (isMove) {
		var timer:Timer = new Timer(50, 1);
		timer.addEventListener (TimerEvent.TIMER, OnMoveRefreshTimer);
		timer.start();
	}
	askForCopyMove();
}

private function OnMoveRefreshTimer (event:TimerEvent):void
{
	fs_importFiles.refresh();
	OnFileChoose();
}

private function askForCopyMove():void
{
	if (filesToCopy_.length > 0) {
		askForMoveDialog_ = false;
		fileToCopyMove_ = filesToCopy_.pop();
	}
	else if (filesToMove_.length > 0) {
		askForMoveDialog_ = true;
		fileToCopyMove_ = filesToMove_.pop();
	}
	else {
		return;
	}
	
	Alert.show ("Overwrite existing file:\n" + fileToCopyMove_.kDestination.nativePath, "Copy/Move File", 3, this, OverwriteCopyMoveHandler);
}

private function OverwriteCopyMoveHandler (event:CloseEvent):void
{
	try {
		if (event.detail == Alert.YES) {
			var src:File = fileToCopyMove_.kSource;
			var dest:File = fileToCopyMove_.kDestination;
			src.copyTo (dest, true);
			if (askForMoveDialog_) {
				src.moveToTrash();
			}
		}
	}
	catch (error:Error) {
		Alert.show ("Error while copying/moving file.", "Exception");
	}
	var timer:Timer = new Timer(50, 1);
	timer.addEventListener (TimerEvent.TIMER, OnAskCopyMoveTimer);
	timer.start();
}

private function OnAskCopyMoveTimer (event:TimerEvent):void
{
	askForCopyMove();
	if (askForMoveDialog_) {
		fs_importFiles.refresh();
		OnFileChoose();
	}
}

private function copyRecursive (source:File, dest:File):Boolean
{
	if (source.isDirectory) {
		if (!dest.exists) {
			dest.createDirectory();
		}
		else if (!dest.isDirectory) {
			return false;
		}
		var files:Array = source.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			if (!copyRecursive (f, dest.resolvePath(f.name))) {
				return false;
			}
		}
		return true;
	}
	else if (!source.isHidden && !source.isSymbolicLink) {
		return CopyAction (source, dest, false);
	}
	return false;
}

private function NewFileAction():void
{
	var newfilePath:File = fs_importFiles.directory;
	if (newfilePath != null) {
		try {
			var cnt:uint = 0;
			var newFs:File = null;
			do {
				cnt++;
				newFs = newfilePath.resolvePath ("newfile_" + cnt + ".txt");
			} while (newFs.exists);
			var target:FileStream = new FileStream();
			target.open (newFs, FileMode.WRITE);
			target.close();
			doubleClickHandler_ (newFs.nativePath);
			fs_importFiles.refresh();
			newPosition_ = -1;
			newSelectedEntry_ = newFs.nativePath;
			StartAfterDelNewTimer();
		}
		catch (error:Error) {
			Alert.show ("Error while creating file.", "Exception");
		}
	}
}

public function ChangeFileExtension (ext:String):void
{
	var oldindex:int = fs_importFiles.selectedIndex;
	var path:String = fs_importFiles.selectedPath;
	//if (ext.length < 1) {
	//	return;
	//}
	if (path != null) {
		try {
			var source:File = new File (path);
			//if (source.isDirectory) {
			//	return;
			//}
			var oldext:String = "";
			if (source.extension != null) {
				oldext = source.extension;
				oldext = "." + oldext;
			}
			path = path.substr (0, path.length - oldext.length);
			path += "." + ext;
			var newFs:File = new File(path);
			if (newFs.exists) {
				Alert.show ("The file exists already.", "Rename");
			}
			else {
				source.moveTo (newFs);
				fs_importFiles.refresh();
				fs_importFiles.selectedIndex = oldindex;
			}
		}
		catch (error:Error) {
			Alert.show ("Error while renaming file.", "Exception");
		}
	}
}

public function ChangeFileName (name:String):void
{
	var oldindex:int = fs_importFiles.selectedIndex;
	var path:String = fs_importFiles.selectedPath;
	if (name.length < 1) {
		return;
	}
	if (path != null) {
		try {
			var source:File = new File (path);
			//if (source.isDirectory) {
			//	return;
			//}
			var oldext:String = "";
			if (source.extension != null && source.extension.length < 5) {
				oldext = source.extension;
			}
			var oldname:String = source.name;
			var oldpath:String = source.parent.nativePath;
			path = path.substr (0, path.length - oldext.length);
			var newFs:File = new File(oldpath);
			if (oldext.length > 0) {
				oldext = "." + oldext;
			}
			newFs = newFs.resolvePath (name + oldext);
			if (newFs.exists) {
				Alert.show ("The file exists already.", "Rename");
			}
			else {
				source.moveTo (newFs);
				fs_importFiles.refresh();
				fs_importFiles.selectedIndex = oldindex;
			}
		}
		catch (error:Error) {
			Alert.show ("Error while renaming file.", "Exception");
		}
	}
}

public function EditWaveFile (begin:uint, len:uint, norm:Boolean, swap:Boolean, conv44:Boolean, inSec:int, outSec:int):void
{
	var path:String = fs_importFiles.selectedPath;
	if (path != null && path.length > 0) {
		Utilities.editWaveFile (path, begin, len, norm, swap, conv44, inSec, outSec);
		fs_importFiles.refresh();
	}
}

private function CopyAction (srcFs:File, newFs:File, overwrite:Boolean):Boolean
{
	if (srcFs.exists) {
		if (!overwrite && newFs.exists) {
			copySourceFs_ = srcFs;
			copyDestFs_ = newFs;
			Alert.show ("Overwrite existing file:\n" + newFs.nativePath, "Copy File", 3, this, OverwriteHandler);
		}
		try {
			//fs.copyTo(new File("/Volumes/MEMSTICK_1G/" + fs.name)); // Test: creates resource file on FAT32
			var fstr:FileStream = new FileStream();
			fstr.open (srcFs, FileMode.READ);
			var len:Number = srcFs.size;
			
			//var targetFs:File = new File("/Volumes/MEMSTICK_1G/" + fs.name);
			var targetStream:FileStream = new FileStream();
			targetStream.open (newFs, FileMode.WRITE);
			
			for (var ix:Number = 0; ix < len; ix++) {
				var bt:uint = fstr.readUnsignedByte();
				targetStream.writeByte(bt);
			}
			
			fstr.close();
			targetStream.close();
			return true;
		}
		catch (error:Error) {
			Alert.show ("Error while copying file.", "Exception");
			return false;
		}
	}
	return false;
}

private function OverwriteHandler (event:CloseEvent):void
{
	if (event.detail == Alert.YES) {
		CopyAction (copySourceFs_, copyDestFs_, true);
	}
}

protected function OnDirectoryChange (event:FileEvent):void
{
	var timer:Timer = new Timer(50, 1);
	timer.addEventListener (TimerEvent.TIMER, OnDirChangeTimer);
	timer.start();
}

private function OnDirChangeTimer (event:TimerEvent):void
{
	var newDir:String = fs_importFiles.directory.nativePath;
	if (newDir.length < curDirectory.length) {
		//var lastName = curDirectory.substr (newDir.length + 1);
		var ix:int = fs_importFiles.findIndex (curDirectory);
		if (ix >= 0) {
			fs_importFiles.selectedIndex = ix;
			fs_importFiles.validateNow(); // O.K.
			fs_importFiles.scrollToIndex (ix);
		}
	}
	curDirectory = newDir;
	tx_path.text = curDirectory + " (" + fs_importFiles.directory.getDirectoryListing().length.toString() + ")";
	if (fs_importFiles.selectedIndex < 0 && fs_importFiles.rowCount > 0) {
		fs_importFiles.selectedIndex = 0;
	}
	fs_importFiles.setFocus();
	OnFileChoose();
}

protected function OnTextChanging (event:TextOperationEvent):void
{
	//if (event.operation == InsertTextOperation) {
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	//var copy_op:FlowOperation = CopyOperation;
	//if (op.isPrototypeOf (flashx.textLayout.operations.CopyOperation)) {
	if (opstr == "[object CopyOperation]") {
		return;
	}
	event.preventDefault();
}

protected function OnTextNBChanging (event:TextOperationEvent):void
{
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	if (opstr == "[object CopyOperation]") {
		return;
	}
	event.preventDefault();
}


protected function OnTextSelectionChange (event:FlexEvent):void
{
	//const var cman:ICursorManager = txt.cursorManager;
	//var xpos:int = txt.cursorManager.currentCursorXOffset;
	//var ypos:int = txt.cursorManager.currentCursorYOffset;
	//tx_cursor.text = "Line " + xpos.toString() + " Pos " + ypos.toString();
	
	//WriteDebugLogMessage("OnTextSelectionChange()");
	if (isFullDisplay || full_len > 50000000) { // do not try to show more than 50 MB
		return;
	}
	var anc:int = txt.selectionAnchorPosition;
	//WriteDebugLogMessage("Text position, text size: " + anc.toString() + ", " + text_len);
	if (anc > text_len * 0.9 && anc < text_len && full_len > short_len) {
		ShowFullContent();
	}
}

protected function OnTextNBSelectionChange (event:FlexEvent):void
{
	//WriteDebugLogMessage("OnTextNBSelectionChange()");
	if (isFullDisplay || full_len > 50000000) {
		return;
	}
	var anc:int = txt_nb.selectionAnchorPosition;
	//WriteDebugLogMessage("Text (NB) position, text size: " + anc.toString() + ", " + text_len);
	if (anc > text_len * 0.9 && anc < text_len && full_len > short_len) {
		ShowFullContent();
	}
}

private function renderHandler(event:FlexEvent):void // does not work
{
	txt.removeEventListener(FlexEvent.UPDATE_COMPLETE, renderHandler);
	txt_nb.removeEventListener(FlexEvent.UPDATE_COMPLETE, renderHandler);
	//tx_Busy.visible = false;
}

protected function doubleClickHandler(event:MouseEvent):void
{
	doubleClickHandler_ (fs_importFiles.selectedPath);
}

private function doubleClickHandler_ (path:String):void
{
	//var path:String = fs_importFiles.selectedPath;
	lastSelectedPath = path;
	if (path == null) {
		return;
	}
	try {
		var file:File = new File (path);
		if (file.isSymbolicLink || file.isDirectory) {
			return;
		}
		var curext:String = "";
		if (file.extension != null) {
			curext = file.extension;
		}
		var extU:String = curext.toLocaleUpperCase();
		if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
			var viewWindow:ImageView = new ImageView();
			if (imageViewWidth > 0 && imageViewHeight > 0) {
				viewWindow.setSize (imageViewWidth, imageViewHeight);
			}
			viewWindow.open();
			viewWindow.showImage (path);
		}
		else if (extU == "MP3" || extU == "MP4" || extU == "M4V" || extU == "F4V" || extU == "FLV" || extU == "MOV" || extU == "MPG" || extU == "MPEG" ||
			extU == "MP4V" || extU == "3GP" || extU == "3G2" || extU == "M4A" || extU == "AAC" || extU == "MTS" || extU == "AVI" || extU == "WMV" ||
			extU == "WAV" || extU == "FLAC" || extU == "AC3" || extU == "VOB" || extU == "AOB" || extU == "MPA")
		{
			// no extra view
		}
		else {
			if (file.size <= 20000000) {
				textWindow_ = new TextEditView();
				if (textViewWidth > 0 && textViewHeight > 0) {
					textWindow_.setSize (textViewWidth, textViewHeight);
				}
				textWindow_.open();
				textWindow_.loadTextFile (path);
			}
		}
	}
	catch (e:Error) {
	}
}

public function setEditorMemoryNumber (num:int):void
{
	if (textWindow_ != null) {
		textWindow_.setMemoryNumber (num);
	}
}

public function showImage (path:String):void
{
	var viewWindow:ImageView = new ImageView();
	if (imageViewWidth > 0 && imageViewHeight > 0) {
		viewWindow.setSize (imageViewWidth, imageViewHeight);
	}
	viewWindow.open();
	viewWindow.showImage (path);
}

public function setImgViewParameter (w:int, h:int):void
{
	imageViewWidth = w;
	imageViewHeight = h;
}

public function setTextViewParameter (w:int, h:int):void
{
	textViewWidth = w;
	textViewHeight = h;
}

public function setTextBinViewParameter (w:int, h:int):void
{
	textBinViewWidth = w;
	textBinViewHeight = h;
}

protected function getSizeStr (len:Number):String
{
	var str:String = "";
	var numstr:String = len.toString();
	var sz:int = numstr.length;
	var fst:int = sz % 3;
	if (sz < 4) {
		return numstr;
	}
	if (fst > 0) {
		str = numstr.substr(0, fst);
		numstr = numstr.substr(fst);
		str += ".";
	}
	do {
		if (numstr.length < 4) {
			str += numstr;
			return str;
		}
		str += numstr.substr (0, 3);
		numstr = numstr.substr (3);
		str += ".";
	} while (numstr.length > 0);
	
	return str;
}

public function setSelectedFile (name:String):void
{
	if (fs_importFiles.findString(name)) {
		fs_importFiles.validateNow();
		var ix:int = fs_importFiles.selectedIndex;
		fs_importFiles.scrollToIndex (ix);
	}
}

public function createFolder (name:String):void
{
	if (curDirectory == null) {
		return;
	}
	try {
		var newDir:File = new File (curDirectory);
		if (newDir.exists) {
			newDir = newDir.resolvePath (name);
			if (newDir.exists) {
				Alert.show ("The Folder exists already", "Create Folder");
			}
			else {
				newDir.createDirectory();
				fs_importFiles.refresh();
				var ix:int = fs_importFiles.findIndex (newDir.nativePath);
				if (ix >= 0) {
					fs_importFiles.selectedIndex = ix;
					fs_importFiles.validateNow(); // O.K.
					fs_importFiles.scrollToIndex (ix);
				}
				OnFileChoose();
			}
		}
	}
	catch (error:Error) {
		Alert.show ("Error while creating folder.", "Exception");
	}
}

private function onGetInfo():void
{
	if (curDirectory == null) {
		return;
	}
	var dirFs:File = null;
	var dlg:DirInfoDialog = new DirInfoDialog();
	var selStr:String = fs_importFiles.selectedPath;
	if (selStr == null || selStr.length == 0) {
		dirFs = new File (curDirectory);
	}
	else {
		dirFs = new File (selStr);
		if (!dirFs.isDirectory) {
			dirFs = new File (curDirectory);
		}
	}
	if (dirFs != null) {
		infoFileSize_ = 0;
		infoFileCount_ = 0;
		infoDirCount_ = 0;
		getInfo (dirFs);
		dlg.message = "Directory is:\n";
		dlg.message += dirFs.nativePath + "\n\n";
		dlg.message += "Created on: " + dirFs.creationDate.toLocaleString() + "\n";
		dlg.message += "Modified on: " + dirFs.modificationDate.toLocaleString() + "\n\n";
		dlg.message += "Total number of Subdirectories: " + infoDirCount_.toString() + "\n";
		dlg.message += "Total number of files: " + infoFileCount_.toString() + "\n";
		dlg.message += "Total size: " + getSizeStr (infoFileSize_) + "\n";
		dlg.open();
	}
}

private function getInfo (dirFs:File):void
{
	try {
		var files:Array = dirFs.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			if (f.isDirectory) {
				infoDirCount_++;
				getInfo (f);
			}
			else {
				infoFileCount_++;
				infoFileSize_ += f.size;
			}
		}
	}
	catch (error:Error) {
	}
}

public function onAfterTextEdit():void
{
	fs_importFiles.refresh();
	OnFileChoose();
}

public function setFindStrings (str:Array):void
{
	if (prefs_ != null) {
		prefs_.setFindStrings(str);
	}
}

public function setReplaceStrings (str:Array):void
{
	if (prefs_ != null) {
		prefs_.setReplaceStrings(str);
	}
}

public function getFindStrings():Array
{
	if (prefs_ != null) {
		return prefs_.getFindStrings();
	}
	return null;
}

public function getReplaceStrings():Array
{
	if (prefs_ != null) {
		return prefs_.getReplaceStrings();
	}
	return null;
}

public function setFindBinStrings (str:Array):void
{
	if (prefs_ != null) {
		prefs_.setFindBinStrings(str);
	}
}

public function setReplaceBinStrings (str:Array):void
{
	if (prefs_ != null) {
		prefs_.setReplaceBinStrings(str);
	}
}

public function getFindBinStrings():Array
{
	if (prefs_ != null) {
		return prefs_.getFindBinStrings();
	}
	return null;
}

public function getReplaceBinStrings():Array
{
	if (prefs_ != null) {
		return prefs_.getReplaceBinStrings();
	}
	return null;
}


//=======================================================
/*
\history

WGo-2009-04-09: Created
WGo-2014-12-09: File info, image info, full file view on demand (default is to show 100k)
WGo-2014-12-11: text field has property editable, but only copying is enabled, UI dimension is saved
WGo-2014-12-15: current path is saved, buttons for home path + custom path added
WGo-2014-12-18: Exif info completed
WGo-2015-01-09: File actions New, Delete, Duplicate
WGo-2015-01-09-2: ChangeFileName + ChangeFileExtension
WGo-2015-01-13: Play mp3 with info
WGo-2015-02-04: forward + backward with wave
WGo-2015-02-25: dir info
WGo-2015-02-26: createFolder()
WGo-2015-03-04: Exif info extended
WGo-2015-03-17: ShowBinaryContent() char 0x7f must be shown as '.'
WGo-2015-04-10: Copy + Move
WGo-2015-04-13: Copy + Move tested
WGo-2015-11-03: RemoveDSStoreFiles on key Z

*/

