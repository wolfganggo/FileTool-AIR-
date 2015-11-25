// ActionScript file

package actionscript
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	
	
	//=======================================================

	public class Utilities
	{
		static public var wavechunk_1:ByteArray = null;
		//static public var wavechunk_2:ByteArray = null;
		static private var waveContainer_:Array = null;
		static private var readingChunk1_:Boolean = true;
		static private var fsReadWave:FileStream = null;
		static private var waveFilePosition_:uint = 0;
		static private var waveFileSize_:uint = 0;
		static private var waveTotalBytes_:uint = 0;
		static private var waveSize_:uint = 0;
		static private var waveStart_:uint = 0;
		static private var waveDataFormat_:uint = 0;
		static private var waveBlockSize_:uint = 0;
		static public var waveNumChannels_:uint = 0;
		static public var waveBitsPerSample_:uint = 0;
		static public var waveSampleRate_:uint = 0;
		static public var isReadingFile_:Boolean = false;
		static public var waveSizeMilliSecs_:uint = 0;
		static public var waveChunkUsed_:uint = 0;
		static private var numFrames_:uint = 0; // internal use for AIFF
		static private var firstBytes_:Array = null;
		static private var wave96PosMicroSec_:uint = 0;
		static private var wave44Pos_:uint = 0;
		static private var wave96LastVal1_:int = 0;
		static private var wave96LastVal2_:int = 0;
		
		static private var debugFs:FileStream = null;

		
		static public function ConvertToAscii (isCString:Boolean, isBreak:Boolean, isSpace:Boolean, path:String):void
		{
			var file:File = new File( path);
			if( file.isDirectory) {
				return;
			}
			try {
				//var ext:String = file.extension;
				//var jobContent:String = "";
				var curLine:String = "";
				var fstr:FileStream = new FileStream();
				fstr.open( file, FileMode.READ);
				var len:Number = file.size;
				if( len == 0 || len > 1000000000) { // max. 1 GB => duration ca 20 min on Mac Mini 2011, 2 GHz
					Alert.show( "This file cannot be processed.", "Import Error", Alert.OK);
					fstr.close();
					return;
				}

				var newName:String = file.nativePath;
				newName += ".binhex";
				var targetFs:File = new File( newName);
				var target:FileStream = new FileStream();
				target.open( targetFs, FileMode.WRITE);
				
				if (isCString) {
					//jobContent += "{\n";
					target.writeMultiByte ("{\n", "iso-8859-1");
				}

				var ix:uint = 0;
				do {
					var b:uint = fstr.readUnsignedByte();
					var s:String = b.toString(16);
					if( s.length == 1) {
						s = "0" + s;
					}
					if (isSpace) {
						curLine += " ";
					}
					curLine += s;
					ix++;
					if (ix % 8 == 0 && isSpace) {
						curLine += " ";
					}
					if (ix % 48 == 0) {
						if (isCString) {
							curLine = "\"" + curLine + "\",\n";
						}
						else if (isBreak) {
							curLine += "\n";
						}
						//jobContent += curLine;
						target.writeMultiByte (curLine, "iso-8859-1");
						curLine = "";
					}
				}
				while( fstr.bytesAvailable > 0);
				
				if( curLine.length > 0) {
					if (isCString) {
						curLine = "\"" + curLine + "\",\n";
					}
					//jobContent += curLine;
					target.writeMultiByte (curLine, "iso-8859-1");
				}
				
				if (isCString) {
					//jobContent += "}";
					target.writeMultiByte ("}", "iso-8859-1");
				}
				
				fstr.close();
				
				//target.writeUTF( jobContent);
				//target.writeMultiByte( jobContent, "iso-8859-1");
				//		target.writeObject( conf_);
				target.close();
			}
			catch( error:Error) {
				var msg:String = "Cannot read or write file !";
				Alert.show( msg, "Error", Alert.OK);
			}
		}
		
		static public function ConvertFromAscii (path:String):void
		{
			var file:File = new File (path);
			if (file.isDirectory) {
				return;
			}
			try {
				//var ext:String = file.extension;
				var jobContent:String = "";
				var curLine:String = "";
				var fstr:FileStream = new FileStream();
				fstr.open (file, FileMode.READ);
				var len:Number = file.size;
				if (len == 0 || len > 3300000000) { // max. 3 GB
					Alert.show ("This file cannot be processed.", "Import Error", Alert.OK);
					fstr.close();
					return;
				}

				var newName:String = file.nativePath;
				var oldLen:Number = newName.length;
				if (oldLen > 9) {
					newName = newName.substr (0, oldLen - 7); // remove ".binhex"
				}
				
				var targetFs:File = new File (newName);
				if (targetFs.exists) {
					newName += "_1";
					targetFs = new File (newName);
				}
				var target:FileStream = new FileStream();
				target.open (targetFs, FileMode.WRITE);

				var chars:String = "";
				var char1:uint = 0;
				var hasChar1:Boolean = false;
				do {
					var b:uint = fstr.readUnsignedByte();
					if (b < 48 || b > 102) {
						continue;
					}
					if (!hasChar1) {
						char1 = b;
						hasChar1 = true;
					}
					else {
						var newbyte:int = getByteFromHex (char1, b);
						//target.writeUnsignedInt (newbyte);
						target.writeByte (newbyte);
						hasChar1 = false;
					}
				}
				while (fstr.bytesAvailable > 0);

				fstr.close();
				target.close();
			}
			catch (error:Error) {
				var msg:String = "Cannot read or write file !";
				Alert.show( msg, "Error", Alert.OK);
			}
		}
		
		static private function getByteFromHex (b1:uint, b2:uint):uint
		{
			var bt:uint = 0;
			if (b2 > 47 && b2 < 58) {
				bt = b2 - 48;
			}
			else if (b2 > 64 && b2 < 71) {
				bt = b2 - 55;
			}
			else if (b2 > 96 && b2 < 103) {
				bt = b2 - 87;
			}
			
			if (b1 > 47 && b1 < 58) {
				bt += (b1 - 48) * 16;
			}
			else if (b1 > 64 && b1 < 71) {
				bt += (b1 - 55) * 16;
			}
			else if (b1 > 96 && b1 < 103) {
				bt += (b1 - 87) * 16;
			}
			return bt;
		}

		
		static public function readWaveFile (path:String):uint
		{
			var samples:uint = 0;
			try {
				waveContainer_ = new Array();
				var file:File = new File (path);
				fsReadWave = new FileStream();
				fsReadWave.open (file, FileMode.READ);
				var len:Number = file.size;
				if (len > 0xfffffff0) { // fit to uint
					waveFileSize_ = 0;
					return 0;
				}
				waveFileSize_ = len;
				
				readingChunk1_ = true;
				wavechunk_1 = new ByteArray();
				firstBytes_ = new Array();
				waveTotalBytes_ = 0;
				var record:Array = new Array();
				var curID:String = "";
				var curStart:uint = 0;
				var curLen:uint = 0;
				var curLine:String = "";
				if (len > 2000) { // header length
					len = 2000;
				}
				for (var i:uint = 0; i < len; i++) {
					var b:uint = 0;
					b = fsReadWave.readUnsignedByte();
					record.push (b);
				}
				fsReadWave.position = 0;
				waveFilePosition_ = 0; // position for the next chunk, a step back from the end of the last chunk
					
				var ixHdr:int = 0;
				for (; ixHdr < record.length; ixHdr++) {
					if (record[ixHdr] > 0) {
						curID += String.fromCharCode (record[ixHdr]);
					}
					if (ixHdr == 3) {
						if (curID != "RIFF") {
							return 0;
						}
					}
					if (ixHdr == 7) {
						curID = "";
					}
					if (ixHdr == 11) {
						if (curID == "WAVE") {
							break;
						}
						else {
							return 0;
						}
					}
				}
				waveTotalBytes_ = record[4] + record[5] * 256 + record[6] * 65536 + record[7] * 16777216;
					
				ixHdr++;
				curStart = ixHdr;
				curID = "";
				for (; ixHdr < record.length; ixHdr++) {
					curID += String.fromCharCode (record[ixHdr]);
					if (ixHdr - curStart == 3) {
						curLen = record[curStart + 4] + record[curStart + 5] * 256 + record[curStart + 6] * 65536 + record[curStart + 7] * 16777216;
						if (curID == "fmt ") {
							waveNumChannels_ = record[curStart + 10];
							waveSampleRate_ = record[curStart + 12] + record[curStart + 13] * 256 + record[curStart + 14] * 65536;
							waveBlockSize_ = record[curStart + 20]; // 6 bytes bei 24/96
							waveBitsPerSample_ = record[curStart + 22];
							if (record[curStart + 8] == 254 && record[curStart + 9] == 255) { // extended format
								if (curLen < 40) {
									return 0;
								}
								waveDataFormat_ = record[curStart + 32];
								//waveBitsPerSample_ = record[curStart + 30];
							}
							else {
								waveDataFormat_ = record[curStart + 8];
							}
							if (waveDataFormat_ != 1 || waveBitsPerSample_ < 9 || waveNumChannels_ > 2 ||
								(waveSampleRate_ != 44100 && waveSampleRate_ != 48000 && waveSampleRate_ != 96000) )
							{
								return 0;
							}
							
						}
						else if (curID == "data") {
							waveSize_ = curLen;
							waveStart_ = curStart + 8;

							//trace("readWaveFile(), start of data: " + waveStart_);

							if (waveBitsPerSample_ == 16 && waveBlockSize_ == 4 && waveNumChannels_ == 1) {
								waveBlockSize_ = 2;
							}
							waveSizeMilliSecs_ = (waveSize_ * 10) / (waveBlockSize_ * (waveSampleRate_/100));
							fsReadWave.position = waveStart_;
							isReadingFile_ = true;
							samples = readWaveData (fsReadWave, null, true); // chunk 1
							var copy:ByteArray = new ByteArray();
							copy = wavechunk_1;
							waveContainer_.push (copy);
							isReadingFile_ = false;
							//readWaveData (fsReadWave, false);          // chunk 2
							break;
						}
						else {
							// ignored identifier
						}
						ixHdr = curStart + curLen + 7; // 8 - 1 because the loop counter will be incremented
						if ((ixHdr + 1) % 2 != 0) {
							ixHdr++;
						}
						curID = "";
						curStart = ixHdr + 1;
					}
				}
			}
			catch (error:Error) {
				var msg:String = "Cannot read file !";
				Alert.show( msg, "Error", Alert.OK);
			}

			return samples; // of current chunk
		}
		
		static public function readNextWaveChunk():uint
		{
			if (waveFilePosition_ >= waveTotalBytes_) {
				return 0;
			}
			isReadingFile_ = true;
			fsReadWave.position = waveFilePosition_;
			//WriteDebugLogMessage ("readNextWaveChunk() file position is now:" + waveFilePosition_.toString());

			var bytearray:ByteArray = new ByteArray();
			var count:uint = readWaveData (fsReadWave, bytearray, true);
			//copy = wavechunk_2;
			if (count > 0) {
				waveContainer_.push (bytearray);
			}
			
			//WriteDebugLogMessage ("container content is now:");
			//for (var ix:uint = 0; ix < waveContainer_.length; ix++) {
				//WriteDebugLogMessage ("ByteArray: " + ix.toString() + " = " + waveContainer_[ix][0].toString() + "  " + waveContainer_[ix][1].toString() + "  " + waveContainer_[ix][2].toString());
			//}
			isReadingFile_ = false;
			
			return count;
		}

		static private function readWaveData (fs:FileStream, barray:ByteArray, littleEndian:Boolean):uint
		{
			//isReadingFile_ = true;
			var block:Array = new Array();
			var valueSize:uint = waveBlockSize_ / waveNumChannels_;
			var arrayIx:uint = waveBlockSize_;
			var bytesIn1Chunk:uint = 101 * (waveSampleRate_  / 10) * waveBlockSize_; // load 10 sec + 100 ms
			var beginNextChunk:uint = 10 * waveSampleRate_ * waveBlockSize_;
			var val1:Number = 0;
			var val2:Number = 0;
			var maxPos:uint = waveStart_ + waveSize_;
			var omitSample:Boolean = false;
			var omitSample13:Boolean = false;
			var omitSample231:Boolean = false;
			var sample13Cnt:uint = 13;
			var sample231Cnt:uint = 231;
			var sample48kCnt:uint = 0;
			var sample13Delay:uint = 4;
			//var totalSampleCnt:uint = 0;
			var usedSampleCnt:uint = 0;
			
			if (barray == null) {
				wavechunk_1.clear();
			}
			
			//trace("readWaveData(), file position before: " + fs.position);

			var i:uint = 0;
			for ( ; i < bytesIn1Chunk; i++) {
				if (fs.bytesAvailable < 1) {
					waveFilePosition_ = waveTotalBytes_;
					break;
				}
				if (i == beginNextChunk) {
					waveFilePosition_ = fs.position;
				}
				var b:uint = fs.readUnsignedByte();

				block.push(b);
				arrayIx--;
				if (arrayIx == 0) {
					arrayIx = waveBlockSize_;
					if (waveSampleRate_ == 96000) {
						if (omitSample) {
							omitSample = false;
							continue;
						}
						else {
							omitSample = true;
						}
					}
					if (waveSampleRate_ == 96000 || waveSampleRate_ == 48000) { // omit 3900 per second, every 13 (3692 + 208), every 231 (207 + 1)
						sample48kCnt++;
						sample13Cnt--;
						sample231Cnt--;
						if (sample13Cnt == 0) { // latest position 47996
							if (sample231Cnt < 2) {
								sample13Delay = 4;
							}
							sample13Cnt = 13;
							omitSample13 = true;
						}
						if (sample231Cnt == 0) { //latest position  47817
							if (sample13Cnt < 2) {
								sample13Delay = 4;
							}
							sample231Cnt = 231;
							omitSample231 = true;
						}
						if (omitSample13) {
							if (sample13Delay > 0) {
								sample13Delay--;
							}
							else {
								omitSample13 = false;
								continue;
							}
						}
						if (omitSample231) {
							omitSample231 = false;
							continue;
						}
						if (sample48kCnt == 48000) {
							sample48kCnt = 0;
							sample13Cnt = 14;
							sample231Cnt = 232;
							continue;
						}
					}

					var nextix:uint = 2;
					var v1:uint = 0;
					if (littleEndian) {
						if (valueSize == 2) {
							v1 = (block[0] << 16) + (block[1] << 24);
						}
						else {
							v1 = (block[0] << 8) + (block[1] << 16) + (block[2] << 24);
							nextix = 3;
						}
						val1 = int(v1) / 2147483648.0;
						if (waveNumChannels_ == 1) {
							val2 = val1;
						}
						else {
							if (valueSize == 2) {
								v1 = (block[nextix] << 16) + (block[nextix + 1] << 24);
							}
							else {
								v1 = (block[nextix + 0] << 8) + (block[nextix + 1] << 16) + (block[nextix + 2] << 24);
							}
							val2 = int(v1) / 2147483648.0;
						}
					}
					else {
						if (valueSize == 2) {
							v1 = (block[0] << 24) + (block[1] << 16);
						}
						else {
							v1 = (block[0] << 24) + (block[1] << 16) + (block[2] << 8);
							nextix = 3;
						}
						val1 = int(v1) / 2147483648.0;
						if (waveNumChannels_ == 1) {
							val2 = val1;
						}
						else {
							if (valueSize == 2) {
								v1 = (block[nextix] << 24) + (block[nextix + 1] << 16);
							}
							else {
								v1 = (block[nextix + 0] << 24) + (block[nextix + 1] << 16) + (block[nextix + 2] << 8);
							}
							val2 = int(v1) / 2147483648.0;
						}
					}
					block.length = 0;
					if (barray == null) {
						wavechunk_1.writeFloat (val1);
						wavechunk_1.writeFloat (val2);
					}
					else {
						barray.writeFloat (val1);
						barray.writeFloat (val2);
					}
				}
			}
			//trace("readWaveData(), counter after ready: " + i);
			//trace("readWaveData(), waveFilePosition_ after: " + waveFilePosition_);
			//totalSampleCnt = i / valueSize;
			if (barray == null) {
				wavechunk_1.position = 0;
				usedSampleCnt = wavechunk_1.length / 8; // 4 bytes, 2 values
			}
			else {
				barray.position = 0;
				usedSampleCnt = barray.length / 8;
			}
			//isReadingFile_ = false;
			return usedSampleCnt; // number of samples
		}
		
		// works only for continous playing
		static public function getNextDataFromWave (position:uint):uint
		{
			var index:uint = position / 10000;
			if (index < waveContainer_.length) {
				waveChunkUsed_ = index;
				wavechunk_1 = waveContainer_[index];
				return wavechunk_1.length / 8;
			}
			else {
				return 0;
			}
		}
		
		static public function getWaveDataAtPosition (position:uint, littleEndian:Boolean):Object
		{
			var index:uint = position / 10000;
			var count:uint = 0;
			isReadingFile_ = true;
			var result:Object = new Object();
			//trace("getWaveDataAtPosition, index = " + index);
			//trace("getWaveDataAtPosition, container size = " + waveContainer_.length);
			
			
			if (index < waveContainer_.length) {
				//wavechunk_1 = waveContainer_[index];
				//result.kWave = waveContainer_[index];
				//result.kCount = waveContainer_[index].length / 8;
				count = waveContainer_[index].length / 8;
			}
			else {
				do {
					fsReadWave.position = waveFilePosition_;
					var bytearray:ByteArray = new ByteArray();
					count = readWaveData (fsReadWave, bytearray, littleEndian);
					//trace("getWaveDataAtPosition readWaveData, count = " +  count);
					if (count > 0) {
						waveContainer_.push (bytearray);
					}
					else {
						break;
					}
				} while (waveContainer_.length <= index);

			}
			if (count > 0) {
				waveChunkUsed_ = index;
				//wavechunk_1 = waveContainer_[index];
				result.kWave = waveContainer_[index];
				result.kWave.position = 0;
			}
			result.kCount = count;
			isReadingFile_ = false;
			return result;
		}
		
		static public function initializeWave():void
		{
			if (wavechunk_1 != null) {
				wavechunk_1.clear();
			}
			readingChunk1_ = true;
			waveFilePosition_ = 0;
			waveFileSize_ = 0;
			waveTotalBytes_ = 0;
			waveSize_ = 0;
			waveStart_ = 0;
			waveDataFormat_ = 0;
			waveNumChannels_ = 0;
			waveBitsPerSample_ = 0;
			waveSampleRate_ = 0;
			waveBlockSize_ = 0;
			isReadingFile_ = false;
			waveSizeMilliSecs_ = 0;
			waveChunkUsed_ = 0;
		}
		
		static public function getNumWaveChunksAvailable():uint
		{
			if (waveContainer_ != null) {
				return waveContainer_.length;
			}
			return 0;
		}
		
		
		//=======================================================

		static public function readAiffFile (path:String):uint
		{
			var samples:uint = 0;
			try {
				waveContainer_ = new Array();
				var file:File = new File (path);
				fsReadWave = new FileStream();
				fsReadWave.open (file, FileMode.READ);
				var len:Number = file.size;
				if (len > 0xfffffff0) { // fit to uint
					waveFileSize_ = 0;
					return 0;
				}
				waveFileSize_ = len;
				
				readingChunk1_ = true;
				wavechunk_1 = new ByteArray();
				waveTotalBytes_ = 0;
				var record:Array = new Array();
				var curID:String = "";
				var curStart:uint = 0;
				var curLen:uint = 0;
				var curLine:String = "";
				if (len > 2000) { // header length
					len = 2000;
				}
				for (var i:uint = 0; i < len; i++) {
					var b:uint = 0;
					b = fsReadWave.readUnsignedByte();
					record.push (b);
				}
				fsReadWave.position = 0;
				waveFilePosition_ = 0; // position for the next chunk, a step back from the end of the last chunk
				
				var ixHdr:int = 0;
				for (; ixHdr < record.length; ixHdr++) {
					if (record[ixHdr] > 0) {
						curID += String.fromCharCode (record[ixHdr]);
					}
					if (ixHdr == 3) {
						if (curID != "FORM") {
							return 0;
						}
					}
					if (ixHdr == 7) {
						curID = "";
					}
					if (ixHdr == 11) {
						if (curID == "AIFF") {
							break;
						}
						else {
							return 0;
						}
					}
				}
				waveTotalBytes_ = record[7] + record[6] * 256 + record[5] * 65536 + record[4] * 16777216;
				
				ixHdr++;
				curStart = ixHdr;
				curID = "";
				for (; ixHdr < record.length; ixHdr++) {
					curID += String.fromCharCode (record[ixHdr]);
					if (ixHdr - curStart == 3) {
						curLen = record[curStart + 7] + record[curStart + 6] * 256 + record[curStart + 5] * 65536 + record[curStart + 4] * 16777216;
						if (curID == "COMM") {
							waveNumChannels_ = record[curStart + 9];
							numFrames_ = record[curStart + 13] + record[curStart + 12] * 256 + record[curStart + 11] * 65536 + record[curStart + 10] * 16777216;
							waveBitsPerSample_ = record[curStart + 15];
							var sRateExp:int = record[curStart + 17] + record[curStart + 16] * 256;
							var sRateF:int = (sRateExp == 16398 ? 1 : (sRateExp == 16399 ? 2 : 4));
							waveSampleRate_ = (record[curStart + 19] + record[curStart + 18] * 256) * sRateF;

							if (waveBitsPerSample_ < 9 || waveNumChannels_ > 2 ||
								(waveSampleRate_ != 44100 && waveSampleRate_ != 48000 && waveSampleRate_ != 96000) )
							{
								return 0;
							}
							
						}
						else if (curID == "SSND") {
							waveSize_ = curLen;
							waveStart_ = curStart + 16;
							waveBlockSize_ = curLen / numFrames_;
							var offset:uint = record[curStart + 11] + record[curStart + 10] * 256 + record[curStart + 9] * 65536 + record[curStart + 8] * 16777216;
							var blocksize:uint = record[curStart + 15] + record[curStart + 14] * 256 + record[curStart + 13] * 65536 + record[curStart + 12] * 16777216;
							if (offset > 0 || blocksize > 0) {
								return 0; // could be supported later
							}
							waveSizeMilliSecs_ = (waveSize_ * 10) / (waveBlockSize_ * (waveSampleRate_/100));
							fsReadWave.position = waveStart_;
							isReadingFile_ = true;
							samples = readWaveData (fsReadWave, null, false); // chunk 1
							var copy:ByteArray = new ByteArray();
							copy = wavechunk_1;
							waveContainer_.push (copy);
							isReadingFile_ = false;
							break;
						}
						else {
							// ignored identifier
						}
						ixHdr = curStart + curLen + 7; // 8 - 1 because the loop counter will be incremented
						if ((ixHdr + 1) % 2 != 0) {
							ixHdr++;
						}
						curID = "";
						curStart = ixHdr + 1;
					}
				}
			}
			catch (error:Error) {
				var msg:String = "Cannot read file !";
				Alert.show( msg, "Error", Alert.OK);
			}
			
			return samples;
		}
		
		static public function readNextAiffChunk():uint
		{
			if (waveFilePosition_ >= waveTotalBytes_) {
				return 0;
			}
			isReadingFile_ = true;
			fsReadWave.position = waveFilePosition_;
			
			var bytearray:ByteArray = new ByteArray();
			var count:uint = readWaveData (fsReadWave, bytearray, false);
			if (count > 0) {
				waveContainer_.push (bytearray);
			}
			isReadingFile_ = false;
			
			return count;
		}
		

		
		//=======================================================
		
		static public function editWaveFile (path:String,
											 begin:int, length:int,
											 normalize:Boolean, swap:Boolean, convert44:Boolean,
											 fadeInLength:int, fadeOutLength:int):uint
		{
			wave96PosMicroSec_ = 0;
			wave44Pos_ = 0;
			wave96LastVal1_ = 0;
			wave96LastVal2_ = 0;
			var samples:uint = 0;
			var waveTotalBytes:uint = 0;
			var waveSize:uint = 0;
			var waveStart:uint = 0;
			var waveDataFormat:uint = 0;
			var waveBlockSize:uint = 0;
			var waveNumChannels:uint = 0;
			var waveBitsPerSample:uint = 0;
			var waveSampleRate:uint = 0;
			try {
				var file:File = new File (path);
				var fsWave:FileStream = new FileStream();
				fsWave.open (file, FileMode.READ);
				var len:Number = file.size;
				if (len > 0xfffffff0) {
					waveFileSize_ = 0;
					return 0;
				}
				var record:Array = new Array();
				var curID:String = "";
				var curStart:uint = 0;
				var curLen:uint = 0;
				var curLine:String = "";
				if (len > 2000) {
					len = 2000;
				}
				for (var i:uint = 0; i < len; i++) {
					var b:uint = 0;
					b = fsWave.readUnsignedByte();
					record.push (b);
				}
				
				var ixHdr:int = 0;
				for (; ixHdr < record.length; ixHdr++) {
					if (record[ixHdr] > 0) {
						curID += String.fromCharCode (record[ixHdr]);
					}
					if (ixHdr == 3) {
						if (curID != "RIFF") {
							return 0;
						}
					}
					if (ixHdr == 7) {
						curID = "";
					}
					if (ixHdr == 11) {
						if (curID == "WAVE") {
							break;
						}
						else {
							return 0;
						}
					}
				}
				waveTotalBytes = record[4] + record[5] * 256 + record[6] * 65536 + record[7] * 16777216;
				
				ixHdr++;
				curStart = ixHdr;
				curID = "";
				for (; ixHdr < record.length; ixHdr++) {
					curID += String.fromCharCode (record[ixHdr]);
					if (ixHdr - curStart == 3) {
						curLen = record[curStart + 4] + record[curStart + 5] * 256 + record[curStart + 6] * 65536 + record[curStart + 7] * 16777216;
						if (curID == "fmt ") {
							waveNumChannels = record[curStart + 10];
							waveSampleRate = record[curStart + 12] + record[curStart + 13] * 256 + record[curStart + 14] * 65536;
							waveBlockSize = record[curStart + 20]; // 6 bytes bei 24/96
							waveBitsPerSample = record[curStart + 22];
							if (record[curStart + 8] == 254 && record[curStart + 9] == 255) { // extended format
								if (curLen < 40) {
									return 0;
								}
								waveDataFormat = record[curStart + 32];
								//waveBitsPerSample_ = record[curStart + 30];
							}
							else {
								waveDataFormat = record[curStart + 8];
							}
							if (waveDataFormat != 1 || waveBitsPerSample < 9 || waveNumChannels > 2 ||
								(waveSampleRate != 44100 && waveSampleRate != 48000 && waveSampleRate != 96000) )
							{
								return 0;
							}
						}
						else if (curID == "data") {
							waveSize = curLen;
							waveStart = curStart + 8;
							if (waveBitsPerSample == 16 && waveBlockSize == 4 && waveNumChannels == 1) {
								waveBlockSize = 2;
							}
							//fsWave.position = waveStart;
							break;
						}
						else {
							// ignored identifier
						}
						ixHdr = curStart + curLen + 7; // 8 - 1 because the loop counter will be incremented
						if ((ixHdr + 1) % 2 != 0) {
							ixHdr++;
						}
						curID = "";
						curStart = ixHdr + 1;
					}
				}
				
				var begSample:uint = begin * waveSampleRate / 1000;
				var begByte:uint = begSample * waveBlockSize;
				var lenSample:uint = length * waveSampleRate / 1000;
				var totalSamples:uint = waveSize / waveBlockSize;
				if (begSample >= totalSamples) {
					return 0;
				}
				if (begSample + lenSample > totalSamples || lenSample == 0) {
					lenSample = totalSamples - begSample;
				}
				var afterLastByte:uint = begByte + lenSample * waveBlockSize;
				var beginFadeOutByte:uint = afterLastByte;
				var lenFadeOutBytes:uint = fadeOutLength * waveSampleRate * waveBlockSize;
				if (lenFadeOutBytes < afterLastByte && fadeOutLength > 0) {
					beginFadeOutByte = afterLastByte - lenFadeOutBytes;
				}
				var lenFadeInBytes:uint = fadeInLength * waveSampleRate * waveBlockSize;
				var peak:uint = 0;
				var amp:Number = 1.0;
				if (normalize) {
					peak = findPeakValue (fsWave, waveStart, waveSize, waveNumChannels, waveBlockSize / waveNumChannels, waveSampleRate);
					amp = 2147483380 / peak;  // in 32 bit signed format, 2147483647 is max
					if (amp < 1) {
						amp = 1.0;
					}
				}
				var outBlockSize:uint = waveBlockSize;
				var outBitsPerSample:uint = waveBitsPerSample;
				var outSampleRate:uint = waveSampleRate;
				var outLenSamples:uint = lenSample;

				if (convert44 && waveSampleRate != 96000) {
					convert44 = false;
				}
				if (convert44) {
					outBlockSize = waveNumChannels * 2;
					outBitsPerSample = 16;
					outSampleRate = 44100;
					var len96ms10:uint = lenSample / 960;
					outLenSamples = len96ms10 * 441;
				}
				
				var parent:String = file.parent.nativePath;
				var name:String = file.name;
				var ext:String = file.extension;
				name = name.substr (0, name.length - (ext.length + 1));
				var cnt:int = 1;
				var outFile:File = null;
				var targetpar:File = new File (parent);
				do {
					outFile = targetpar.resolvePath (name + "_" + cnt.toString() + "." + ext);
					if (!outFile.exists) {
						break;
					}
					cnt++;
				} while (cnt < 100);
				
				if (cnt < 100 && outFile != null) {
					var outFs:FileStream = new FileStream();
					outFs.open (outFile, FileMode.WRITE);
					
					//debugFs = new FileStream();
					//var debugPath:String = outFile.nativePath + ".txt";
					//var dbgf:File = new File (debugPath);
					//debugFs.open (dbgf, FileMode.WRITE);

					outFs.writeUTFBytes("RIFF");
					writeUnsignedLE (outFs, outLenSamples * outBlockSize + 36, 4); // total size minus 8 bytes
					outFs.writeUTFBytes("WAVE");
					outFs.writeUTFBytes("fmt ");
					writeUnsignedLE (outFs, 16, 4); // header size
					writeUnsignedLE (outFs, 1, 2); // format
					writeUnsignedLE (outFs, waveNumChannels, 2);
					writeUnsignedLE (outFs, outSampleRate, 4);
					writeUnsignedLE (outFs, outSampleRate * outBlockSize, 4);
					writeUnsignedLE (outFs, outBlockSize, 2);
					writeUnsignedLE (outFs, outBitsPerSample, 2);
					outFs.writeUTFBytes("data");
					writeUnsignedLE (outFs, outLenSamples * outBlockSize, 4);
					
					fsWave.position = waveStart;
					var block:Array = new Array();
					var valueSize:uint = waveBlockSize / waveNumChannels;
					var arrayIx:uint = waveBlockSize;
					var fadeInVal:Number = 0;
					var fadeInStep:Number = 1.0 / (fadeInLength * waveSampleRate);
					var fadeOutVal:Number = 1;
					var fadeOutStep:Number = 1.0 / (fadeOutLength * waveSampleRate);
					
					for (var j:uint = 0; j < waveSize; j++) {
						if (j >= afterLastByte) {
							break;
						}
						var bt:uint = fsWave.readUnsignedByte();
						if (j < begByte) {
							continue; // increment file position always
						}
						block.push(bt);
						arrayIx--;
						if (arrayIx == 0) {
							arrayIx = waveBlockSize;
							
							var nextix:uint = 2;
							var v1:uint = 0;
							var v2:int = 0;
							var v3:int = 0;
							var outlen:int = 2;
							var outshift:int = 16;
							if (valueSize == 2) {
								v1 = (block[0] << 16) + (block[1] << 24);
							}
							else {
								v1 = (block[0] << 8) + (block[1] << 16) + (block[2] << 24);
								nextix = 3;
								outlen = 3;
								outshift = 8;
							}
							v2 = int(v1);
							if (waveNumChannels == 2) {
								if (valueSize == 2) {
									v1 = (block[nextix] << 16) + (block[nextix + 1] << 24);
								}
								else {
									v1 = (block[nextix + 0] << 8) + (block[nextix + 1] << 16) + (block[nextix + 2] << 24);
								}
								v3 = int(v1);
							}

							if (normalize) {
								v2 *= amp;
								v3 *= amp;
							}
							if (j < lenFadeInBytes + begByte) {
								fadeInVal += fadeInStep;
								if (fadeInVal > 1) {
									fadeInVal = 1;
								}
								v2 *= fadeInVal;
								v3 *= fadeInVal;
							}
							else if (j >= beginFadeOutByte) {
								fadeOutVal -= fadeOutStep;
								if (fadeOutVal < 0) {
									fadeOutVal = 0;
								}
								v2 *= fadeOutVal;
								v3 *= fadeOutVal;
							}
							if (swap) {
								var tmp:int = v2;
								v2 = v3;
								v3 = tmp;
							}

							if (convert44) {
								var wave_ix:uint = (j - begByte) / waveBlockSize;
								write44_16 (outFs, v2, v3, outLenSamples, waveNumChannels, wave_ix);
							}
							else {
								writeSignedLE (outFs, v2, outlen, outshift);
								if (waveNumChannels == 2) {
									writeSignedLE (outFs, v3, outlen, outshift);
								}
							}
							block.length = 0;
						}
					}

				}
			}
			catch (error:Error) {
				var msg:String = "Cannot read file !";
				Alert.show( msg, "Error", Alert.OK);
			}
			
			//debugFs.close();
			
			return samples;
		}
		
		static public function write44_16 (fs:FileStream, v1:int, v2:int, len44smpl:uint, waveNumChannels:uint, pos:uint):void
		{
			if (wave44Pos_ >= len44smpl) {
				return;
			}
			var tmp96:Number = pos * 1000;
			var cur96Pos:uint = tmp96 / 96;
			var tmp44:Number = wave44Pos_ * 10000;
			var cur44PosMicroSec:uint = tmp44 / 441;
			var difftime:uint = cur96Pos - wave96PosMicroSec_;
			var diff44:uint = cur96Pos - cur44PosMicroSec;
			var ratio:Number = 0;
			if (difftime > 0) {
				ratio = diff44 / difftime;
			}
			var value1:int = v1;
			var value2:int = v2;
			var diffval1:int = 0;
			var diffval2:int = 0;
			
			if (cur96Pos >= cur44PosMicroSec) {
				if (cur96Pos > cur44PosMicroSec) {
					if (wave96LastVal1_ > v1) {
						diffval1 = wave96LastVal1_ - v1;
						value1 = v1 + ratio * diffval1;
						if (waveNumChannels == v2) {
							diffval2 = wave96LastVal2_ - v2;
							value2 = v2 + ratio * diffval2;
						}
					}
					else {
						diffval1 = v1 - wave96LastVal1_;
						value1 = v1 - ratio * diffval1;
						if (waveNumChannels == 2) {
							diffval2 = v2 - wave96LastVal2_;
							value2 = v2 - ratio * diffval2;
						}
					}
					
				}
				writeSignedLE (fs, value1, 2, 16);
				if (waveNumChannels == 2) {
					writeSignedLE (fs, value2, 2, 16);
				}
				
				if (wave44Pos_ < 1000) {
					//var v96o:int = wave96LastVal1_ / 65536;
					//var v96n:int = v1 / 65536;
					//var v44:int = value1 / 65536;
					//debugFs.writeUTFBytes("Position 96: " + cur96Pos.toString() + "\n");
					//debugFs.writeUTFBytes("Position 44: " + cur44PosMicroSec.toString() + "\n");
					//debugFs.writeUTFBytes("Value 96 old: " + v96o.toString() + "\n");
					//debugFs.writeUTFBytes("Value 96 new: " + v96n.toString() + "\n");
					//debugFs.writeUTFBytes("Value 44: " + v44.toString() + "\n");
					//debugFs.writeUTFBytes("---\n");
					
				}
				
				wave44Pos_++;
			}
			
			wave96LastVal1_ = v1;
			wave96LastVal2_ = v2;
			wave96PosMicroSec_ = cur96Pos;
		}

		static public function writeUnsignedLE (fs:FileStream, value:uint, length:uint):void
		{
			fs.writeByte(value);
			if (length > 1) {
				fs.writeByte (value >> 8);
			}
			if (length > 2) {
				fs.writeByte (value >> 16);
			}
			if (length > 3) {
				fs.writeByte (value >> 24);
			}
		}
		
		static public function writeSignedLE (fs:FileStream, value:int, length:uint, shift:uint):void
		{
			fs.writeByte (value >> shift);
			if (length > 1) {
				fs.writeByte (value >> (8 + shift));
			}
			if (length > 2) {
				fs.writeByte (value >> (16 + shift));
			}
			if (length > 3) {
				fs.writeByte (value >> (24 + shift));
			}
		}
		
		static public function findPeakValue (fs:FileStream, startpos:uint, length:uint, numChannels:uint, valueSize:uint, rate:uint):uint
		{
			if (valueSize < 2 || valueSize > 3) {
				return 0;
			}
			var maxval:uint = 0;
			fs.position = startpos;
			var block:Array = new Array();
			var arrayIx:uint = numChannels * valueSize;
			for (var i:uint = 0; i < length; i++) {
				var b:uint = fs.readUnsignedByte();
				block.push(b);
				arrayIx--;
				if (arrayIx == 0) {
					arrayIx = numChannels * valueSize;

					var nextix:uint = 2;
					var v1:uint = 0;
					var v2:int = 0;
					var v3:int = 0;
					if (valueSize == 2) {
						v1 = (block[0] << 16) + (block[1] << 24);
					}
					else {
						v1 = (block[0] << 8) + (block[1] << 16) + (block[2] << 24);
						nextix = 3;
					}
					v2 = int(v1);
					if (numChannels == 2) {
						if (valueSize == 2) {
							v1 = (block[nextix] << 16) + (block[nextix + 1] << 24);
						}
						else {
							v1 = (block[nextix + 0] << 8) + (block[nextix + 1] << 16) + (block[nextix + 2] << 24);
						}
						v3 = int(v1);
					}
					if (v2 < 0) {
						v2 *= -1;
					}
					if (v3 < 0) {
						v3 *= -1;
					}
					if (v2 > maxval) {
						maxval = v2;
					}
					if (v3 > maxval) {
						maxval = v3;
					}
					block.length = 0;
				}
			}
			return maxval; // in 32 bit format
		}
			
			
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
					Alert.show( "This file is not valid.", "JS File Error");
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
				Alert.show( msg, "JS File Error");
			}
			return s;
		}
		
		//=======================================================
		static public function RemoveDSStoreFiles (path:String):int
		{
			var count:int = 0;
			try {
				var file:File = new File (path);

				var files:Array = file.getDirectoryListing();
				for (var i1:uint = 0; i1 < files.length; i1++) {
					var f:File = files[i1];
					if (f.isDirectory) {
						count += RemoveDSStoreFiles (f.nativePath);
					}
					else if (f.name == ".DS_Store") {
						f.deleteFile();
						count++;
					}
				}
			}
			catch( e:Error) {
				var msg:String = "Exception caught when deleting .DS_Store\n";
				Alert.show( msg, "Delete Error");
			}
			return count;
		}
		
		//=======================================================
		
		static public function WriteDebugLogMessage (msg:String):void
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
				Alert.show( "Exception caught when writing logfile", "Log File Error");
			}
		}
	}
}

