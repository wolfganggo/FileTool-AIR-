package actionscript
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	

	public class ThumbnailCache
	{
		private var cacheFs_:File = null;
		private var thumbFolder_:File = null;
		private var pictFolder_:String = "";
		//public var curThumb_:BitmapData = null;
		
		public function ThumbnailCache()
		{
			try {
				cacheFs_ = File.applicationStorageDirectory;
				cacheFs_ = cacheFs_.resolvePath("pictcache/");
				cacheFs_.createDirectory();
			}
			catch (error:Error) {
			}
		}

		public function startThumbnails (path:String, name:String):void
		{
			if (cacheFs_ == null || !cacheFs_.exists) {
				return;
			}
			
			var cachefs:File = cacheFs_.resolvePath (name);
			var cnt:int = 1;
			while (cachefs.exists) {
				cachefs = cacheFs_.resolvePath (name + "_" + cnt.toString());
				cnt++;
				if (cnt > 999) {
					return;
				}
			}
			cachefs.createDirectory();

			pictFolder_ = path;
			thumbFolder_ = cachefs;
		}		
		
		public function saveThumbnail (obj:BitmapData, origFs:File, thumbCounter:int):void
		{
			if (thumbFolder_ == null || !thumbFolder_.exists || pictFolder_.length == 0) {
				return;
			}
			var image_w:int = obj.width;
			var image_h:int = obj.height;
			var cache:Object = new Object;
			cache.kOriginalFolder = pictFolder_;
			cache.kOriginalFile = origFs.name;
			cache.kFileDate = origFs.modificationDate.toLocaleString();
			cache.kWidth = image_w;
			cache.kHeight = image_h;

			//curThumb_ = new BitmapData (image_w, image_h, false);
			//curThumb_.copyPixels (obj.bitmapData, new Rectangle (0, 0, image_w, image_h), new Point());
			//var byteArray:ByteArray = new ByteArray(); 
			//obj.bitmapData.encode(new Rectangle(0,0,640,480), new JPEGEncoderOptions(50), byteArray);
			var byteArray:ByteArray = obj.getPixels (new Rectangle (0, 0, image_w, image_h));
			byteArray.compress();
			//obj.bitmapData.setPixels(byteArray);

			try {
				var file1:File = thumbFolder_.resolvePath (thumbCounter.toString());
				var fstr1:FileStream = new FileStream();
				fstr1.open (file1, FileMode.WRITE);
				fstr1.writeBytes (byteArray);
				//fstr1.writeObject (byteArray);
				fstr1.close();
				var file2:File = thumbFolder_.resolvePath (thumbCounter.toString() + "a");
				var fstr2:FileStream = new FileStream();
				fstr2.open (file2, FileMode.WRITE);
				fstr2.writeObject (cache);
				fstr2.close();
			}
			catch (error:Error) {
			}
		}
		
		public function readThumbnails (path:String, name:String, files:Array):Array
		{
			if (cacheFs_ == null || !cacheFs_.exists) {
				//Utilities.logDebug("##ERROR readThumbnails: cacheFs_ invalid");
				return null;
			}
			var retArr:Array = new Array();

			try {
				var dirFiles:Array = cacheFs_.getDirectoryListing();
				for (var i1:uint = 0; i1 < dirFiles.length; i1++) {
					var f:File = dirFiles[i1];
					if (f.isDirectory && f.name.indexOf(name) != -1) {
						var f0a:File = f.resolvePath("0a");
						var origP:File = new File (path);
						if (f0a.exists) {
							var fstr:FileStream = new FileStream();
							fstr.open (f0a, FileMode.READ);
							var cache:Object = fstr.readObject();
							fstr.close();
							if (cache != null) {
								var curPath:String = cache.kOriginalFolder;
								if (path != curPath) {
									continue;
								}
								pictFolder_ = curPath;
							}							
						}
						else {
							continue;
						}
						thumbFolder_ = f;
						var i2:int = 0;
						do {
							//if (files.length <= i2) {
							//	Utilities.logDebug("##ERROR readThumbnails: files.length");
							//	return null;
							//}
							var fxa:File = f.resolvePath (i2.toString() + "a");
							var origF:File = origP.resolvePath (files[i2]);
							if (!fxa.exists) {
								break;
							}
							if (!origF.exists) {
								//Utilities.logDebug("##ERROR readThumbnails: origF invalid");
								return null;
							}
							var fsa:FileStream = new FileStream();
							fsa.open (fxa, FileMode.READ);
							var cache1:Object = fsa.readObject();
							fsa.close();
							
							var w:int = 0;
							var h:int = 0;
							if (cache1 != null) {
								var curDate:String = cache1.kFileDate;
								var curFile:String = cache1.kOriginalFile;
								w = cache1.kWidth;
								h = cache1.kHeight;
								if (curFile != files[i2] || curDate != origF.modificationDate.toLocaleString()) {
									//Utilities.logDebug("##ERROR readThumbnails: origF.modificationDate different");
									return null;
								}
							}
							var fx:File = f.resolvePath (i2.toString());
							if (!fx.exists) {
								//Utilities.logDebug("##ERROR readThumbnails: fx invalid");
								return null;
							}
							var fs:FileStream = new FileStream();
							fs.open (fx, FileMode.READ);
							var bytearr:ByteArray = new ByteArray(); 
							//var obj:Object = fs.readObject();
							//var objStr:String = String (obj);
							//var bytearr:ByteArray = obj as ByteArray; 
							fs.readBytes (bytearr);
							fs.close();
							if (bytearr != null) {
								bytearr.uncompress();
								var bdata:BitmapData = new BitmapData(w,h);
								bdata.setPixels (new Rectangle(0,0,w,h), bytearr);
								//var bmp:Bitmap = new Bitmap(bdata);
								retArr.push (bdata);
							}
							i2++;
						} while (i2 < files.length);
						
					}
				}
			}
			catch (error:Error) {
				//Utilities.logDebug("##ERROR readThumbnails: " + error.toString());
				return null;
			}
			return retArr;
		}
		
		public function removeThumbnails():Boolean
		{
			if (thumbFolder_ == null || !thumbFolder_.exists) {
				return false;
			}
			
			try {
				thumbFolder_.moveToTrash();
				return true;
			}
			catch (error:Error) {
				return false;
			}
			return false;
		}

	}
}