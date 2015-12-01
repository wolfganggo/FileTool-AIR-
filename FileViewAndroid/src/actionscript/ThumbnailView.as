import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.Timer;

import mx.events.FlexEvent;
import mx.graphics.BitmapFillMode;

import spark.components.Group;
import spark.events.IndexChangeEvent;
import spark.events.ViewNavigatorEvent;

import actionscript.ThumbnailCache;
import actionscript.Utilities;



private var cur_ix_:int = 0;
private var curPage_:int = 0;
private var curDirectory_:File = null;
private var curFile_:File = null;
private var filelist_:Array = null;
//public var fileSpecList_:Array = null;
public var bitmaplist_:Array = null;

private var loader_:Loader = null;
//private var loadfile_:String = "";
private var shownImage_:Bitmap = null; 
private var mouseX_:Number = 0;
private var mouseY_:Number = 0;
private var foundInCache_:Boolean = false;
private var cacheModified_:Boolean = false;
private var cache_:ThumbnailCache = null;
private var showImgOnReturn_:Boolean = false;
private var ixinval:int = -1;


//=======================================================

protected function OnViewComplete (event:FlexEvent):void
{
	this.addEventListener (MouseEvent.CLICK, onMouseClick);

	if (this.data != null && this.data.kSrcSelection != null) {
		var f:File = new File (data.kSrcSelection);
		curDirectory_ = f.parent;
		if (curDirectory_ == null) {
			return;
		}
		filelist_ = getFileListing (curDirectory_);
		if (filelist_.length == 0) {
			return;
		}
		cur_ix_ = 0;
		if (data.kPageIndex > -1) {
			curPage_ = data.kPageIndex;
			cur_ix_ = curPage_ * 52;
		}
		
		var endIx:int = cur_ix_ + 52;
		if (endIx > filelist_.length) {
			endIx = filelist_.length;
		}
		st_info.text = "      " + filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + endIx.toString()
			+ ")        " + curDirectory_.name;
		
		cache_ = new ThumbnailCache();
		bitmaplist_ = cache_.readThumbnails (curDirectory_.nativePath, curDirectory_.name, filelist_);
		if (bitmaplist_ != null && bitmaplist_.length > 0) {
			loadThumbnails();
			return;
		}
		cache_.removeThumbnails(); // if read has found files, but failed
		cache_.startThumbnails (curDirectory_.nativePath, curDirectory_.name);
		curFile_ = curDirectory_.resolvePath (filelist_[0]);
		var urlstr:String = "file://";
		urlstr += curFile_.nativePath;
		bitmaplist_ = new Array();
		
		var req:URLRequest = new URLRequest (urlstr);
		loader_ = new Loader();
		loader_.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
		loader_.load(req);
	}
}

protected function onViewRemoving(event:ViewNavigatorEvent):void
{
	if (!showImgOnReturn_) {
		data.kSrcSelection = "";
		data.kPageIndex = ixinval;
	}
}