//=======================================================
/*
// Sample package

// events/MyStaticEventHandler.as
package { // Empty package.
import flash.events.Event;
import mx.controls.Alert;
public class MyStaticEventHandler {
public function MyStaticEventHandler() {
// Empty constructor.
}
public static function handleAllEvents(event:Event):void {
Alert.show("Some event happened.");
}
}
}

package myComponents
// myComponents/MyCustomTreeDataDescriptor.as
{
import mx.collections.ArrayCollection;
import mx.collections.CursorBookmark;
import mx.controls.treeClasses.*;
public class MyCustomTreeDataDescriptor implements ITreeDataDescriptor
{
}

    public function showTime(time:Date):void 
    {
        // gets the time values
        var seconds:uint = time.getSeconds();
        var minutes:uint = time.getMinutes();
        var hours:uint = time.getHours();

        // multiplies by 6 to get degrees
        this.secondHand.rotation = 180 + (seconds * 6);
        this.minuteHand.rotation = 180 + (minutes * 6);

        // Multiply by 30 to get basic degrees, then
        // add up to 29.5 degrees (59 * 0.5)
        // to account for the minutes.
        this.hourHand.rotation = 180 + (hours * 30) + (minutes * 0.5);
    }

*/
//=======================================================
/*
\history

WGo-2014-12-22: created
WGo-2015-01-23: Wave file playing is possible
WGo-2015-01-26: Wave file plays longer time
WGo-2015-02-03: AIFF plays too
WGo-2015-05-12: ConvertToAscii() had bug when creating c-string
WGo-2015-06-18: parameter isSpace added to ConvertToAscii()
WGo-2015-07-13: fade in after begin when begin > 0
WGo-2015-08-26: Convert 96k to 44.1k

*/

