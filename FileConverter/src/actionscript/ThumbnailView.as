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

import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.AIREvent;
import mx.events.CloseEvent;
import mx.events.FlexNativeWindowBoundsEvent;

import spark.primitives.Rect;
import actionscript.ThumbnailCache;


private var imagePath_:String = "";
private var imageName_:String = "";
private var curDirectory_:File = null;
private var curFile_:File = null;
private var filelist_:Array = null;
private var bitmaplist_:Array = null;
private var cur_ix_:int = 0;
private var curPage_:int = 0;

private var loader_:Loader = null;
private var loadfile_:String = "";
private var shownImage_:Bitmap = null; 
private var isExifPortrait_:Boolean = false;

private var mouseX_:Number = 0;
private var mouseY_:Number = 0;
private var cache_:ThumbnailCache = null;
private var foundInCache_:Boolean = false;
private var cacheModified_:Boolean = false;


private function OnWindowComplete():void
{
	this.nativeWindow.x = 50;
	this.nativeWindow.y = 0;
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	this.addEventListener (MouseEvent.CLICK, onMouseClick);
	this.setFocus();
}

public function showThumbnails (tfs:File):void
{
	if (tfs == null) {
		return;
	}
	curDirectory_ = tfs.parent;
	filelist_ = getFileListing (curDirectory_);
	
	if (filelist_.length == 0) {
		return;
	}
	cur_ix_ = 0;
	var endIx:int = 40;
	if (filelist_.length < 40) {
		endIx = filelist_.length;
	}
	this.title = filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + endIx.toString() + ")      " + curDirectory_.name;
	
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

private function onLoadComplete (event:Event):void
{
	cacheModified_ = true;
	var image:Bitmap = Bitmap(loader_.content);
	image.smoothing = false;
	var image_w:Number = image.bitmapData.width;
	var image_h:Number = image.bitmapData.height;
	var scale:Number = 0;
	//var offsetX:int = 3;
	//var offsetY:int = 3;
	if (image_w > image_h) {
		scale = 144 / image_w;
		//offsetY = (150 - image_h * scale) / 2;
	}
	else {
		scale = 144 / image_h;
		//offsetX = (150 - image_w * scale) / 2;
	}
	var mx:Matrix = new Matrix();
	mx.scale (scale, scale);
	
	var bdata:BitmapData = new BitmapData (image_w * scale, image_h * scale, false);
	bdata.draw (image.bitmapData, mx);
	image.bitmapData.dispose(); // saves a lot of memory, up to 300 MB (debug version)
	//bdata.scroll (offsetX, offsetY);

	var shownImg:Bitmap = new Bitmap (bdata);
	bitmaplist_.push (bdata);
	cache_.saveThumbnail (bdata, curFile_, cur_ix_);
	
	var pict_ix:int = cur_ix_ + 1 - (curPage_ * 40);
	
	if (pict_ix == 1) {
		arrangeImage (img1, shownImg);
	}
	else if (pict_ix == 2) {
		arrangeImage (img2, shownImg);
	}
	else if (pict_ix == 3) {
		arrangeImage (img3, shownImg);
	}
	else if (pict_ix == 4) {
		arrangeImage (img4, shownImg);
	}
	else if (pict_ix == 5) {
		arrangeImage (img5, shownImg);
	}
	else if (pict_ix == 6) {
		arrangeImage (img6, shownImg);
	}
	else if (pict_ix == 7) {
		arrangeImage (img7, shownImg);
	}
	else if (pict_ix == 8) {
		arrangeImage (img8, shownImg);
	}
	else if (pict_ix == 9) {
		arrangeImage (img9, shownImg);
	}
	else if (pict_ix == 10) {
		arrangeImage (img10, shownImg);
	}
	else if (pict_ix == 11) {
		arrangeImage (img11, shownImg);
	}
	else if (pict_ix == 12) {
		arrangeImage (img12, shownImg);
	}
	else if (pict_ix == 13) {
		arrangeImage (img13, shownImg);
	}
	else if (pict_ix == 14) {
		arrangeImage (img14, shownImg);
	}
	else if (pict_ix == 15) {
		arrangeImage (img15, shownImg);
	}
	else if (pict_ix == 16) {
		arrangeImage (img16, shownImg);
	}
	else if (pict_ix == 17) {
		arrangeImage (img17, shownImg);
	}
	else if (pict_ix == 18) {
		arrangeImage (img18, shownImg);
	}
	else if (pict_ix == 19) {
		arrangeImage (img19, shownImg);
	}
	else if (pict_ix == 20) {
		arrangeImage (img20, shownImg);
	}
	else if (pict_ix == 21) {
		arrangeImage (img21, shownImg);
	}
	else if (pict_ix == 22) {
		arrangeImage (img22, shownImg);
	}
	else if (pict_ix == 23) {
		arrangeImage (img23, shownImg);
	}
	else if (pict_ix == 24) {
		arrangeImage (img24, shownImg);
	}
	else if (pict_ix == 25) {
		arrangeImage (img25, shownImg);
	}
	else if (pict_ix == 26) {
		arrangeImage (img26, shownImg);
	}
	else if (pict_ix == 27) {
		arrangeImage (img27, shownImg);
	}
	else if (pict_ix == 28) {
		arrangeImage (img28, shownImg);
	}
	else if (pict_ix == 29) {
		arrangeImage (img29, shownImg);
	}
	else if (pict_ix == 30) {
		arrangeImage (img30, shownImg);
	}
	else if (pict_ix == 31) {
		arrangeImage (img31, shownImg);
	}
	else if (pict_ix == 32) {
		arrangeImage (img32, shownImg);
	}
	else if (pict_ix == 33) {
		arrangeImage (img33, shownImg);
	}
	else if (pict_ix == 34) {
		arrangeImage (img34, shownImg);
	}
	else if (pict_ix == 35) {
		arrangeImage (img35, shownImg);
	}
	else if (pict_ix == 36) {
		arrangeImage (img36, shownImg);
	}
	else if (pict_ix == 37) {
		arrangeImage (img37, shownImg);
	}
	else if (pict_ix == 38) {
		arrangeImage (img38, shownImg);
	}
	else if (pict_ix == 39) {
		arrangeImage (img39, shownImg);
	}
	else if (pict_ix == 40) {
		arrangeImage (img40, shownImg);
	}
	
	if (filelist_.length == cur_ix_ + 1 || pict_ix == 40) {
		return;
	}
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
	for ( ; cur_ix_ - (curPage_ * 40) < 40; cur_ix_++) {
		
		if (bitmaplist_.length <= cur_ix_) {
			break;
		}
		var pict_ix:int = cur_ix_ + 1 - (curPage_ * 40);
		var bdata:BitmapData = bitmaplist_[cur_ix_];
		var shownImg:Bitmap = new Bitmap (bdata);
		
		if (pict_ix == 1) {
			arrangeImage (img1, shownImg);
		}
		else if (pict_ix == 2) {
			arrangeImage (img2, shownImg);
		}
		else if (pict_ix == 3) {
			arrangeImage (img3, shownImg);
		}
		else if (pict_ix == 4) {
			arrangeImage (img4, shownImg);
		}
		else if (pict_ix == 5) {
			arrangeImage (img5, shownImg);
		}
		else if (pict_ix == 6) {
			arrangeImage (img6, shownImg);
		}
		else if (pict_ix == 7) {
			arrangeImage (img7, shownImg);
		}
		else if (pict_ix == 8) {
			arrangeImage (img8, shownImg);
		}
		else if (pict_ix == 9) {
			arrangeImage (img9, shownImg);
		}
		else if (pict_ix == 10) {
			arrangeImage (img10, shownImg);
		}
		else if (pict_ix == 11) {
			arrangeImage (img11, shownImg);
		}
		else if (pict_ix == 12) {
			arrangeImage (img12, shownImg);
		}
		else if (pict_ix == 13) {
			arrangeImage (img13, shownImg);
		}
		else if (pict_ix == 14) {
			arrangeImage (img14, shownImg);
		}
		else if (pict_ix == 15) {
			arrangeImage (img15, shownImg);
		}
		else if (pict_ix == 16) {
			arrangeImage (img16, shownImg);
		}
		else if (pict_ix == 17) {
			arrangeImage (img17, shownImg);
		}
		else if (pict_ix == 18) {
			arrangeImage (img18, shownImg);
		}
		else if (pict_ix == 19) {
			arrangeImage (img19, shownImg);
		}
		else if (pict_ix == 20) {
			arrangeImage (img20, shownImg);
		}
		else if (pict_ix == 21) {
			arrangeImage (img21, shownImg);
		}
		else if (pict_ix == 22) {
			arrangeImage (img22, shownImg);
		}
		else if (pict_ix == 23) {
			arrangeImage (img23, shownImg);
		}
		else if (pict_ix == 24) {
			arrangeImage (img24, shownImg);
		}
		else if (pict_ix == 25) {
			arrangeImage (img25, shownImg);
		}
		else if (pict_ix == 26) {
			arrangeImage (img26, shownImg);
		}
		else if (pict_ix == 27) {
			arrangeImage (img27, shownImg);
		}
		else if (pict_ix == 28) {
			arrangeImage (img28, shownImg);
		}
		else if (pict_ix == 29) {
			arrangeImage (img29, shownImg);
		}
		else if (pict_ix == 30) {
			arrangeImage (img30, shownImg);
		}
		else if (pict_ix == 31) {
			arrangeImage (img31, shownImg);
		}
		else if (pict_ix == 32) {
			arrangeImage (img32, shownImg);
		}
		else if (pict_ix == 33) {
			arrangeImage (img33, shownImg);
		}
		else if (pict_ix == 34) {
			arrangeImage (img34, shownImg);
		}
		else if (pict_ix == 35) {
			arrangeImage (img35, shownImg);
		}
		else if (pict_ix == 36) {
			arrangeImage (img36, shownImg);
		}
		else if (pict_ix == 37) {
			arrangeImage (img37, shownImg);
		}
		else if (pict_ix == 38) {
			arrangeImage (img38, shownImg);
		}
		else if (pict_ix == 39) {
			arrangeImage (img39, shownImg);
		}
		else if (pict_ix == 40) {
			arrangeImage (img40, shownImg);
		}
	}
	//arrangeAll();
}

private function arrangeImage (imgctrl:Image, bmp:Bitmap):void
{
	imgctrl.source = bmp;
	var contW:int = bmp.bitmapData.width;
	var contH:int = bmp.bitmapData.height;
	var offsetX:int = (150 - contW) / 2;
	var offsetY:int = (150 - contH) / 2;
	imgctrl.x = offsetX;
	imgctrl.y = offsetY;
}

private function arrangeAll():void
{
	for (var ix:int = 0; ix < this.numElements; ix++) {
		var elm:Image = this.getElementAt(ix) as Image;
		if (elm != null) {
			var contW:int = elm.contentWidth;
			var contH:int = elm.contentHeight;
			var offsetX:int = (150 - contW) / 2;
			var offsetY:int = (150 - contH) / 2;
			elm.x = offsetX;
			elm.y = offsetY;
		}
	}
	
	//numElements : int
	//[read-only] The number of visual elements in this container.
	//getElementAt(index:int):IVisualElement
}


protected function onClose(event:Event):void
{
	//FlexGlobals.topLevelApplication.setSelectedFile (imageName_);
}

protected function onWindowDeactivate(event:AIREvent):void
{
}

protected function onWindowActivate(event:AIREvent):void
{
	this.setFocus();
}

protected function OnKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey;
	var key:uint = event.keyCode; // 221 +
	if (key == Keyboard.SPACE || (key == Keyboard.W && isControlKey)) {
		this.close();
	}
	else if (key == Keyboard.LEFT) {
		if (curPage_ > 0) {
			resetImages();
			curPage_--;
			cur_ix_ = curPage_ * 40;
			if (filelist_.length <= cur_ix_) {
				return;
			}
			var endIx:int = cur_ix_ + 40;
			if (endIx > filelist_.length) {
				endIx = filelist_.length;
			}
			this.title = filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + endIx.toString() + ")      " + curDirectory_.name;
			loadThumbnails();
		}
	}
	else if (key == Keyboard.RIGHT) {
		if (filelist_.length <= (curPage_ + 1) * 40) {
			return;
		}
		resetImages();
		curPage_++;
		cur_ix_ = curPage_ * 40;
		
		var eendIx:int = cur_ix_ + 40;
		if (eendIx > filelist_.length) {
			eendIx = filelist_.length;
		}
		this.title = filelist_.length.toString() + " Images (" + (cur_ix_ + 1).toString() + "-" + eendIx.toString() + ")      " + curDirectory_.name;
		
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
}

protected function onMouseClick (event:MouseEvent):void
{
	var x:int = event.stageX;
	var y:int = event.stageY;
	var index_x:int = x / 150;
	var index_y:int = y / 150;
	var pict_ix:int = index_y * 8 + index_x + curPage_ * 40;
	if (pict_ix >= 0 && pict_ix < filelist_.length) {
		curFile_ = curDirectory_.resolvePath (filelist_[pict_ix]);
		//this.close();
		FlexGlobals.topLevelApplication.showImage (curFile_.nativePath);
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
}

//=======================================================
/*
\history

WGo-2015-03-10: created
WGo-2015-03-12: set focus after activate

*/

