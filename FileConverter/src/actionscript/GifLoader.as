package actionscript
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.controls.Image;
	
	//import mx.controls.Alert;

	
	public class GifLoader
	{
		//private var initPath_:String = "";

		private var gifFs_:File = null;
		private var img_:Image = null;
		private var bmpdata_:BitmapData = null; 
		private var header_:Array = null;
		private var imgdata_:Array = null;
		private var counter_:int = 0;
		private var delay_:int = 10;
		private var loader_:Loader = null;
		private var width_:int = 0;
		private var height_:int = 10;
		private var frameMove_:Boolean = false;
		private var offset1_:uint = 0;
		private var offset2_:uint = 0;
		private var offset3_:uint = 0;
		private var offset4_:uint = 0;

		
		public function GifLoader()
		{
			//try {
			//}
			//catch (error:Error) {
			//}
		}
		
		public function loadGif (gifFs:File, imgctrl:Image):void
		{
			if (gifFs == null || imgctrl == null) {
				return;
			}
			gifFs_ = gifFs;
			img_ = imgctrl;
			imgdata_ = new Array();
			try {
				var fstr:FileStream = new FileStream();
				fstr.open (gifFs, FileMode.READ);
				var len:int = gifFs.size;
				var record:Array = new Array();
				
				for (var ix:uint = 0; ix < len; ix++) {
					var bt:uint = fstr.readUnsignedByte();
					record.push (bt);
				}
				var foundhdr:Array = record.slice (0, 6);
				var hdrstr:String = foundhdr.toString();
				if (hdrstr != "71,73,70,56,55,97" && hdrstr != "71,73,70,56,57,97") {
					return;
				}
				width_ = record[6] + 256 * record[7];
				height_ = record[8] + 256 * record[9];
				var iy:int = 13;
				var flags:uint = record[10];
				var cpres:int = flags & 0x80;
				if (cpres != 0) {
					var gctSize:int = (flags & 0x07) + 1;
					gctSize = 3 * (Math.pow(2, gctSize));
					iy += gctSize;
				}
				if (iy + 2 >= len) {
					return;
				}
				
				var ctrlextFound:Boolean = false;
				var ctrlextIx:int = 0;
				do {
					var curval:uint = record[iy];
					if (curval == 0x21) {
						if (record[iy + 1] == 0xf9) { // Graphic Control Extension
							if (header_ == null) {
								header_ = record.slice (0, iy);
							}
							delay_ = record[iy + 4] + 256 * record[iy + 5];
							if (delay_ < 5 || delay_ > 100) {
								delay_ = 10;
							}
							ctrlextIx = iy;
							var cextsize:int = record[iy + 2];
							iy += cextsize + 4;
							
							ctrlextFound = true;
						}
						else if (record[iy + 1] == 0xfe) { // comment extension
							iy = skipBlocks (record, iy + 2, len);
						}
						else { // application extension
							var appextsize:int = record[iy + 2];
							//var appname:String = record.slice (iy + 3, iy + 11).toString();
							iy += appextsize + 3;
							iy = skipBlocks (record, iy, len);
						}
					}
					else if (curval == 0x2c) {
						var nextix:int = findNextData (record, iy, len);
						if (!ctrlextFound) {
							ctrlextIx = iy;
						}
						var pictarr:Array = record.slice (ctrlextIx, nextix - 1);
						imgdata_.push (pictarr);
						iy = nextix;
						
						ctrlextFound = false;
						if (record[nextix] == 0) {
							break;
						}
					}
					else {
						break;
					}
					
				} while (iy < len);
			}
			catch (error:Error) {
				return;
			}
			showOneGif();
		}
		
		private function findNextData (record:Array, ix:int, len:int):int
		{
			var iy:int = ix;
			var imageFound:Boolean = false;
			do {
				if (record[iy] == 0x2c && !imageFound) { // Image Descriptor
					imageFound = true;
					if (record[iy + 1] != 0 || record[iy + 2] != 0 || record[iy + 3] != 0 || record[iy + 4] != 0) {
						if (offset1_ != 0 || offset2_ != 0 || offset3_ != 0 || offset4_ != 0) {
							var xmove:Boolean = (record[iy + 1] != offset1_ || record[iy + 2] != offset2_);
							var ymove:Boolean = (record[iy + 3] != offset3_ || record[iy + 4] != offset4_);
							frameMove_ = xmove && ymove;
						}
						offset1_ = record[iy + 1];
						offset2_ = record[iy + 2];
						offset3_ = record[iy + 3];
						offset4_ = record[iy + 4];
					}
					var flags:uint = record[iy + 9];
					iy += 11; // incl. LZW byte
					var cpres:int = flags & 0x80;
					if (cpres != 0) {
						var ctSize:int = (flags & 0x07) + 1;
						ctSize = 3 * (Math.pow(2, ctSize));
						iy += ctSize;
					}
					iy = skipBlocks (record, iy, len);
				}
				else if (record[iy] == 0x21 && record[iy + 1] == 0x01) { // Plain Text Extension
					var extsize:int = record[iy + 2];
					iy += extsize + 3;
					iy = skipBlocks (record, iy, len);
				}
				else {
					break;
				}
			} while (iy < len);
			
			return iy; 
		}
		
		private function skipBlocks (record:Array, ix:int, len:int):int
		{
			var iy:int = ix;
			do {
				var blklen:int = record[iy];
				if (blklen < 1) {
					break;
				}
				else {
					iy += blklen + 1;
				}
			} while (iy < len);
			return iy + 1;
		}
		
		private function StartGifTimer():void
		{
			var tm:Timer = new Timer (delay_ * 10, 1);
			tm.addEventListener (TimerEvent.TIMER, onShowGifTimer);
			tm.start();
		}
		
		private function onShowGifTimer (event:TimerEvent):void
		{
			if (header_ == null) {
				return;
			}
			showOneGif();
		}
		
		private function showOneGif():void
		{
			if (img_ == null || header_ == null || counter_ >= imgdata_.length) {
				return;
			}
			var ba:ByteArray = new ByteArray();
			var data:Array = imgdata_[counter_];
			
			for (var ix:uint = 0; ix < header_.length; ix++) {
				ba.writeByte (header_[ix]);
			}
			for (var iy:uint = 0; iy < data.length; iy++) {
				ba.writeByte (data[iy]);
			}
			
			counter_++;
			if (counter_ >= imgdata_.length) {
				counter_ = 0;
				//bmpdata_.dispose();
				//bmpdata_ = null;
			}
			loader_ = new Loader();
			loader_.contentLoaderInfo.addEventListener (Event.COMPLETE, onLoadComplete);
			loader_.loadBytes (ba);
		}

		private function onLoadComplete (event:Event):void
		{
			if (img_ == null || header_ == null || imgdata_ == null) {
				return;
			}
			var bmp:Bitmap = Bitmap(loader_.content);
			if (bmpdata_ != null) {
				if (frameMove_) {
					bmpdata_.copyPixels (bmp.bitmapData, new Rectangle(0,0,bmp.bitmapData.width,bmp.bitmapData.height), new Point(0,0));
				}
				else {
					bmpdata_.draw (bmp.bitmapData, null, null, BlendMode.NORMAL, null, true); // smoothing
				}
				bmp.bitmapData = bmpdata_;
			}
			else {
				bmpdata_ = bmp.bitmapData;
			}
			
			bmp.smoothing = true;
			img_.visible = true;
			img_.source = bmp;
			if (imgdata_.length > 1) {
				StartGifTimer();
			}
		}
		
		public function getImageSize():String
		{
			return width_.toString() + " x " + height_.toString();
		}
		
		public function getImageCount():String
		{
			if (imgdata_ != null) {
				var len:uint = imgdata_.length;
				if (len > 1) {
					return "Frame count: " + len.toString();
				}
			}
			return "";
		}
		
		public function stopGif():void
		{
			header_ = null;
			imgdata_ = null;
			if (img_ != null) {
				img_.source = null;
				img_.visible = false;
			}
		}

	}
}

//=======================================================
/*
\history

WGo-2015-03-17: created
WGo-2015-03-19: seems to work

*/
