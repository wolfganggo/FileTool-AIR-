import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Point;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.AIREvent;
import mx.events.CloseEvent;
import mx.events.FlexNativeWindowBoundsEvent;

import spark.primitives.Rect;


private var imagePath_:String = "";
private var imageName_:String = "";
private var cust_w_:int = 900;
private var cust_h_:int = 600;
private var saveNewSize_:Boolean = true;

private var cur_ix_:int = 0;
private var curDirectory_:File = null;
private var filelist_:Array = null;

private var loader_:Loader = null;
private var zoomLevel_:int = 0; // 0 = fit; 1 = 1.4; 2 = 2; 3 = max
private var defScale_:Number = 0; // 0 = no scaling possible
private var scale1_:Number = 0;
private var scale2_:Number = 0;
private var centerX_:Number = 0;
private var centerY_:Number = 0;
private var totalScrollX_:Number = 0;
private var totalScrollY_:Number = 0;
private var loadfile_:String = "";
private var shownImage_:Bitmap = null; 
private var panUpValues_:Array = null;
private var panLeftValues_:Array = null;
private var panDownValues_:Array = null;
private var panRightValues_:Array = null;
private var kScrollMax:Number = 1000000;
private var offsetX_:int = 0;
private var offsetY_:int = 0;
private var isExifPortrait_:Boolean = false;
private var actualImgW_:int = 0;
private var actualImgH_:int = 0;


private function OnWindowComplete():void
{
	this.nativeWindow.x = 50;
	this.nativeWindow.y = 0;
	//this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	img.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	
	img.setFocus();
}

public function showImage (path:String):void
{
	var f:File = new File (path);
	curDirectory_ = f.parent;
	filelist_ = getFileListing (curDirectory_);
	cur_ix_ = getIndex (f.name);
	var fstr:FileStream = new FileStream();
	fstr.open (f, FileMode.READ);
	isExifPortrait_ = getExifIsPortrait (fstr, f.size);

	imagePath_ = path;
	imageName_ = f.name;
	var ixStr:String = "END";
	if (cur_ix_ < filelist_.length -1) {
		ixStr = (cur_ix_ + 1).toString() + "/" + filelist_.length.toString();
	}
	this.title = imageName_  + "   [" + ixStr + "] [zoom " + zoomLevel_.toString() + "]";

	var urlstr:String = "file://";
	urlstr += path;
	loadfile_ = urlstr;
	var req:URLRequest = new URLRequest (urlstr);
	var ldr:Loader = new Loader();
	ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
	ldr.load(req);
}

private function OnLoadComplete (event:Event):void
{
	loader_ = Loader(event.target.loader);
	var image:Bitmap = Bitmap(loader_.content);
	image.smoothing = true;
	//image.cacheAsBitmap = true;
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	zoomLevel_ = 0;
	totalScrollX_ = 0;
	totalScrollY_ = 0;
	offsetX_ = 0;
	offsetY_ = 0;
	actualImgW_ = image_w;
	actualImgH_ = image_h;
	saveNewSize_ = true;
	if (isExifPortrait_) {
		actualImgW_ = image_h;
		actualImgH_ = image_w;
		img.rotation = 270;
		saveNewSize_ = false;
	}
	else {
		img.rotation = 0;
	}
	centerX_ = actualImgW_ / 2;
	centerY_ = actualImgH_ / 2;

	shownImage_ = new Bitmap();
	var bdata:BitmapData = new BitmapData (image_w, image_h, false);
	bdata.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	shownImage_.bitmapData = bdata;
	shownImage_.smoothing = true;

	if (actualImgW_ > cust_w_ || actualImgH_ > cust_h_) {
		this.width = cust_w_;
		this.height = cust_h_;
		var sx:Number = cust_w_ / actualImgW_;
		var sy:Number = cust_h_ / actualImgH_;
		if (sx < sy) {
			img.scaleX = sx;
			img.scaleY = sx;
			offsetY_ = (cust_h_ - actualImgH_ * sx) / 2;
		}
		else {
			img.scaleX = sy; 
			img.scaleY = sy; 
			offsetX_ = (cust_w_ - actualImgW_ * sy) / 2;
		}
		defScale_ = img.scaleX;
	}
	else {
		saveNewSize_ = false;
		this.width = actualImgW_;
		this.height = actualImgH_;
		defScale_ = 0;
	}
	if (isExifPortrait_) {
		totalScrollY_ = cust_h_;
		offsetY_ += cust_h_;
	}	
	var context:LoaderContext = new LoaderContext();
	img.loaderContext = context;
	img.x = offsetX_;
	img.y = offsetY_;
	//img.y = 1000; // nearly good

	img.source = shownImage_;
}