private function onLoadComplete (event:Event):void
{
	cacheModified_ = true;
	var image:Bitmap = Bitmap(loader_.content);
	image.smoothing = false;
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	var scale:Number = 0;
	if (image_w > image_h) {
		//scale = 300 / image_w;
		scale = 200 / image_w;
	}
	else {
		//scale = 300 / image_h;
		scale = 200 / image_h;
	}
	var mx:Matrix = new Matrix();
	mx.scale (scale, scale);
	
	var bdata:BitmapData = new BitmapData (image_w * scale, image_h * scale, false);
	bdata.draw (image.bitmapData, mx);
	image.bitmapData.dispose(); // saves a lot of memory, up to 300 MB (debug version)
	var shownImg:Bitmap = new Bitmap (bdata);
	bitmaplist_.push (shownImg);
	cache_.saveThumbnail (shownImg, curFile_, cur_ix_);
	
	var pict_ix:int = cur_ix_ + 1 - (curPage_ * 52);
	
	if (pict_ix == 1) {
		img1.source = shownImg;
	}
	else if (pict_ix == 2) {
		img2.source = shownImg;
	}
	else if (pict_ix == 3) {
		img3.source = shownImg;
	}
	else if (pict_ix == 4) {
		img4.source = shownImg;
	}
	else if (pict_ix == 5) {
		img5.source = shownImg;
	}
	else if (pict_ix == 6) {
		img6.source = shownImg;
	}
	else if (pict_ix == 7) {
		img7.source = shownImg;
	}
	else if (pict_ix == 8) {
		img8.source = shownImg;
	}
	else if (pict_ix == 9) {
		img9.source = shownImg;
	}
	else if (pict_ix == 10) {
		img10.source = shownImg;
	}
	else if (pict_ix == 11) {
		img11.source = shownImg;
	}
	else if (pict_ix == 12) {
		img12.source = shownImg;
	}
	else if (pict_ix == 13) {
		img13.source = shownImg;
	}
	else if (pict_ix == 14) {
		img14.source = shownImg;
	}
	else if (pict_ix == 15) {
		img15.source = shownImg;
	}
	else if (pict_ix == 16) {
		img16.source = shownImg;
	}
	else if (pict_ix == 17) {
		img17.source = shownImg;
	}
	else if (pict_ix == 18) {
		img18.source = shownImg;
	}
	else if (pict_ix == 19) {
		img19.source = shownImg;
	}
	else if (pict_ix == 20) {
		img20.source = shownImg;
	}
	else if (pict_ix == 21) {
		img21.source = shownImg;
	}
	else if (pict_ix == 22) {
		img22.source = shownImg;
	}
	else if (pict_ix == 23) {
		img23.source = shownImg;
	}
	else if (pict_ix == 24) {
		img24.source = shownImg;
	}
	else if (pict_ix == 25) {
		img25.source = shownImg;
	}
	else if (pict_ix == 26) {
		img26.source = shownImg;
	}
	else if (pict_ix == 27) {
		img27.source = shownImg;
	}
	else if (pict_ix == 28) {
		img28.source = shownImg;
	}
	else if (pict_ix == 29) {
		img29.source = shownImg;
	}
	else if (pict_ix == 30) {
		img30.source = shownImg;
	}
	else if (pict_ix == 31) {
		img31.source = shownImg;
	}
	else if (pict_ix == 32) {
		img32.source = shownImg;
	}
	else if (pict_ix == 33) {
		img33.source = shownImg;
	}
	else if (pict_ix == 34) {
		img34.source = shownImg;
	}
	else if (pict_ix == 35) {
		img35.source = shownImg;
	}
	else if (pict_ix == 36) {
		img36.source = shownImg;
	}
	else if (pict_ix == 37) {
		img37.source = shownImg;
	}
	else if (pict_ix == 38) {
		img38.source = shownImg;
	}
	else if (pict_ix == 39) {
		img39.source = shownImg;
	}
	else if (pict_ix == 40) {
		img40.source = shownImg;
	}
	else if (pict_ix == 41) {
		img41.source = shownImg;
	}
	else if (pict_ix == 42) {
		img42.source = shownImg;
	}
	else if (pict_ix == 43) {
		img43.source = shownImg;
	}
	else if (pict_ix == 44) {
		img44.source = shownImg;
	}
	else if (pict_ix == 45) {
		img45.source = shownImg;
	}
	else if (pict_ix == 46) {
		img46.source = shownImg;
	}
	else if (pict_ix == 47) {
		img47.source = shownImg;
	}
	else if (pict_ix == 48) {
		img48.source = shownImg;
	}
	else if (pict_ix == 49) {
		img49.source = shownImg;
	}
	else if (pict_ix == 50) {
		img50.source = shownImg;
	}
	else if (pict_ix == 51) {
		img51.source = shownImg;
	}
	else if (pict_ix == 52) {
		img52.source = shownImg;
		if (filelist_.length > (curPage_ * 52)) {
			imgN.visible = true;
		}
		return;
	}
	
	//var bmp:BitmapImage = event.target as BitmapImage;
	//flash.display.BitmapData
	//public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:flash.geom:ColorTransform = null, blendMode:String = null, clipRect:Rectangle = null, smoothing:Boolean = false):void
	//flash.geom.Matrix
	////flash.display.Bitmap
	if (filelist_.length == cur_ix_ + 1) {
		return;
	}
	//var tm:Timer = new Timer (10, 1);
	//tm.addEventListener (TimerEvent.TIMER, onLoadCompleteTimer);
	//tm.start();

	cur_ix_++;
	curFile_ = curDirectory_.resolvePath (filelist_[cur_ix_]);
	var urlstr:String = "file://";
	urlstr += curFile_.nativePath;
	var req:URLRequest = new URLRequest (urlstr);
	loader_ = new Loader();
	loader_.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
	loader_.load(req);
}

	
private function loadThumbnails():void
{
	//var pict_ix:int = cur_ix_ + 1 - (curPage_ * 52);

	for ( ; cur_ix_ - (curPage_ * 52) < 52; cur_ix_++) {
		
		if (bitmaplist_.length <= cur_ix_) {
			break;
		}
		var pict_ix:int = cur_ix_ + 1 - (curPage_ * 52);

		if (pict_ix == 1) {
			img1.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 2) {
			img2.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 3) {
			img3.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 4) {
			img4.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 5) {
			img5.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 6) {
			img6.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 7) {
			img7.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 8) {
			img8.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 9) {
			img9.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 10) {
			img10.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 11) {
			img11.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 12) {
			img12.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 13) {
			img13.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 14) {
			img14.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 15) {
			img15.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 16) {
			img16.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 17) {
			img17.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 18) {
			img18.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 19) {
			img19.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 20) {
			img20.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 21) {
			img21.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 22) {
			img22.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 23) {
			img23.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 24) {
			img24.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 25) {
			img25.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 26) {
			img26.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 27) {
			img27.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 28) {
			img28.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 29) {
			img29.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 30) {
			img30.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 31) {
			img31.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 32) {
			img32.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 33) {
			img33.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 34) {
			img34.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 35) {
			img35.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 36) {
			img36.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 37) {
			img37.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 38) {
			img38.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 39) {
			img39.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 40) {
			img40.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 41) {
			img41.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 42) {
			img42.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 43) {
			img43.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 44) {
			img44.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 45) {
			img45.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 46) {
			img46.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 47) {
			img47.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 48) {
			img48.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 49) {
			img49.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 50) {
			img50.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 51) {
			img51.source = bitmaplist_[cur_ix_];
		}
		else if (pict_ix == 52) {
			img52.source = bitmaplist_[cur_ix_];
			if (filelist_.length > (curPage_ * 52)) {
				imgN.visible = true;
			}
		}
	}
		
	//cur_ix_++;
}

