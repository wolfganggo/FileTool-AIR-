// ActionScript file

package actionscript
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	//=======================================================

	public class Utilities
	{
		static public var isReadingFile_:Boolean = false;
		static private var numFrames_:uint = 0;
		static public var log_:String = "no entry";
			
			
		//=======================================================
		// A string that contains a list of strings separated by line ends
		// is converted to an array
		static public function convertStringToList( argStr:String):Array
		{
			var startIx:Number = 0;
			var endIx:Number = 0;
			var inStr:String = argStr;
			var str:String = "";
			var retArray:Array = new Array();
			
			do {
				endIx = inStr.search( '\n');
				if( endIx == -1) {
					endIx = inStr.search( '\r');
				}
				if( endIx < inStr.length && endIx >= 0) {
					str = inStr.substring(startIx, endIx);
					if( endIx + 1 < inStr.length) {
						inStr = inStr.substring( endIx + 1);
					}
					else {
						inStr = "";
					}
				}
				else {
					str = inStr;
					inStr = "";
				}
				retArray.push( str);
				
			} while( inStr.length > 0);
			
			return retArray;
		}
		
		//=======================================================
		
		static public function ReadJSFileContent( path:String, filename:String):String
		{
			var filePath:String = path + filename;
			var s:String = "";
			try {
				var file:File = new File( filePath);
				var len:Number = file.size;
				if( len == 0 || len > 10000) {
					//Alert.show( "This file is not valid.", "JS File Error");
					return "";
				}
				var fstr:FileStream = new FileStream();
				fstr.open( file, FileMode.READ);
				s = fstr.readMultiByte( len, "iso-8859-1");
				fstr.close();
			}
			catch( e:Error) {
				var msg:String = "Exception caught when reading JavaScript file:\n";
				msg += path;
				msg += filename;
				//Alert.show( msg, "JS File Error");
			}
			return s;
		}
		
		//=======================================================
		static public function logDebug (msg:String):void
		{
			if (log_.length == 8) {
				if (log_ == "no entry") {
					log_ = "";
				}
			}
			log_ += msg + "\n";
		}
		
		static public function WriteToDebugLogFile (msg:String):void
		{
			// Set this to false in Debug mode, only temporary
			if (true) {
				return;
			}
			var logFs:File = new File;
			try {
				var dt:Date = new Date;
				var curMsg:String = dt.toLocaleTimeString();
				curMsg += ",";
				var ms:String = String(dt.getMilliseconds());
				if( ms.length < 2) {
					ms = "00" + ms;
				}
				else if( ms.length < 3) {
					ms = "0" + ms;
				}
				curMsg += ms + "  " + msg + "\n";
				logFs = File.applicationStorageDirectory;
				logFs = logFs.resolvePath("debug/");
				logFs.createDirectory();
				logFs = logFs.resolvePath("log.txt");
				var fstr:FileStream = new FileStream();
				fstr.open( logFs, FileMode.APPEND);
				fstr.writeUTFBytes( curMsg);
				fstr.close();
			}
			catch( e:Error) {
				//Alert.show( "Exception caught when writing logfile", "Log File Error");
			}
		}
	}
}

//=======================================================
/*
\history

WGo-2015-02-04: created

*/