private function zoom (into:Boolean, newLevel:int = -1):void
{
	//trace("============");
	//trace("enter zoom()");
	//trace("zoom level: " + zoomLevel_);
	
	if (loader_ == null || defScale_ == 0 || shownImage_ == null) {
		return;
	}
	var oldScale:Number = img.scaleX;
	if (into && (zoomLevel_ == 3 || oldScale >= 1)) {
		return;
	}
	if (!into && zoomLevel_ == 0) {
		return;
	}
	//img.source = null;
	var image:Bitmap = Bitmap(loader_.content);
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	actualImgW_ = image_w;
	actualImgH_ = image_h;
	if (isExifPortrait_) {
		actualImgW_ = image_h;
		actualImgH_ = image_w;
	}
	//shownImage_.bitmapData.dispose();
	//var newimg:BitmapData = new BitmapData (image_w, image_h, false);
	//newimg.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	shownImage_.bitmapData.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	//shownImage_.bitmapData = newimg;
	//shownImage_.smoothing = true;
	panUpValues_ = new Array();
	panLeftValues_ = new Array();
	panDownValues_ = new Array();
	panRightValues_ = new Array();

	var newScale:Number = defScale_;
	img.x = 0;
	img.y = 0;

	if (into) {
		zoomLevel_++;
		newScale = oldScale * 1.414;
		if (zoomLevel_ == 1) {
			if (newScale <= 1) {
				scale1_ = newScale;
			}
			else {
				scale1_ = defScale_;
			}
		}
		else if (zoomLevel_ == 2) {
			if (newScale <= 1) {
				scale2_ = newScale;
			}
			else {
				scale2_ = defScale_;
			}
		}
		if (newScale > 1 || zoomLevel_ == 3) {
			newScale = 1;
		}
	}
	else {
		zoomLevel_--;
		if (newLevel != -1) {
			zoomLevel_ = newLevel;
		}
		if (zoomLevel_ == 2) {
			newScale = scale2_;
		}
		else if (zoomLevel_ == 1) {
			newScale = scale1_;
		}
		else if (zoomLevel_ == 0) {
			img.x = offsetX_;
			img.y = offsetY_;
		}
	}
	img.scaleX = newScale; 
	img.scaleY = newScale;
	totalScrollX_ = 0;
	totalScrollY_ = 0;
	if (actualImgW_ * newScale > cust_w_) {
		totalScrollX_ = (actualImgW_ - cust_w_ / newScale) / 2 + centerX_ - actualImgW_ / 2;
		if (totalScrollX_ > actualImgW_ - cust_w_ / newScale) {
			totalScrollX_ = actualImgW_ - cust_w_ / newScale;
		}
	}
	if (actualImgH_ * newScale > cust_h_) {
		totalScrollY_ = (actualImgH_ - cust_h_ / newScale) / 2 + centerY_ - actualImgH_ / 2;
		if (totalScrollY_ > actualImgH_ - cust_h_ / newScale) {
			totalScrollY_ = actualImgH_ - cust_h_ / newScale;
		}
	}
	centerX_ = cust_w_ / (2 * newScale)  + totalScrollX_;
	centerY_ = cust_h_ / (2 * newScale) + totalScrollY_;
	panLeftValues_.push (totalScrollX_);
	panRightValues_.push (totalScrollX_);
	panUpValues_.push (totalScrollY_);
	panDownValues_.push (totalScrollY_);
	
	//img.source = shownImage_;
	shownImage_.bitmapData.scroll (totalScrollX_ * -1, totalScrollY_ * -1);

	var ixStr:String = "END";
	if (cur_ix_ < filelist_.length -1) {
		ixStr = (cur_ix_ + 1).toString() + "/" + filelist_.length.toString();
	}
	this.title = imageName_  + "   [" + ixStr + "] [zoom " + zoomLevel_.toString() + "]";
}

