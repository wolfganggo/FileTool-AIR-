package actionscript
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	//import mx.controls.Alert;

	
	public class Preferences
	{
		private var prefsFs_:File = null;
		private var prefs_:Object = null;
		private var initPath_:String = "";
		private var customPath1_:String = "";
		private var customPath2_:String = "";
		private var img_w_:int = 40;
		private var img_h_:int = 40;
		private var txt_w_:int = 0;
		private var txt_h_:int = 0;
		private var txtbin_w_:int = 0;
		private var txtbin_h_:int = 0;
		private var memstr1_:String = "";
		private var memstr2_:String = "";
		private var memstr3_:String = "";
		private var memstr4_:String = "";
		private var memstr5_:String = "";
		private var memstr6_:String = "";
		private var memstr7_:String = "";
		private var memstr8_:String = "";
		private var memstr9_:String = "";
		private var editstr1_:String = "";
		private var editstr2_:String = "";
		private var editstr3_:String = "";
		private var editstr4_:String = "";
		private var editstr5_:String = "";
		private var editstr6_:String = "";
		private var editstr7_:String = "";
		private var editstr8_:String = "";
		private var editstr9_:String = "";
		private var findstr1_:String = "";
		private var findstr2_:String = "";
		private var findstr3_:String = "";
		private var findstr4_:String = "";
		private var findstr5_:String = "";
		private var findstr6_:String = "";
		private var findstr7_:String = "";
		private var findstr8_:String = "";
		private var findstr9_:String = "";
		private var findstr10_:String = "";
		private var replstr1_:String = "";
		private var replstr2_:String = "";
		private var replstr3_:String = "";
		private var replstr4_:String = "";
		private var replstr5_:String = "";
		private var replstr6_:String = "";
		private var replstr7_:String = "";
		private var replstr8_:String = "";
		private var replstr9_:String = "";
		private var replstr10_:String = "";
		private var findbinstr1_:String = "";
		private var findbinstr2_:String = "";
		private var findbinstr3_:String = "";
		private var findbinstr4_:String = "";
		private var findbinstr5_:String = "";
		private var findbinstr6_:String = "";
		private var findbinstr7_:String = "";
		private var findbinstr8_:String = "";
		private var findbinstr9_:String = "";
		private var findbinstr10_:String = "";
		private var replbinstr1_:String = "";
		private var replbinstr2_:String = "";
		private var replbinstr3_:String = "";
		private var replbinstr4_:String = "";
		private var replbinstr5_:String = "";
		private var replbinstr6_:String = "";
		private var replbinstr7_:String = "";
		private var replbinstr8_:String = "";
		private var replbinstr9_:String = "";
		private var replbinstr10_:String = "";

		public function Preferences()
		{
			try {
				prefsFs_ = File.applicationStorageDirectory;
				prefsFs_ = prefsFs_.resolvePath("prefs/");
				prefsFs_.createDirectory();
				prefsFs_ = prefsFs_.resolvePath("savedprefs");
				
				if (prefsFs_.exists) {
					var fstr:FileStream = new FileStream();
					fstr.open (prefsFs_, FileMode.READ);
					prefs_ = fstr.readObject();
					fstr.close();
					initPath_ = getInitPath();
					customPath1_ = readCustomPath1();
					customPath2_ = readCustomPath2();
					img_w_ = readImageWidth();
					img_h_ = readImageHeight();
					readAllMemstr();
					readFindStr();
				}
				else {
					prefs_ = new Object();
				}
			}
			catch (error:Error) {
			}
		}
		
		public function save (x:int, y:int, w:int, h:int):void
		{
			var entry:Object = new Object();
			entry.kXPos = x;
			entry.kYPos = y;
			entry.kWidth = w;
			entry.kHeight = h;
			entry.kImgWidth = img_w_;
			entry.kImgHeight = img_h_;
			entry.kTxtWidth = txt_w_;
			entry.kTxtHeight = txt_h_;
			entry.kTxtBinWidth = txtbin_w_;
			entry.kTxtBinHeight = txtbin_h_;
			prefs_["ui_position"] = entry;
			
			var stringEntry:Object = new Object();
			stringEntry.kInitPath = initPath_;
			stringEntry.kCustomPath = customPath1_;
			stringEntry.kCustomPath2 = customPath2_;
			prefs_["path_prefs"] = stringEntry;

			var memstrEntry:Object = new Object();
			memstrEntry.kMemstr1 = memstr1_;
			memstrEntry.kMemstr2 = memstr2_;
			memstrEntry.kMemstr3 = memstr3_;
			memstrEntry.kMemstr4 = memstr4_;
			memstrEntry.kMemstr5 = memstr5_;
			memstrEntry.kMemstr6 = memstr6_;
			memstrEntry.kMemstr7 = memstr7_;
			memstrEntry.kMemstr8 = memstr8_;
			memstrEntry.kMemstr9 = memstr9_;
			memstrEntry.kEditstr1 = editstr1_;
			memstrEntry.kEditstr2 = editstr2_;
			memstrEntry.kEditstr3 = editstr3_;
			memstrEntry.kEditstr4 = editstr4_;
			memstrEntry.kEditstr5 = editstr5_;
			memstrEntry.kEditstr6 = editstr6_;
			memstrEntry.kEditstr7 = editstr7_;
			memstrEntry.kEditstr8 = editstr8_;
			memstrEntry.kEditstr9 = editstr9_;
			prefs_["string_prefs"] = memstrEntry;

			var findStringEntry:Object = new Object();
			findStringEntry.kFindStr1 = findstr1_;
			findStringEntry.kFindStr2 = findstr2_;
			findStringEntry.kFindStr3 = findstr3_;
			findStringEntry.kFindStr4 = findstr4_;
			findStringEntry.kFindStr5 = findstr5_;
			findStringEntry.kFindStr6 = findstr6_;
			findStringEntry.kFindStr7 = findstr7_;
			findStringEntry.kFindStr8 = findstr8_;
			findStringEntry.kFindStr9 = findstr9_;
			findStringEntry.kFindStr10 = findstr10_;
			findStringEntry.kReplStr1 = replstr1_;
			findStringEntry.kReplStr2 = replstr2_;
			findStringEntry.kReplStr3 = replstr3_;
			findStringEntry.kReplStr4 = replstr4_;
			findStringEntry.kReplStr5 = replstr5_;
			findStringEntry.kReplStr6 = replstr6_;
			findStringEntry.kReplStr7 = replstr7_;
			findStringEntry.kReplStr8 = replstr8_;
			findStringEntry.kReplStr9 = replstr9_;
			findStringEntry.kReplStr10 = replstr10_;

			findStringEntry.kFindBinStr1 = findbinstr1_;
			findStringEntry.kFindBinStr2 = findbinstr2_;
			findStringEntry.kFindBinStr3 = findbinstr3_;
			findStringEntry.kFindBinStr4 = findbinstr4_;
			findStringEntry.kFindBinStr5 = findbinstr5_;
			findStringEntry.kFindBinStr6 = findbinstr6_;
			findStringEntry.kFindBinStr7 = findbinstr7_;
			findStringEntry.kFindBinStr8 = findbinstr8_;
			findStringEntry.kFindBinStr9 = findbinstr9_;
			findStringEntry.kFindBinStr10 = findbinstr10_;
			findStringEntry.kReplBinStr1 = replbinstr1_;
			findStringEntry.kReplBinStr2 = replbinstr2_;
			findStringEntry.kReplBinStr3 = replbinstr3_;
			findStringEntry.kReplBinStr4 = replbinstr4_;
			findStringEntry.kReplBinStr5 = replbinstr5_;
			findStringEntry.kReplBinStr6 = replbinstr6_;
			findStringEntry.kReplBinStr7 = replbinstr7_;
			findStringEntry.kReplBinStr8 = replbinstr8_;
			findStringEntry.kReplBinStr9 = replbinstr9_;
			findStringEntry.kReplBinStr10 = replbinstr10_;

			prefs_["find_prefs"] = findStringEntry;
			
			try {
				var fstr:FileStream = new FileStream();
				fstr.open (prefsFs_, FileMode.WRITE);
				fstr.writeObject (prefs_);
				fstr.close();
			}
			catch (error:Error) {
				//var msg:String = "The configurations settings cannot be saved.\nMessage: ";
				//msg += error.message;
				//Alert.show( msg, "File Error");
			}
		}
		
		public function getXPos():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kXPos != null) {
					return obj.kXPos;
				}
			}
			return -1;
		}
		
		public function getYPos():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kYPos != null) {
					return obj.kYPos;
				}
			}
			return -1;
		}
		
		public function getWidth():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kWidth != null) {
					return obj.kWidth;
				}
			}
			return -1;
		}
		
		public function getHeight():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kHeight != null) {
					return obj.kHeight;
				}
			}
			return -1;
		}
		
		public function setInitPath (path:String):void
		{
			initPath_ = path;
		}
		
		public function setCustomPath1 (path:String):void
		{
			customPath1_ = path;
		}
		
		public function setCustomPath2 (path:String):void
		{
			customPath2_ = path;
		}
		
		public function setImageDimension (w:int, h:int):void
		{
			img_w_ = w;
			img_h_ = h;
		}
		
		public function setTextDimension (w:int, h:int):void
		{
			txt_w_ = w;
			txt_h_ = h;
		}

		public function setTextBinDimension (w:int, h:int):void
		{
			txtbin_w_ = w;
			txtbin_h_ = h;
		}
		
		public function setMemstr1 (s:String):void
		{
			memstr1_ = s;
		}
		
		public function setMemstr2 (s:String):void
		{
			memstr2_ = s;
		}
		
		public function setMemstr3 (s:String):void
		{
			memstr3_ = s;
		}
		
		public function setMemstr4 (s:String):void
		{
			memstr4_ = s;
		}
		
		public function setMemstr5 (s:String):void
		{
			memstr5_ = s;
		}
		
		public function setMemstr6 (s:String):void
		{
			memstr6_ = s;
		}
		
		public function setMemstr7 (s:String):void
		{
			memstr7_ = s;
		}
		
		public function setMemstr8 (s:String):void
		{
			memstr8_ = s;
		}
		
		public function setMemstr9 (s:String):void
		{
			memstr9_ = s;
		}
		
		public function setEditstr1 (s:String):void
		{
			editstr1_ = s;
		}
		
		public function setEditstr2 (s:String):void
		{
			editstr2_ = s;
		}
		
		public function setEditstr3 (s:String):void
		{
			editstr3_ = s;
		}
		
		public function setEditstr4 (s:String):void
		{
			editstr4_ = s;
		}
		
		public function setEditstr5 (s:String):void
		{
			editstr5_ = s;
		}
		
		public function setEditstr6 (s:String):void
		{
			editstr6_ = s;
		}
		
		public function setEditstr7 (s:String):void
		{
			editstr7_ = s;
		}
		
		public function setEditstr8 (s:String):void
		{
			editstr8_ = s;
		}
		
		public function setEditstr9 (s:String):void
		{
			editstr9_ = s;
		}
		
		
		// =======================		
		
		public function readImageWidth():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kImgWidth != null) {
					return obj.kImgWidth;
				}
			}
			return 40;
		}
		
		public function readImageHeight():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kImgHeight != null) {
					return obj.kImgHeight;
				}
			}
			return 40;
		}
		
		public function getImageWidth():int
		{
			return img_w_;
		}
		
		public function getImageHeight():int
		{
			return img_h_;
		}
		
		public function getTextWidth():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kTxtWidth != null) {
					return obj.kTxtWidth;
				}
			}
			return 40;
		}
		
		public function getTextHeight():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kTxtHeight != null) {
					return obj.kTxtHeight;
				}
			}
			return 40;
		}
		
		public function getTextBinWidth():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kTxtBinWidth != null) {
					return obj.kTxtBinWidth;
				}
			}
			return 40;
		}
		
		public function getTextBinHeight():int
		{
			var obj:Object = prefs_["ui_position"];
			if (obj != null) {
				if (obj.kTxtBinHeight != null) {
					return obj.kTxtBinHeight;
				}
			}
			return 40;
		}
		
		public function getInitPath():String
		{
			var obj:Object = prefs_["path_prefs"];
			if (obj != null) {
				if (obj.kInitPath != null) {
					return obj.kInitPath;
				}
			}
			return "";
		}
		
		public function readCustomPath1():String
		{
			var obj:Object = prefs_["path_prefs"];
			if (obj != null) {
				if (obj.kCustomPath != null) {
					return obj.kCustomPath;
				}
			}
			return "";
		}
		
		public function readCustomPath2():String
		{
			var obj:Object = prefs_["path_prefs"];
			if (obj != null) {
				if (obj.kCustomPath2 != null) {
					return obj.kCustomPath2;
				}
			}
			return "";
		}
		
		public function getCustomPath1():String
		{
			return customPath1_;
		}
		
		public function getCustomPath2():String
		{
			return customPath2_;
		}
		
		// ==============
		
		private function readAllMemstr():String
		{
			var obj:Object = prefs_["string_prefs"];
			if (obj != null) {
				if (obj.kMemstr1 != null) {
					memstr1_ = obj.kMemstr1;
				}
				if (obj.kMemstr2 != null) {
					memstr2_ = obj.kMemstr2;
				}
				if (obj.kMemstr3 != null) {
					memstr3_ = obj.kMemstr3;
				}
				if (obj.kMemstr4 != null) {
					memstr4_ = obj.kMemstr4;
				}
				if (obj.kMemstr5!= null) {
					memstr5_ = obj.kMemstr5;
				}
				if (obj.kMemstr6 != null) {
					memstr6_ = obj.kMemstr6;
				}
				if (obj.kMemstr7 != null) {
					memstr7_ = obj.kMemstr7;
				}
				if (obj.kMemstr8 != null) {
					memstr8_ = obj.kMemstr8;
				}
				if (obj.kMemstr9 != null) {
					memstr9_ = obj.kMemstr9;
				}
				if (obj.kEditstr1 != null) {
					editstr1_ = obj.kEditstr1;
				}
				if (obj.kEditstr2 != null) {
					editstr2_ = obj.kEditstr2;
				}
				if (obj.kEditstr3 != null) {
					editstr3_ = obj.kEditstr3;
				}
				if (obj.kEditstr4 != null) {
					editstr4_ = obj.kEditstr4;
				}
				if (obj.kEditstr5 != null) {
					editstr5_ = obj.kEditstr5;
				}
				if (obj.kEditstr6 != null) {
					editstr6_ = obj.kEditstr6;
				}
				if (obj.kEditstr7 != null) {
					editstr7_ = obj.kEditstr7;
				}
				if (obj.kEditstr8 != null) {
					editstr8_ = obj.kEditstr8;
				}
				if (obj.kEditstr9 != null) {
					editstr9_ = obj.kEditstr9;
				}
			}
			return "";
		}
		
		public function getMemstr1():String
		{
			return memstr1_;
		}
		
		public function getMemstr2():String
		{
			return memstr2_;
		}
		
		public function getMemstr3():String
		{
			return memstr3_;
		}
		
		public function getMemstr4():String
		{
			return memstr4_;
		}
		
		public function getMemstr5():String
		{
			return memstr5_;
		}
		
		public function getMemstr6():String
		{
			return memstr6_;
		}
		
		public function getMemstr7():String
		{
			return memstr7_;
		}
		
		public function getMemstr8():String
		{
			return memstr8_;
		}
		
		public function getMemstr9():String
		{
			return memstr9_;
		}
		
		public function getEditstr1():String
		{
			return editstr1_;
		}
		
		public function getEditstr2():String
		{
			return editstr2_;
		}
		
		public function getEditstr3():String
		{
			return editstr3_;
		}
		
		public function getEditstr4():String
		{
			return editstr4_;
		}
		
		public function getEditstr5():String
		{
			return editstr5_;
		}
		
		public function getEditstr6():String
		{
			return editstr6_;
		}
		
		public function getEditstr7():String
		{
			return editstr7_;
		}
		
		public function getEditstr8():String
		{
			return editstr8_;
		}
		
		public function getEditstr9():String
		{
			return editstr9_;
		}
		
		private function readFindStr():void
		{
			var obj:Object = prefs_["find_prefs"];
			if (obj != null) {
				if (obj.kFindStr1 != null) {
					findstr1_ = obj.kFindStr1;
					findstr2_ = obj.kFindStr2;
					findstr3_ = obj.kFindStr3;
					findstr4_ = obj.kFindStr4;
					findstr5_ = obj.kFindStr5;
					findstr6_ = obj.kFindStr6;
					findstr7_ = obj.kFindStr7;
					findstr8_ = obj.kFindStr8;
					findstr9_ = obj.kFindStr9;
					findstr10_ = obj.kFindStr10;
					replstr1_ = obj.kReplStr1;
					replstr2_ = obj.kReplStr2;
					replstr3_ = obj.kReplStr3;
					replstr4_ = obj.kReplStr4;
					replstr5_ = obj.kReplStr5;
					replstr6_ = obj.kReplStr6;
					replstr7_ = obj.kReplStr7;
					replstr8_ = obj.kReplStr8;
					replstr9_ = obj.kReplStr9;
					replstr10_ = obj.kReplStr10;
				}
				if (obj.kFindBinStr1 != null) {
					findbinstr1_ = obj.kFindBinStr1;
					findbinstr2_ = obj.kFindBinStr2;
					findbinstr3_ = obj.kFindBinStr3;
					findbinstr4_ = obj.kFindBinStr4;
					findbinstr5_ = obj.kFindBinStr5;
					findbinstr6_ = obj.kFindBinStr6;
					findbinstr7_ = obj.kFindBinStr7;
					findbinstr8_ = obj.kFindBinStr8;
					findbinstr9_ = obj.kFindBinStr9;
					findbinstr10_ = obj.kFindBinStr10;
					replbinstr1_ = obj.kReplBinStr1;
					replbinstr2_ = obj.kReplBinStr2;
					replbinstr3_ = obj.kReplBinStr3;
					replbinstr4_ = obj.kReplBinStr4;
					replbinstr5_ = obj.kReplBinStr5;
					replbinstr6_ = obj.kReplBinStr6;
					replbinstr7_ = obj.kReplBinStr7;
					replbinstr8_ = obj.kReplBinStr8;
					replbinstr9_ = obj.kReplBinStr9;
					replbinstr10_ = obj.kReplBinStr10;
				}
			}
		}
		
		public function getFindStrings():Array
		{
			var retval:Array = new Array();
			if (findstr1_.length > 0) {
				retval.push (findstr1_);
			}
			if (findstr2_.length > 0) {
				retval.push (findstr2_);
			}
			if (findstr3_.length > 0) {
				retval.push (findstr3_);
			}
			if (findstr4_.length > 0) {
				retval.push (findstr4_);
			}
			if (findstr5_.length > 0) {
				retval.push (findstr5_);
			}
			if (findstr6_.length > 0) {
				retval.push (findstr6_);
			}
			if (findstr7_.length > 0) {
				retval.push (findstr7_);
			}
			if (findstr8_.length > 0) {
				retval.push (findstr8_);
			}
			if (findstr9_.length > 0) {
				retval.push (findstr9_);
			}
			if (findstr10_.length > 0) {
				retval.push (findstr10_);
			}
			return retval;
		}

		public function getReplaceStrings():Array
		{
			var retval:Array = new Array();
			if (replstr1_.length > 0) {
				retval.push (replstr1_);
			}
			if (replstr2_.length > 0) {
				retval.push (replstr2_);
			}
			if (replstr3_.length > 0) {
				retval.push (replstr3_);
			}
			if (replstr4_.length > 0) {
				retval.push (replstr4_);
			}
			if (replstr5_.length > 0) {
				retval.push (replstr5_);
			}
			if (replstr6_.length > 0) {
				retval.push (replstr6_);
			}
			if (replstr7_.length > 0) {
				retval.push (replstr7_);
			}
			if (replstr8_.length > 0) {
				retval.push (replstr8_);
			}
			if (replstr9_.length > 0) {
				retval.push (replstr9_);
			}
			if (replstr10_.length > 0) {
				retval.push (replstr10_);
			}
			return retval;
		}
		
		public function setFindStrings (str:Array):void
		{
			for (var ix:int = 0; ix < str.length; ix++) {
				switch (ix) {
					case 0: findstr1_ = str[ix];
						break;
					case 1: findstr2_ = str[ix];
						break;
					case 2: findstr3_ = str[ix];
						break;
					case 3: findstr4_ = str[ix];
						break;
					case 4: findstr5_ = str[ix];
						break;
					case 5: findstr6_ = str[ix];
						break;
					case 6: findstr7_ = str[ix];
						break;
					case 7: findstr8_ = str[ix];
						break;
					case 8: findstr9_ = str[ix];
						break;
					case 9: findstr10_ = str[ix];
						break;
				}
			}
		}
		
		public function setReplaceStrings (str:Array):void
		{
			for (var ix:int = 0; ix < str.length; ix++) {
				switch (ix) {
					case 0: replstr1_ = str[ix];
						break;
					case 1: replstr2_ = str[ix];
						break;
					case 2: replstr3_ = str[ix];
						break;
					case 3: replstr4_ = str[ix];
						break;
					case 4: replstr5_ = str[ix];
						break;
					case 5: replstr6_ = str[ix];
						break;
					case 6: replstr7_ = str[ix];
						break;
					case 7: replstr8_ = str[ix];
						break;
					case 8: replstr9_ = str[ix];
						break;
					case 9: replstr10_ = str[ix];
						break;
				}
			}
		}
		

	
	
		public function getFindBinStrings():Array
		{
			var retval:Array = new Array();
			if (findbinstr1_.length > 0) {
				retval.push (findbinstr1_);
			}
			if (findbinstr2_.length > 0) {
				retval.push (findbinstr2_);
			}
			if (findbinstr3_.length > 0) {
				retval.push (findbinstr3_);
			}
			if (findbinstr4_.length > 0) {
				retval.push (findbinstr4_);
			}
			if (findbinstr5_.length > 0) {
				retval.push (findbinstr5_);
			}
			if (findbinstr6_.length > 0) {
				retval.push (findbinstr6_);
			}
			if (findbinstr7_.length > 0) {
				retval.push (findbinstr7_);
			}
			if (findbinstr8_.length > 0) {
				retval.push (findbinstr8_);
			}
			if (findbinstr9_.length > 0) {
				retval.push (findbinstr9_);
			}
			if (findbinstr10_.length > 0) {
				retval.push (findbinstr10_);
			}
			return retval;
		}
		
		public function getReplaceBinStrings():Array
		{
			var retval:Array = new Array();
			if (replbinstr1_.length > 0) {
				retval.push (replbinstr1_);
			}
			if (replbinstr2_.length > 0) {
				retval.push (replbinstr2_);
			}
			if (replbinstr3_.length > 0) {
				retval.push (replbinstr3_);
			}
			if (replbinstr4_.length > 0) {
				retval.push (replbinstr4_);
			}
			if (replbinstr5_.length > 0) {
				retval.push (replbinstr5_);
			}
			if (replbinstr6_.length > 0) {
				retval.push (replbinstr6_);
			}
			if (replbinstr7_.length > 0) {
				retval.push (replbinstr7_);
			}
			if (replbinstr8_.length > 0) {
				retval.push (replbinstr8_);
			}
			if (replbinstr9_.length > 0) {
				retval.push (replbinstr9_);
			}
			if (replbinstr10_.length > 0) {
				retval.push (replbinstr10_);
			}
			return retval;
		}
		
		public function setFindBinStrings (str:Array):void
		{
			for (var ix:int = 0; ix < str.length; ix++) {
				switch (ix) {
					case 0: findbinstr1_ = str[ix];
						break;
					case 1: findbinstr2_ = str[ix];
						break;
					case 2: findbinstr3_ = str[ix];
						break;
					case 3: findbinstr4_ = str[ix];
						break;
					case 4: findbinstr5_ = str[ix];
						break;
					case 5: findbinstr6_ = str[ix];
						break;
					case 6: findbinstr7_ = str[ix];
						break;
					case 7: findbinstr8_ = str[ix];
						break;
					case 8: findbinstr9_ = str[ix];
						break;
					case 9: findbinstr10_ = str[ix];
						break;
				}
			}
		}
		
		public function setReplaceBinStrings (str:Array):void
		{
			for (var ix:int = 0; ix < str.length; ix++) {
				switch (ix) {
					case 0: replbinstr1_ = str[ix];
						break;
					case 1: replbinstr2_ = str[ix];
						break;
					case 2: replbinstr3_ = str[ix];
						break;
					case 3: replbinstr4_ = str[ix];
						break;
					case 4: replbinstr5_ = str[ix];
						break;
					case 5: replbinstr6_ = str[ix];
						break;
					case 6: replbinstr7_ = str[ix];
						break;
					case 7: replbinstr8_ = str[ix];
						break;
					case 8: replbinstr9_ = str[ix];
						break;
					case 9: replbinstr10_ = str[ix];
						break;
				}
			}
		}

	}
	
}