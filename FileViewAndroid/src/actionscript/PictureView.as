import flash.display.Bitmap;
import flash.events.Event;
import flash.events.GestureEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.events.TouchEvent;
import flash.events.TransformGestureEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Timer;

import mx.events.FlexEvent;
import mx.graphics.BitmapFillMode;

import spark.components.Group;
import spark.events.IndexChangeEvent;

import actionscript.Utilities;

import views.LongPressConfirmDialog;



private var cur_ix_:int = 0;
private var curDirectory_:File = null;
private var curFile_:File = null;
private var filelist_:Array = null;
private var wasDoubleClick_:Boolean = false;
private var clickCount_:int = 0;
private var orientLandscape_:Boolean = false;
private var isExifPortrait_:Boolean = false;
private var lastevent_:MouseEvent = null;

private var loader_:Loader = null;
private var zoomLevel_:int = 0; // 0 = fit, 1 = 1,5, 2 = 2, 3 = max
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
private var mouseDownTimerActive_:Boolean = false;
private var mouseDownTimerValid_:Boolean = false;
private var mouseX_:Number = 0;
private var mouseY_:Number = 0;

//=======================================================

protected function OnViewComplete (event:FlexEvent):void
{
	//img.addEventListener(TransformGestureEvent.GESTURE_PAN, onPanning);
	//img.addEventListener (TouchEvent.TOUCH_MOVE, onTouchMove); // no touch events at all
	img.addEventListener (MouseEvent.CLICK, onMouseClick);
	img.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	img.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	//img.addEventListener (MouseEvent.DOUBLE_CLICK, onDoubleClick); // must be enabled
	img.fillMode = BitmapFillMode.CLIP;

	if (this.data != null && this.data.kSrcSelection != null) {
		var f:File = new File (data.kSrcSelection);
		curFile_ = f;
		curDirectory_ = f.parent;
		filelist_ = getFileListing (curDirectory_);
		cur_ix_ = getIndex (f.name);
		var fstr:FileStream = new FileStream();
		fstr.open (f, FileMode.READ);
		isExifPortrait_ = getExifIsPortrait (fstr, f.size);
		fstr.close();
		
		var urlstr:String = "file://";
		urlstr += data.kSrcSelection;
		
		loadfile_ = urlstr;
		var req:URLRequest = new URLRequest (urlstr);
		loader_ = new Loader();
		loader_.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadDataComplete);
		loader_.load(req);

		
		//img.source = urlstr;
		//img.addEventListener(Event.COMPLETE, onLoadComplete);
	}
}

private function onLoadComplete (event:Event):void
{
	//st_imginfo.text = "Image: " + img.sourceWidth.toString() + " x " + img.sourceHeight.toString();
	//var w:int = img.sourceWidth;
	//var h:int = img.sourceHeight;
	//if (w > h) {
	//	orientLandscape_ = true;
	//	img.rotation = 90;
	//}
	//else {
	//	orientLandscape_ = false;
	//}
}

private function onLoadDataComplete (event:Event):void
{
	var image:Bitmap = Bitmap(loader_.content);
	//image.smoothing = true;
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	zoomLevel_ = 0;
	centerX_ = image_w / 2;
	centerY_ = image_h / 2;
	img.rotation = 0;
	
	shownImage_ = new Bitmap();
	var bdata:BitmapData = new BitmapData (image_w, image_h, false);
	bdata.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	shownImage_.bitmapData = bdata;
	shownImage_.smoothing = true;
	// img.imageDisplay.displayObject : Group, w, h = 0

	Utilities.logDebug("onLoadDataComplete, img control size: " + int (this.width).toString() + " x " + int (this.height).toString());

	if (isExifPortrait_) {
		orientLandscape_ = true; // w > h in this case
		img.rotation = 270;
	}
	else if (image_w > image_h) {
		orientLandscape_ = true;
		img.rotation = 90;
	}
	else {
		orientLandscape_ = false;
	}

	var sx:Number = this.width / image_w; 
	var sy:Number = this.height / image_h;
	if (orientLandscape_) {
		sx = this.width / image_h;
		sy = this.height / image_w;
	}
	if (sx < sy) {
		img.scaleX = sx; 
		img.scaleY = sx; 
	}
	else {
		img.scaleX = sy; 
		img.scaleY = sy; 
	}
	if (img.scaleX < 1) {
		defScale_ = img.scaleX;
	}
	else {
		defScale_ = 0;
	}
	Utilities.logDebug("onLoadDataComplete, scaling: " + defScale_.toString());
	
	img.source = shownImage_;
}