private function pan (direction:int):void // 1 = up (y smaller), 2 = right (x bigger), 3 = down (y bigger), 4 = left (x smaller)
{
	if (loader_ == null || defScale_ == 0 || zoomLevel_ == 0 || shownImage_ == null) {
		return;
	}
	if (direction == 2 && panRightValues_[panRightValues_.length-1] == kScrollMax) {
		return;
	}
	if (direction == 4 && panLeftValues_[panLeftValues_.length-1] == kScrollMax) {
		return;
	}
	if (direction == 1 && panUpValues_[panUpValues_.length-1] == kScrollMax) {
		return;
	}
	if (direction == 3 && panDownValues_[panDownValues_.length-1] == kScrollMax) {
		return;
	}
	var image:Bitmap = Bitmap(loader_.content);
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	var actualImgW:int = image_w;
	var actualImgH:int = image_h;
	if (isExifPortrait_) {
		actualImgW = image_h;
		actualImgH = image_w;
	}
	
	//img.source = null;
	//shownImage_.bitmapData.dispose();
	//var newimg:BitmapData = new BitmapData (image_w, image_h, false);
	//newimg.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	shownImage_.bitmapData.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	//shownImage_.bitmapData = newimg;
	//shownImage_.smoothing = true;

	var curScale:Number = img.scaleX;
	var scrol_x:Number = 0;
	var scrol_y:Number = 0;
	if ((direction == 2 || direction == 4) && actualImgW * curScale > cust_w_) {
		if (direction == 2) { //right
			if (panLeftValues_.length > 1) { // go back
				panLeftValues_.pop();
				totalScrollX_ = panLeftValues_[panLeftValues_.length-1];
			}
			else {
				scrol_x = cust_w_ / (8 * curScale);
				if (totalScrollX_ + scrol_x > actualImgW - cust_w_ / curScale) {
					scrol_x = actualImgW - cust_w_ / curScale - totalScrollX_;
					totalScrollX_ += scrol_x;
					panRightValues_.push (kScrollMax);
				}
				else {
					totalScrollX_ += scrol_x;
					panRightValues_.push (totalScrollX_);
				}
			}
			
		}
		else { // left
			if (panRightValues_.length > 1) { // go back
				panRightValues_.pop();
				totalScrollX_ = panRightValues_[panRightValues_.length-1];
			}
			else {
				scrol_x = 0 - cust_w_ / (8 * curScale);
				if (totalScrollX_ + scrol_x <= 0) {
					totalScrollX_ = 0;
					panLeftValues_.push (kScrollMax);
				}
				else {
					totalScrollX_ += scrol_x;
					panLeftValues_.push (totalScrollX_);
				}
			}
		}
	}
	if ((direction == 1 || direction == 3) && actualImgH * curScale > cust_h_) {
		if (direction == 1) { // up
			if (panDownValues_.length > 1) { // go back
				panDownValues_.pop();
				totalScrollY_ = panDownValues_[panDownValues_.length-1];
			}
			else {
				scrol_y = 0 - cust_h_ / (8 * curScale);
				if (totalScrollY_ + scrol_y <= 0) {
					totalScrollY_ = 0;
					panUpValues_.push (kScrollMax);
				}
				else {
					totalScrollY_ += scrol_y;
					panUpValues_.push (totalScrollY_);
				}
			}
		}
		else { // down
			if (panUpValues_.length > 1) { // go back
				panUpValues_.pop();
				totalScrollY_ = panUpValues_[panUpValues_.length-1];
			}
			else {
				scrol_y = cust_h_ / (8 * curScale);
				if (totalScrollY_ + scrol_y > actualImgH - cust_h_ / curScale) {
					scrol_y = actualImgH - cust_h_ / curScale - totalScrollY_;
					totalScrollY_ += scrol_y;
					panDownValues_.push (kScrollMax);
				}
				else {
					totalScrollY_ += scrol_y;
					panDownValues_.push (totalScrollY_);
				}
			}
		}
	}
	centerX_ = cust_w_ / (2 * curScale)  + totalScrollX_;
	centerY_ = cust_h_ / (2 * curScale) + totalScrollY_;

	//img.source = shownImage_;
	shownImage_.bitmapData.scroll (totalScrollX_ * -1, totalScrollY_ * -1);
}

public function setSize (w:int, h:int):void
{
	cust_w_ = w;
	cust_h_ = h;
	//this.width = w;
	//this.height = h;
}

