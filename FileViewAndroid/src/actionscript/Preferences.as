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
				}
				else {
					prefs_ = new Object();
				}
			}
			catch (error:Error) {
			}
		}
		
		public function save ():void
		{
			var stringEntry:Object = new Object();
			stringEntry.kInitPath = initPath_;
			stringEntry.kCustomPath1 = customPath1_;
			stringEntry.kCustomPath2 = customPath2_;
			prefs_["path_prefs"] = stringEntry;

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
		
		// =======================		
		
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
				if (obj.kCustomPath1 != null) {
					return obj.kCustomPath1;
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
		
	}

}