private function zoom (into:Boolean):void
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
	img.source = null;
	//img.initialize();
	var image:Bitmap = Bitmap(loader_.content);
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	shownImage_.bitmapData.dispose();
	var newimg:BitmapData = new BitmapData (image_w, image_h, false);
	newimg.copyPixels (image.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
	shownImage_.bitmapData = newimg;
	shownImage_.smoothing = true;
	panUpValues_ = new Array();
	panLeftValues_ = new Array();
	panDownValues_ = new Array();
	panRightValues_ = new Array();
	
	var newScale:Number = defScale_;
	
	var ctrlW:Number = this.width;
	var ctrlH:Number = this.height;
	if (orientLandscape_) {
		ctrlW = this.height;
		ctrlH = this.width;
	}

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
		zoomLevel_ = 0;
	}
	Utilities.logDebug("zoom(), scaling is: " + newScale.toString());
	img.scaleX = newScale; 
	img.scaleY = newScale;
	totalScrollX_ = 0;
	totalScrollY_ = 0;
	if (image_w * newScale > ctrlW) {
		totalScrollX_ = (image_w - ctrlW / newScale) / 2 + centerX_ - image_w / 2;
		if (totalScrollX_ > image_w - ctrlW / newScale) {
			totalScrollX_ = image_w - ctrlW / newScale;
		}
	}
	if (image_h * newScale > ctrlH) {
		totalScrollY_ = (image_h - ctrlH / newScale) / 2 + centerY_ - image_h / 2;
		if (totalScrollY_ > image_h - ctrlH / newScale) {
			totalScrollY_ = image_h - ctrlH / newScale;
		}
	}
	centerX_ = ctrlW / (2 * newScale)  + totalScrollX_;
	centerY_ = ctrlH / (2 * newScale) + totalScrollY_;
	panLeftValues_.push (totalScrollX_);
	panRightValues_.push (totalScrollX_);
	panUpValues_.push (totalScrollY_);
	panDownValues_.push (totalScrollY_);
	
	img.source = shownImage_;
	shownImage_.bitmapData.scroll (totalScrollX_ * -1, totalScrollY_ * -1);
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
	var ctrlW:Number = this.width;
	var ctrlH:Number = this.height;
	var image:Bitmap = Bitmap(loader_.content);
	var imgW:Number = image.bitmapData.width;
	var imgH:Number = image.bitmapData.height;
	if (orientLandscape_) {
		ctrlW = this.height;
		ctrlH = this.width;
	}
	shownImage_.bitmapData.copyPixels (image.bitmapData, new Rectangle (0, 0, imgW, imgH), new Point());
	var curScale:Number = img.scaleX;
	var scrol_x:Number = 0;
	var scrol_y:Number = 0;
	if ((direction == 2 || direction == 4) && imgW * curScale > ctrlW) {
		if (direction == 2) { //right
			if (panLeftValues_.length > 1) { // go back
				panLeftValues_.pop();
				totalScrollX_ = panLeftValues_[panLeftValues_.length-1];
			}
			else {
				scrol_x = ctrlW / (4 * curScale);
				if (totalScrollX_ + scrol_x > imgW - ctrlW / curScale) {
					scrol_x = imgW - ctrlW / curScale - totalScrollX_;
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
				scrol_x = 0 - ctrlW / (4 * curScale);
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
	if ((direction == 1 || direction == 3) && imgH * curScale > ctrlH) {
		if (direction == 1) { // up
			if (panDownValues_.length > 1) { // go back
				panDownValues_.pop();
				totalScrollY_ = panDownValues_[panDownValues_.length-1];
			}
			else {
				scrol_y = 0 - ctrlH / (4 * curScale);
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
				scrol_y = ctrlH / (4 * curScale);
				if (totalScrollY_ + scrol_y > imgH - ctrlH / curScale) {
					scrol_y = imgH - ctrlH / curScale - totalScrollY_;
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
	centerX_ = ctrlW / (2 * curScale)  + totalScrollX_;
	centerY_ = ctrlH / (2 * curScale) + totalScrollY_;
	
	shownImage_.bitmapData.scroll (totalScrollX_ * -1, totalScrollY_ * -1);
}



protected function onMouseClick (event:MouseEvent):void
{
	lastevent_ = event;
	//Utilities.logDebug("PictureView:onMouseClick");
	clickCount_++;
	if (clickCount_ < 2) {
		var tm:Timer = new Timer (500, 1);
		tm.addEventListener(TimerEvent.TIMER, onMouseClickTimer);
		tm.start();
	}
	var group:Group = event.target as Group;
	if (group == null) {
		return;
	}
	var w:Number = group.width;
	var h:Number = group.height;
	Utilities.logDebug("container size: " + int (w).toString() + " x " + int (h).toString());
	//var ox:Number = event.stageX; // 800 x 1200
	var ox:Number = event.localX; // ca. 4000 x 6200 event.target (spark.components.Group) .height width
	//var oy:Number = event.stageY;
	var oy:Number = event.localY;
	if ((ox > w / 3 && ox < w * 2 / 3) && (oy > h / 3 && oy < h * 2 / 3)) {
		return;
	}
	clickCount_ = 0;
	if (zoomLevel_ == 0) {
		var forw:Boolean = true;
		if (isExifPortrait_) {
			forw = oy > h / 2;
		}
		else {
			forw = ox > w / 2;
		}
		onNextImage (forw);
		return;
	}
	
	if (ox < w / 3) {
		pan (4);
	}
	else if (ox > w * 2 /3) {
		pan (2);
	}
	else if (oy < h / 3) {
		pan (1);
	}
	else if (oy > h * 2 /3) {
		pan (3);
	}
	
}

protected function onDoubleClick (event:MouseEvent):void
{
	wasDoubleClick_ = true;
	
	Utilities.logDebug("PictureView:onDoubleClick");
	var group:Group = event.target as Group;
	if (group == null) {
		return;
	}
	var w:Number = group.width;
	var h:Number = group.height;
	var ox:Number = event.localX; // ca. 4000 x 6200 event.target (spark.components.Group) .height width
	var oy:Number = event.localY;
	if ((ox > w / 3 && ox < w * 2 / 3) && (oy > h / 3 && oy < h * 2 / 3)) {
		zoom (true);
	}

}

private function onMouseClickTimer (event:TimerEvent):void
{
	if (clickCount_ > 1) {
		clickCount_ = 0;
		onDoubleClick (lastevent_);
		return;
	}
	clickCount_ = 0;
	//Utilities.logDebug("PictureView:onMouseClickTimer");

	var group:Group = lastevent_.target as Group;
	if (group == null) {
		return;
	}
	var w:Number = group.width;
	var h:Number = group.height;
	var ox:Number = lastevent_.localX;
	var oy:Number = lastevent_.localY;
	if ((ox > w / 3 && ox < w * 2 / 3) && (oy > h / 3 && oy < h * 2 / 3)) {
		zoom (false);
	}
}

protected function onMouseDown (event:MouseEvent):void
{
	//Utilities.logDebug("PictureView:onMouseDown");
	if (mouseDownTimerActive_) {
		mouseDownTimerValid_ = false;
	}
	else {
		var group:Group = event.target as Group;
		if (group == null) {
			return;
		}
		var w:Number = group.width;
		var h:Number = group.height;
		var ox:Number = event.localX;
		var oy:Number = event.localY;
		if ((ox > w / 3 && ox < w * 2 / 3) && (oy > h / 3 && oy < h * 2 / 3)) {
			mouseDownTimerValid_ = true;
			mouseDownTimerActive_ = true;
			var tm:Timer = new Timer (700, 1);
			tm.addEventListener(TimerEvent.TIMER, onMouseDownTimer);
			tm.start();
		}
	}
}

protected function onMouseUp (event:MouseEvent):void
{
	if (mouseDownTimerActive_) {
		mouseDownTimerValid_ = false;
	}
}

private function onMouseDownTimer (event:TimerEvent):void
{
	mouseDownTimerActive_ = false;
	if (!mouseDownTimerValid_) {
		return;
	}
	mouseDownTimerValid_ = false;

	//Utilities.logDebug("PictureView:onMouseUp, longPress");
	
	if (curFile_ == null) {
		return;
	}
	var dlg:PictInfoDialog = new PictInfoDialog();
	var full_len:Number = curFile_.size;
	var dt:Date = curFile_.modificationDate;
	var fstr:FileStream = new FileStream();
	fstr.open (curFile_, FileMode.READ);
	
	dlg.message = "File: " + curFile_.name + "\n";
	dlg.message += getSizeStr (full_len) + " bytes\n";
	dlg.message += "File date: " + dt.toLocaleString() + "\n";
	dlg.message += "Image size: " + img.sourceWidth.toString() + " x " + img.sourceHeight.toString() + "\n\n";
	dlg.message += "Image File Info\n\n";
	dlg.message += getExifInfo (fstr, full_len);
	dlg.rotation = img.rotation;
	dlg.open (this, true);
}

private function onNextImage (forward:Boolean):void
{
	var msg1:String = "END (" + (cur_ix_ + 1).toString() + ")";
	var msg2:String = "";
	var isNext:Boolean = false;
	var ixStr:String = "";
	if (forward && cur_ix_ < filelist_.length -1) {
		cur_ix_++;
		ixStr = (cur_ix_ + 1).toString() + "/" + filelist_.length.toString();
		if (cur_ix_ == filelist_.length -1) {
			msg1 = "Next (" + ixStr + ")   >||";
		}
		else {
			msg1 = "Next (" + ixStr + ")   >>";
		}
		isNext = true;
	}
	else if (!forward && cur_ix_ > 0) {
		cur_ix_--;
		ixStr = (cur_ix_ + 1).toString() + "/" + filelist_.length.toString();
		if (cur_ix_ == 0) {
			msg1 = "Back (" + ixStr + ")   ||<";
		}
		else {
			msg1 = "Back (" + ixStr + ")   <<";
		}
		isNext = true;
	}
	else if (!forward && cur_ix_ == 0) {
		msg1 = "BEGIN";
	}
	
	if (isNext) {
		var f:File = curDirectory_.resolvePath (filelist_[cur_ix_]);
		curFile_ = f;
		var urlstr:String = "file://";
		urlstr += f.nativePath;
		var fstr:FileStream = new FileStream();
		fstr.open (f, FileMode.READ);
		isExifPortrait_ = getExifIsPortrait (fstr, f.size);
		fstr.close();
		
		data.kSrcSelection = f.nativePath;
		data.kDirectory = curDirectory_.nativePath;
		
		var req:URLRequest = new URLRequest (urlstr);
		loader_ = new Loader();
		loader_.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadDataComplete);
		loader_.load(req);
		//img.source = urlstr;
		msg2 = "\n" + f.name;
	}
	var dlg:PictViewStatusMessage = new PictViewStatusMessage();
	dlg.message = msg1 + msg2;
	dlg.open (this);
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

private function getExifInfo (fs:FileStream, len:int):String
{
	var retstr:String = "";
	var record:Array = new Array();
	var idstr:String = "";
	var bt14:uint = 0;
	var bt_1:uint = 0; 
	var littleEnd:Boolean = false;
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
	var makestr:String = "";
	var modelstr:String = "";
	var orientstr:String = "";
	var datestr:String = "";
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
				littleEnd = false;
			}
			else if (bt14 > 0 && bt == 0) {
				littleEnd = true;
			}
			else {
				return "";
			}
			if (idstr != "Exif") {
				return "";
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
	makestr = "Make: ";
	if (getExifValueFromString (record, make_id, entry, littleEnd)) {
		makestr += entry.kStr;
	}
	modelstr = "Model: ";
	if (getExifValueFromString (record, model_id, entry, littleEnd)) {
		modelstr += entry.kStr;
	}
	lensmakestr = "Lens Make: ";
	if (getExifValueFromString (record, lensmake_id, entry, littleEnd)) {
		lensmakestr += entry.kStr;
	}
	lensmodelstr = "Lens Model: ";
	if (getExifValueFromString (record, lensmodel_id, entry, littleEnd)) {
		lensmodelstr += entry.kStr;
	}
	datestr = "Date: ";
	if (getExifValueFromString (record, date_id, entry, littleEnd)) {
		datestr += entry.kStr;
	}
	orientstr = "Orientation: ";
	if (getExifValueFromShort (record, orient_id, entry, littleEnd)) {
		if (entry.kInt > 0 && entry.kInt < 5) {
			orientstr += " landscape";
		}
		else if (entry.kInt > 4 && entry.kInt < 9) {
			orientstr += " portrait";
		}
	}
	sensstr = "Sensitivity: ";
	if (getExifValueFromLong (record, iso_id, entry, littleEnd)) {
		sensstr += entry.kStr;
	}
	else if (getExifValueFromShort (record, sens_id, entry, littleEnd)) {
		sensstr += entry.kStr;
	}
	expostr = "Exposure time: ";
	if (getExifValueFromRational (record, exposure_id, entry, littleEnd)) {
		expostr += entry.kStr;
	}
	fnumstr = "F Number: ";
	if (getExifValueFromRational (record, fnum_id, entry, littleEnd)) {
		fnumstr += entry.kStr3;
	}
	focalstr = "Focal length: ";
	if (getExifValueFromRational (record, focal_id, entry, littleEnd)) {
		focalstr += entry.kStr2;
	}
	if (getExifValueFromShort (record, focal35_id, entry, littleEnd)) {
		focalstr += " (equ " + entry.kStr + ")";
	}
	programstr = "Program: ";
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
		flashstr = "Flash used: ";
		if (entry.kInt % 2 > 0) { // bit 0 is set
			flashstr += "Yes";
		}
		else {
			flashstr += "No";
		}
	}
	
	meteringstr = "Metering mode: ";
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
	whitebalstr = "White balance: ";
	if (getExifValueFromShort (record, whitebal_id, entry, littleEnd)) {
		if (entry.kInt == 0) {
			whitebalstr += "auto";
		}
		else if (entry.kInt == 1) {
			whitebalstr += "manual";
		}
	}
	biasstr = "Exposure bias: ";
	if (getExifValueFromRational (record, bias_id, entry, littleEnd)) {
		biasstr += entry.kStr4;
	}
	cspacestr = "Color space: ";
	if (getExifValueFromShort (record, cspace_id, entry, littleEnd)) {
		if (entry.kInt == 1) {
			cspacestr += "sRGB";
		}
		else {
			cspacestr += "uncalibrated";
		}
	}
	expomodestr = "Exposure mode: ";
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
	lightsourcestr = "Light source: ";
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
	retstr = makestr + "\n" + modelstr + "\n" + lensmakestr + "\n" + lensmodelstr + "\n" + datestr + "\n" + sensstr + "\n"
		+ expostr + "\n" + fnumstr + "\n" + focalstr + "\n" + orientstr + "\n" + programstr + "\n" + flashstr + "\n"
		+ meteringstr + "\n" + whitebalstr + "\n" + biasstr + "\n"+ cspacestr + "\n" + expomodestr + "\n" + lightsourcestr;
	return retstr;
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
				if (len < 100) {
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

//=======================================================
/*
\history

WGo-2015-02-10: Created

*/