protected function windowResizeHandler (event:FlexNativeWindowBoundsEvent):void
{
	if (saveNewSize_) {
		FlexGlobals.topLevelApplication.setImgViewParameter (this.width, this.height);
	}
}

protected function onClose(event:Event):void
{
	FlexGlobals.topLevelApplication.setSelectedFile (imageName_);
}

protected function windowDeactivateHandler(event:AIREvent):void
{
}

protected function OnKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey;
	var key:uint = event.keyCode; // 221 +
	if (key == Keyboard.SPACE || (key == Keyboard.W && isControlKey)) {
		this.close();
	}
	else if (key == Keyboard.LEFT) {
		if (zoomLevel_ > 0) {
			pan (4);
		}
		else {
			onNavigate (false);
		}
	}
	else if (key == Keyboard.RIGHT) {
		if (zoomLevel_ > 0) {
			pan (2);
		}
		else {
			onNavigate (true);
		}
	}
	else if (key == Keyboard.UP) {
		if (zoomLevel_ > 0) {
			pan (1);
		}
	}
	else if (key == Keyboard.DOWN) {
		if (zoomLevel_ > 0) {
			pan (3);
		}
	}
	else if (key == Keyboard.Z || key == 221) { // PLUS not available
		zoom (true);
	}
	else if (key == Keyboard.B || key == 191) { // MINUS (189) is wrong
		zoom (false);
	}
	else if (key == Keyboard.NUMBER_0) {
		zoom (false, 0);
	}
	else if (key == Keyboard.I) {
		showExifInfo();
	}
}

protected function onNavigate (forw:Boolean):void
{
	if (forw && cur_ix_ < filelist_.length -1) {
		cur_ix_++;
	}
	else if (!forw && cur_ix_ > 0) {
		cur_ix_--;
	}
	else {
		return;
	}
	
	var f:File = curDirectory_.resolvePath (filelist_[cur_ix_]);
	var urlstr:String = "file://";
	urlstr += f.nativePath;
	var fstr:FileStream = new FileStream();
	fstr.open (f, FileMode.READ);
	isExifPortrait_ = getExifIsPortrait (fstr, f.size);

	imagePath_ = f.nativePath;
	imageName_ = f.name;
	var ixStr:String = "END";
	if (cur_ix_ < filelist_.length -1) {
		ixStr = (cur_ix_ + 1).toString() + "/" + filelist_.length.toString();
	}
	this.title = imageName_  + "   [" + ixStr + "] [zoom " + zoomLevel_.toString() + "]";
	
	var req:URLRequest = new URLRequest (urlstr);
	var ldr:Loader = new Loader();
	ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
	ldr.load(req);
}

private function getFileListing (dir:File):Array
{
	var retval:Array = new Array();
	if (dir == null) {
		return retval;
	}
	try {
		var files:Array = dir.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			var ext:String = "";
			if (f.extension != null) {
				ext = f.extension.toLocaleUpperCase();
			}
			if (!f.isDirectory && (ext == "JPG" || ext == "JPEG" || ext == "PNG" || ext == "GIF")) {
				retval.push (f.name);
			}
		}
		retval.sort();
	}
	catch (error:Error) {
	}
	return retval;
}

private function getIndex (name:String):int
{
	for (var i1:int = 0; i1 < filelist_.length; i1++) {
		if (name == filelist_[i1]) {
			return i1;
		}
	}
	return -1;
}