protected function onMouseClick (event:MouseEvent):void
{
	var x:int = event.localX;
	var y:int = event.localY;
	if (x < 200 && y < 230) {
		if (curPage_ > 0) {
			resetImages();
			curPage_--;
			cur_ix_ = curPage_ * 52;
			if (filelist_.length <= cur_ix_) {
				return;
			}
			if (curPage_ == 0) {
				imgB.visible = true;
				imgP.visible = false;
			}
			imgN.visible = false;
			var endIx:int = cur_ix_ + 52;
			if (endIx > filelist_.length) {
				endIx = filelist_.length;
			}
			st_info.text = "      " + filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + endIx.toString()
				+ ")        " + curDirectory_.name;
			loadThumbnails();
		}
		else {
			data.kSrcSelection = "";
			data.kPageIndex = ixinval;
			navigator.popView();
		}
	}
	else if (x > 1000 && y > 1600 && imgN.visible) {
		resetImages();
		curPage_++;
		cur_ix_ = curPage_ * 52;
		if (filelist_.length <= cur_ix_) {
			return;
		}
		imgB.visible = false;
		imgN.visible = false;
		imgP.visible = true;
		
		var eendIx:int = cur_ix_ + 52;
		if (eendIx > filelist_.length) {
			eendIx = filelist_.length;
		}
		st_info.text = "      " + filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + eendIx.toString()
			+ ")        " + curDirectory_.name;

		if (bitmaplist_.length <= cur_ix_) {
			curFile_ = curDirectory_.resolvePath (filelist_[cur_ix_]);
			var urlstr2:String = "file://";
			urlstr2 += curFile_.nativePath;
			var req2:URLRequest = new URLRequest (urlstr2);
			loader_ = new Loader();
			loader_.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
			loader_.load(req2);
		}
		else {
			loadThumbnails();
		}
	}
	else {
		var index_x:int = x / 200;
		var index_y:int = (y - 30) / 200;
		if (y < 0) {
			y = 0;
		}
		var pict_ix:int = index_y * 6 + index_x - 1 + curPage_ * 52;
		if (pict_ix >= 0 && pict_ix < filelist_.length) {
			curFile_ = curDirectory_.resolvePath (filelist_[pict_ix]);
			data.kSrcSelection = curFile_.nativePath;
			data.kDirectory = curDirectory_.nativePath;
			data.kPageIndex = curPage_;
			showImgOnReturn_ = true;
			navigator.popView();
		}
	}
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

private function resetImages():void
{
	img1.source = null;
	img2.source = null;
	img3.source = null;
	img4.source = null;
	img5.source = null;
	img6.source = null;
	img7.source = null;
	img8.source = null;
	img9.source = null;
	img10.source = null;
	img11.source = null;
	img12.source = null;
	img13.source = null;
	img14.source = null;
	img15.source = null;
	img16.source = null;
	img17.source = null;
	img18.source = null;
	img19.source = null;
	img20.source = null;
	img21.source = null;
	img22.source = null;
	img23.source = null;
	img24.source = null;
	img25.source = null;
	img26.source = null;
	img27.source = null;
	img28.source = null;
	img29.source = null;
	img30.source = null;
	img31.source = null;
	img32.source = null;
	img33.source = null;
	img34.source = null;
	img35.source = null;
	img36.source = null;
	img37.source = null;
	img38.source = null;
	img39.source = null;
	img40.source = null;
	img41.source = null;
	img42.source = null;
	img43.source = null;
	img44.source = null;
	img45.source = null;
	img46.source = null;
	img47.source = null;
	img48.source = null;
	img49.source = null;
	img50.source = null;
	img51.source = null;
	img52.source = null;
}
//=======================================================
/*
\history

WGo-2015-03-02: Created

*/