private function getExifIsPortrait (fs:FileStream, len:int):Boolean
{
	var isPortrait:Boolean = false;
	const orient_id:uint = 0x0112;
	var record:Array = new Array();
	var idstr:String = "";
	var bt14:uint = 0;
	var bt_1:uint = 0; 
	var littleEnd:Boolean = false;
	var firstByte:Boolean = true;
	var prestr:String = "";

	if (len > 10000) {
		len = 10000;
	}
	for (var iy:uint = 0; iy < 64; iy++) {
		var b1:uint = 0;
		b1 = fs.readUnsignedByte();
		if (b1 < 32 || b1 > 126) {
			b1 = 63;
		}
		prestr += String.fromCharCode (b1);
	}
	var found_ix:int = prestr.indexOf("Exif");
	if (found_ix < 6) {
		return false;
	}
	fs.position = found_ix - 6;

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
				littleEnd = false;
			}
			else if (bt14 > 0 && bt == 0) {
				littleEnd = true;
			}
			else {
				return false;
			}
			if (idstr != "Exif") {
				return false;
			}
		}
		if (ix > 11) {
			if (firstByte) {
				bt_1 = bt;
				firstByte = false;
			}
			else {
				if (littleEnd) {
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
	entry.kInt = 0;
	if (getExifValueFromShort (record, orient_id, entry, littleEnd)) {
		if (entry.kInt > 4 && entry.kInt < 9) {
			isPortrait = true;
		}
	}
	return isPortrait;
}

private function showExifInfo():void
{
	var f:File = new File (imagePath_);
	var fs:FileStream = new FileStream();
	fs.open (f, FileMode.READ);
	var len:int = f.size;

	var infostr:String = "Folder:   " + curDirectory_.nativePath;
	infostr += "\n\nFile:   " + imageName_;
	infostr += "\nFile size:   " + getSizeStr (len);
	infostr += "\nImage dimension:   " + actualImgW_.toString() + " x " + actualImgH_.toString() + "\n\n";
	var record:Array = new Array();
	var idstr:String = "";
	var bt14:uint = 0;
	var bt_1:uint = 0; 
	var littleEnd:Boolean = false;
	var firstByte:Boolean = true;
	const make_id:uint = 0x010f;
	const model_id:uint = 0x0110;
	const orient_id:uint = 0x0112;
	const version_id:uint = 0x0131; // creator
	//const date_id:uint = 0x0132;
	const moddate_id:uint = 0x0132;  // used by PhotoShop
	const date_id:uint = 0x9003;
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
	const lensmodel2_id:uint = 0x0051;  // private from Panasonic (GH1), length can be shorter
	const metering_id:uint = 0x9207;
	const whitebal_id:uint = 0xA403;
	const bias_id:uint = 0x9204;
	const cspace_id:uint = 0xA001;
	const expomode_id:uint = 0xA402;
	const lightsource_id:uint = 0x9208;
	var makestr:String = "";
	var modelstr:String = "";
	var orientstr:String = "";
	var creatorstr:String = "";
	var datestr:String = "";
	var moddatestr:String = "";
	var expostr:String = "";
	var fnumstr:String = "";
	var sensstr:String = "";
	var flashstr:String = "";
	var focalstr:String = "";
	var programstr:String = "";
	var lensmodelstr:String = "";
	var lensmakestr:String = "";
	
	var meteringstr:String = "";
	var whitebalstr:String = "";
	var biasstr:String = "";
	var cspacestr:String = "";
	var expomodestr:String = "";
	var lightsourcestr:String = "";

	var prestr:String = "";
	
	if (len > 20000) {
		len = 20000;
	}
	for (var iy:uint = 0; iy < 64; iy++) {
		var b1:uint = 0;
		b1 = fs.readUnsignedByte();
		if (b1 < 32 || b1 > 126) {
			b1 = 63;
		}
		prestr += String.fromCharCode (b1);
	}
	var found_ix:int = prestr.indexOf("Exif");
	if (found_ix < 6) {
		return;
	}
	fs.position = found_ix - 6;

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
				littleEnd = false;
			}
			else if (bt14 > 0 && bt == 0) {
				littleEnd = true;
			}
			else {
				return;
			}
			if (idstr != "Exif") {
				return;
			}
		}
		if (ix > 11) {
			if (firstByte) {
				bt_1 = bt;
				firstByte = false;
			}
			else {
				if (littleEnd) {
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
	entry.kInt = 0;
	makestr = "Make:   ";
	if (getExifValueFromString (record, make_id, entry, littleEnd)) {
		makestr += entry.kStr;
	}
	modelstr = "Model:   ";
	if (getExifValueFromString (record, model_id, entry, littleEnd)) {
		modelstr += entry.kStr;
	}
	lensmakestr = "Lens Make:   ";
	if (getExifValueFromString (record, lensmake_id, entry, littleEnd)) {
		lensmakestr += entry.kStr;
	}
	lensmodelstr = "Lens Model:   ";
	if (getExifValueFromString (record, lensmodel_id, entry, littleEnd)) {
		lensmodelstr += entry.kStr;
	}
	else if (getExifValueFromString (record, lensmodel2_id, entry, littleEnd)) {
		lensmodelstr += entry.kStr;
	}
	creatorstr = "Creator:   ";
	if (getExifValueFromString (record, version_id, entry, littleEnd)) {
		creatorstr += entry.kStr;
	}
	datestr = "Date:   ";
	if (getExifValueFromString (record, date_id, entry, littleEnd)) {
		datestr += entry.kStr;
	}
	moddatestr = "Date modified:   ";
	if (getExifValueFromString (record, moddate_id, entry, littleEnd)) {
		moddatestr += entry.kStr;
	}
	orientstr = "Orientation:   ";
	if (getExifValueFromShort (record, orient_id, entry, littleEnd)) {
		if (entry.kInt > 0 && entry.kInt < 5) {
			orientstr += " landscape";
		}
		else if (entry.kInt > 4 && entry.kInt < 9) {
			orientstr += " portrait";
		}
	}
	sensstr = "Sensitivity:   ";
	if (getExifValueFromLong (record, iso_id, entry, littleEnd)) {
		sensstr += entry.kStr;
	}
	else if (getExifValueFromShort (record, sens_id, entry, littleEnd)) {
		sensstr += entry.kStr;
	}
	expostr = "Exposure time:   ";
	if (getExifValueFromRational (record, exposure_id, entry, littleEnd)) {
		expostr += entry.kStr;
	}
	fnumstr = "F Number:   ";
	if (getExifValueFromRational (record, fnum_id, entry, littleEnd)) {
		fnumstr += entry.kStr3;
	}
	focalstr = "Focal length:   ";
	if (getExifValueFromRational (record, focal_id, entry, littleEnd)) {
		focalstr += entry.kStr2;
	}
	if (getExifValueFromShort (record, focal35_id, entry, littleEnd)) {
		focalstr += " (equ " + entry.kStr + ")";
	}
	programstr = "Program:   ";
	if (getExifValueFromShort (record, program_id, entry, littleEnd)) {
		//programstr += entry.kStr;
		if (entry.kInt == 0) {
			programstr += "undefined";
		}
		else if (entry.kInt == 1) {
			programstr += "manual";
		}
		else if (entry.kInt == 2) {
			programstr += "normal";
		}
		else if (entry.kInt == 3) {
			programstr += "aperture priority";
		}
		else if (entry.kInt == 4) {
			programstr += "shutter priority";
		}
		else if (entry.kInt == 5) {
			programstr += "creative";
		}
		else if (entry.kInt == 6) {
			programstr += "action";
		}
		else if (entry.kInt == 7) {
			programstr += "portrait";
		}
		else if (entry.kInt == 8) {
			programstr += "landscape";
		}
		else if (entry.kInt > 0) {
			programstr += "other (" + entry.kStr  + ")";
		}
	}
	if (getExifValueFromShort (record, flash_id, entry, littleEnd)) {
		flashstr = "Flash used:   ";
		if (entry.kInt % 2 > 0) { // bit 0 is set
			flashstr += "Yes";
		}
		else {
			flashstr += "No";
		}
	}
	meteringstr = "Metering mode:   ";
	if (getExifValueFromShort (record, metering_id, entry, littleEnd)) {
		if (entry.kInt == 1) {
			meteringstr += "average";
		}
		else if (entry.kInt == 2) {
			meteringstr += "center weighted average";
		}
		else if (entry.kInt == 3) {
			meteringstr += "spot";
		}
		else if (entry.kInt == 4) {
			meteringstr += "multi-spot";
		}
		else if (entry.kInt == 5) {
			meteringstr += "pattern";
		}
		else if (entry.kInt == 6) {
			meteringstr += "partial";
		}
		else {
			meteringstr += "unknown";
		}
	}
	whitebalstr = "White balance:   ";
	if (getExifValueFromShort (record, whitebal_id, entry, littleEnd)) {
		if (entry.kInt == 0) {
			whitebalstr += "auto";
		}
		else if (entry.kInt == 1) {
			whitebalstr += "manual";
		}
	}
	biasstr = "Exposure bias:   ";
	if (getExifValueFromRational (record, bias_id, entry, littleEnd)) {
		biasstr += entry.kStr4;
	}
	cspacestr = "Color space:   ";
	if (getExifValueFromShort (record, cspace_id, entry, littleEnd)) {
		if (entry.kInt == 1) {
			cspacestr += "sRGB";
		}
		else {
			cspacestr += "uncalibrated";
		}
	}
	expomodestr = "Exposure mode:   ";
	if (getExifValueFromShort (record, expomode_id, entry, littleEnd)) {
		if (entry.kInt == 0) {
			expomodestr += "auto exposure";
		}
		else if (entry.kInt == 1) {
			expomodestr += "manual exposure";
		}
		else if (entry.kInt == 2) {
			expomodestr += "auto bracket";
		}
	}
	lightsourcestr = "Light source:   ";
	if (getExifValueFromShort (record, lightsource_id, entry, littleEnd)) {
		if (entry.kInt == 0) {
			lightsourcestr += "auto";
		}
		else if (entry.kInt == 1) {
			lightsourcestr += "daylight";
		}
		else if (entry.kInt == 2) {
			lightsourcestr += "fluorescent";
		}
		else if (entry.kInt == 3) {
			lightsourcestr += "tungsten";
		}
		else if (entry.kInt == 4) {
			lightsourcestr += "flash";
		}
		else if (entry.kInt == 9) {
			lightsourcestr += "fine weather";
		}
		else if (entry.kInt == 10) {
			lightsourcestr += "cloudy weather";
		}
		else if (entry.kInt == 11) {
			lightsourcestr += "shade";
		}
		else if (entry.kInt == 24) {
			lightsourcestr += "ISO studio tungsten";
		}
		else {
			lightsourcestr += "unknown light source";
		}
	}
	infostr += makestr + "\n" + modelstr + "\n" + lensmakestr + "\n" + lensmodelstr + "\n" + creatorstr + "\n"
		+ datestr + "\n" + moddatestr + "\n" + sensstr + "\n"
		+ expostr + "\n" + fnumstr + "\n" + focalstr + "\n" + orientstr + "\n" + programstr + "\n" + flashstr + "\n"
		+ meteringstr + "\n" + whitebalstr + "\n" + biasstr + "\n"+ cspacestr + "\n" + expomodestr + "\n" + lightsourcestr;

	var myAlert:Alert = Alert.show (infostr, "File Info", Alert.OK, this, InfoDlgHandler);
	myAlert.width = 400;
	myAlert.height = 500;
	
}
	
private function InfoDlgHandler (event:CloseEvent):void
{
	img.setFocus();
}

private function getExifValueFromString (arr:Array, id:uint, value:Object, littleEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 2) {
				var len:uint = 0;
				if (littleEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len < 1000) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (littleEnd) {
						offs = arr[pos + 4] + arr[pos + 5] * 65536;
					}
					else {
						offs = arr[pos + 4] * 65536 + arr[pos + 5];
					}
					for (var ix:int = offs / 2; ix < arlen; ix++) {
						if (littleEnd) {
							var val1:uint = arr[ix] % 256;
							if (val1 == 0) { // Panasonic lens entry can have wrong length
								break;
							}
							value.kStr += String.fromCharCode (val1); // second byte at first
							var val2:uint = arr[ix] / 256;
							if (val2 == 0) {
								break;
							}
							value.kStr += String.fromCharCode (val2);
						}
						else {
							var val3:uint = arr[ix] / 256;
							if (val3 == 0) {
								break;
							}
							value.kStr += String.fromCharCode (val3);
							var val4:uint = arr[ix] % 256;
							if (val4 == 0) {
								break;
							}
							value.kStr += String.fromCharCode (val4);
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

private function getExifValueFromShort (arr:Array, id:uint, value:Object, littleEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 3) {
				var len:uint = 0;
				if (littleEnd) {
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

private function getExifValueFromLong (arr:Array, id:uint, value:Object, littleEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 4 || arr[pos + 1] == 9) {
				var len:uint = 0;
				if (littleEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					if (littleEnd) {
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

private function getExifValueFromRational (arr:Array, id:uint, value:Object, littleEnd:Boolean):Boolean
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
				if (littleEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (littleEnd) {
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
						if (littleEnd) {
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
						if (littleEnd) {
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

protected function getSizeStr (len:int):String
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
//=======================================================
/*
\history

WGo-2014-12-15: created
WGo-2015-02-19: zoom + pan works
WGo-2015-02-20: title with name, index, zoom
WGo-2015-03-05: Images with meta data 'Portrait' rotated, but zoom does not work
WGo-2016-01-05: Find Exif data also in JFIF file
WGo-2016-09-14: date id changed to original
WGo-2016-09-28: read Panasonic lens, string entries need more tolerance for length

*/

