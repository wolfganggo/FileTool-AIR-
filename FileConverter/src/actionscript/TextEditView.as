import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.system.System;
import flash.ui.Keyboard;

import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.AIREvent;
import mx.events.FlexEvent;
import mx.events.FlexNativeWindowBoundsEvent;
import mx.events.ItemClickEvent;

import spark.events.TextOperationEvent;

import flashx.textLayout.elements.TextFlow;
import flashx.textLayout.operations.FlowOperation;


private var docPath_:String = "";
private var content_:Array = null;
private var lineEndings_:int = -1; // 0 = lf, 1 = cr, 2 = cr/lf
private var linePositions_:Array = null;
private var curLineNum_:int = 0;
private var curColNum_:int = 0;
private var TextLengthInit_:int = 0; // initial length, where line end is always 1 char (CR+LF = 1 char)
private var isMacEncoding_:Boolean = false;
private var isWinEncoding_:Boolean = false;
private var isUtf8Encoding_:Boolean = false;
static private var isMacEncSetting_:Boolean = true;
static private var isWinEncSetting_:Boolean = false;
static private var isUtf8EncSetting_:Boolean = false;
private var isModified_:Boolean = false;
private var uft8Byte1_:uint = 0;
private var uft8Byte2_:uint = 0;
private var uft8Byte3_:uint = 0;
private var uft16SuHigh_:uint = 0;

static private var searchStr_:String = "";

private var curName_:String = "";
private var findDlg_:FindDialog = null;
private var caseSensitive_:Boolean = false;
private var wholeWords_:Boolean = false;
private var lastVersion_:String = "";

static private var mem_1_:String = "";
static private var mem_2_:String = "";
static private var mem_3_:String = "";
static private var mem_4_:String = "";
static private var mem_5_:String = "";
static private var mem_6_:String = "";
static private var mem_7_:String = "";
static private var mem_8_:String = "";
static private var mem_9_:String = "";


private function OnWindowComplete():void
{
	mem_1_ = FlexGlobals.topLevelApplication.prefs_.getEditstr1();
	mem_2_ = FlexGlobals.topLevelApplication.prefs_.getEditstr2();
	mem_3_ = FlexGlobals.topLevelApplication.prefs_.getEditstr3();
	mem_4_ = FlexGlobals.topLevelApplication.prefs_.getEditstr4();
	mem_5_ = FlexGlobals.topLevelApplication.prefs_.getEditstr5();
	mem_6_ = FlexGlobals.topLevelApplication.prefs_.getEditstr6();
	mem_7_ = FlexGlobals.topLevelApplication.prefs_.getEditstr7();
	mem_8_ = FlexGlobals.topLevelApplication.prefs_.getEditstr8();
	mem_9_ = FlexGlobals.topLevelApplication.prefs_.getEditstr9();
	RefreshStore();

	this.nativeWindow.x = 50;
	this.nativeWindow.y = 0;
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	if (isMacEncSetting_) {
		rb_mac.selected = true;
	}
	else if (isWinEncSetting_) {
		rb_win.selected = true;
	}
	else if (isUtf8EncSetting_) {
		rb_utf8.selected = true;
	}
	else {
		rb_ascii.selected = true;
	}
	if (!FlexGlobals.topLevelApplication.ch_Font.selected) {
		edittx.setStyle("fontFamily", FlexGlobals.topLevelApplication.fontFamilyCourier_);
	}
	edittx.setFocus();
}


public function setSize (w:int, h:int):void
{
	this.width = w;
	this.height = h;
}

protected function windowResizeHandler (event:FlexNativeWindowBoundsEvent):void
{
	FlexGlobals.topLevelApplication.setTextViewParameter (this.width, this.height);
	//ShowTextContent();
}

protected function windowDeactivateHandler(event:AIREvent):void
{
}

protected function OnClosing(event:Event):void
{
	if (isModified_) {
		try {
			var saveTarget:File = new File (docPath_);
			saveTarget.addEventListener (Event.SELECT, closeSaveFileHandler);
			saveTarget.addEventListener (Event.CANCEL, closeCancelFileHandler);
			saveTarget.browseForSave ("Save modified file as");
		}
		catch (e:Error) {
		}
		event.preventDefault();
	}
	FlexGlobals.topLevelApplication.onAfterTextEdit();
}

protected function closeSaveFileHandler (event:Event):void 
{
	try {
		var newFile:File = event.target as File;
		saveFile (newFile);
		isModified_ = false;
	}
	catch (error:Error) {
	}
	this.close();
}

protected function closeCancelFileHandler (event:Event):void 
{
	isModified_ = false;
	this.close();
}


public function loadTextFile (path:String):void
{
	docPath_ = path;
	lineEndings_ = -1;
	isMacEncoding_ = isMacEncSetting_;
	isWinEncoding_ = isWinEncSetting_;
	isUtf8Encoding_ = isUtf8EncSetting_;
	linePositions_ = new Array();

	try {
		var file:File = new File (path);
		this.title = file.name;
		var fstr:FileStream = new FileStream();
		fstr.open (file, FileMode.READ);
		var len:Number = file.size;
		if (len > 20000000) { // max 20 MB
			fstr.close();
			return;
		}
		content_ = new Array();
		for (var ix:uint = 0; ix < len; ix++) {
			content_.push (fstr.readUnsignedByte());
		}
		fstr.close();
		
		ShowTextContent();
	}
	catch (e:Error) {
	}
}

private function ShowTextContent():void
{
	var wasLF:Boolean = false;
	var wasCR:Boolean = false;
	var waswasCR:Boolean = false;
	var content:String = "";
	var lineLength:int = 1;
	var lineStart:int = 0;
	var ix_txt:int = 0;
	var len:uint = content_.length;
	tx_Index.text = "P: 0";
	tx_Line.text = "L: 0";
	tx_Column.text = "C: 0";
	
	//if (lineLength < 1) {
		//textChunk.writeMultiByte("Täst", "unicode");
		//textChunk.writeUTF("Täst"); // OK
		//textChunk.writeMultiByte("Täst", "utf-8"); // OK
		//edittx.text = textChunk.readMultiByte(4, "unicode");
		//edittx.text = textChunk.toString(); // OK
		//return;
	//}
	
	for (var ix:uint = 0; ix < len; ix++, lineLength++, ix_txt++) {
		var bt:uint = content_[ix];
		if (lineEndings_ < 0 && (wasLF || wasCR) && bt != 10 && bt != 13) {
			if (wasLF && waswasCR) {
				lineEndings_ = 2;
			}
			else if (wasCR) {
				lineEndings_ = 1;
			}
			else {
				lineEndings_ = 0;
			}
		}
		waswasCR = wasCR;
		if (bt == 10) {
			if (!wasCR) {
				content += "\n";
				var entry:Object = new Object();
				entry.kStart = lineStart;
				entry.kLength = lineLength;
				linePositions_.push (entry);
				lineLength = 0;
				lineStart = ix_txt + 1;
			}
			else {
				lineLength--;
				ix_txt--;
			}
			wasLF = true;
			wasCR = false;
		}
		else if (bt == 13) {
			content += "\n";
			var entry1:Object = new Object();
			entry1.kStart = lineStart;
			entry1.kLength = lineLength;
			linePositions_.push (entry1);
			lineLength = 0;
			lineStart = ix_txt + 1;
			wasCR = true;
			wasLF = false;
		}
		else if (bt == 9) {
			wasLF = false;
			wasCR = false;
			content += String.fromCharCode(bt);
		}
		else if (bt < 32 || bt > 126) {
			wasLF = false;
			wasCR = false;
			if (isMacEncoding_) {
				content += readMacRoman (bt);
			}
			else if (isWinEncoding_) {
				content += readWinAnsi (bt);
			}
			else if (isUtf8Encoding_) {
				var u8:String = readUTF8 (bt);
				if (u8.length == 0) {
					lineLength--;
					ix_txt--;
				}
				content += u8;
			}
			else {
				content += ".";
			}
		}
		else {
			wasLF = false;
			wasCR = false;
			content += String.fromCharCode(bt);
		}
		
	}
	TextLengthInit_ = ix_txt;
	
	var entry2:Object = new Object();
	entry2.kStart = lineStart;
	entry2.kLength = lineLength;
	linePositions_.push (entry2);
	
	edittx.text = content;

	//textChunk.writeMultiByte (content, "unicode"); // big endian ?
	//textChunk.writeMultiByte (content, "unicodeFFFE"); // little endian ?
	//textChunk2.writeUTF("  Täst"); // OK

	//edittx.text = textChunk2.readUTFBytes(3);
	//edittx.text += "\u263a"; // smiley - both s: and mx: take always UTF16, even in htmlText
	
}

private function readMacRoman (bt:uint):String
{
	if (bt == 9 || bt == 10 || bt == 13) {
		return "";
	}
	
	if (bt == 128) {
		return String.fromCharCode(196); // A uml
	}
	else if (bt == 133) {
		return String.fromCharCode(214); // O uml
	}
	else if (bt == 134) {
		return String.fromCharCode(220); // U uml
	}
	else if (bt == 138) {
		return String.fromCharCode(228); // a uml
	}
	else if (bt == 154) {
		return String.fromCharCode(246); // o uml
	}
	else if (bt == 159) {
		return String.fromCharCode(252); // u uml
	}
	else if (bt == 167) {
		return String.fromCharCode(223); // sz
	}
	else if (bt == 219) {
		return "\u20ac"; // euro
	}
	else if (bt == 129) {
		return "\u00c5"; // A o
	}
	else if (bt == 130) {
		return "\u00c7"; // C
	}
	else if (bt == 131) {
		return "\u00c9"; // E acc a
	}
	else if (bt == 132) {
		return "\u00d1"; // N tilde
	}

	else if (bt == 135) {
		return String.fromCharCode(225);
		//return "\u00e1"; // a acc a
	}
	else if (bt == 136) {
		return String.fromCharCode(224);
		//return "\u00e2"; // a acc g
	}
	else if (bt == 137) {
		return String.fromCharCode(226);
		//return "\u00e3"; // a dach
	}
	else if (bt == 139) {
		return String.fromCharCode(227); // a ti
		//	return "\u00e4"; // a ti
	}
	
	else if (bt == 140) {
		return String.fromCharCode(229); // a o
	}
	else if (bt == 141) {
		return String.fromCharCode(231); // c
	}
	else if (bt == 142) {
		return String.fromCharCode(233); // e acc a
	}
	else if (bt == 143) {
		return String.fromCharCode(232); // e acc g
	}

	else if (bt == 144) {
		return String.fromCharCode(234); // e da
	}
	else if (bt == 145) {
		return String.fromCharCode(235); // e uml
	}
	else if (bt == 146) {
		return String.fromCharCode(237); // i acc a
	}
	else if (bt == 147) {
		return String.fromCharCode(236); // i acc g
	}
	else if (bt == 148) {
		return String.fromCharCode(238); // i da
	}
	else if (bt == 149) {
		return String.fromCharCode(239); // i uml
	}
	else if (bt == 150) {
		return String.fromCharCode(241); // n ti
	}
	else if (bt == 151) {
		return String.fromCharCode(243); // o acc a
	}
	else if (bt == 152) {
		return String.fromCharCode(242); // o acc g
	}
	else if (bt == 153) {
		return String.fromCharCode(244); // o da
	}
	else if (bt == 155) {
		return String.fromCharCode(245); // o ti
	}

	else if (bt == 156) {
		return String.fromCharCode(250); // u acc a
	}
	else if (bt == 157) {
		return String.fromCharCode(249); // u acc g
	}
	else if (bt == 158) {
		return String.fromCharCode(251); // u da
	}
	else if (bt == 160) {
		return String.fromCharCode(8224); // dagger
	}
	else if (bt == 161) {
		return String.fromCharCode(176); // grad
	}
	else if (bt == 162) {
		return String.fromCharCode(162); // C |
	}
	else if (bt == 163) {
		return String.fromCharCode(163); // pound
	}
	else if (bt == 164) {
		return String.fromCharCode(167); // paragraph
	}
	else if (bt == 165) {
		return String.fromCharCode(8226); // bullet 8226
	}
	else if (bt == 166) {
		return String.fromCharCode(182); // line end
	}
	
	else if (bt == 168) {
		return String.fromCharCode(174); // (R)
	}
	else if (bt == 169) {
		return String.fromCharCode(169); // (C)
	}
	else if (bt == 170) {
		return String.fromCharCode(8482); // TM
	}
	else if (bt == 171) {
		return String.fromCharCode(180); // accent a
	}
	else if (bt == 173) {
		return String.fromCharCode(8800); // =|
	}
	else if (bt == 174) {
		return String.fromCharCode(198); // A uml nor
	}
	else if (bt == 175) {
		return String.fromCharCode(216); // O uml nor
	}
	else if (bt == 176) {
		return String.fromCharCode(8734); // oo
	}
	else if (bt == 177) {
		return String.fromCharCode(177); // +-
	}
	else if (bt == 178) {
		return String.fromCharCode(8804); // <=
	}
	else if (bt == 179) {
		return String.fromCharCode(8805); // >=
	}
	else if (bt == 180) {
		return String.fromCharCode(165); // Y=
	}
	else if (bt == 181) {
		return String.fromCharCode(956); // my
	}
	else if (bt == 182) {
		return String.fromCharCode(948); // delta
	}
	else if (bt == 183) {
		return String.fromCharCode(8721); // Summe
	}
	else if (bt == 184) {
		return String.fromCharCode(8719); // Pi math
	}
	else if (bt == 185) {
		return String.fromCharCode(960); // pi
	}
	else if (bt == 186) {
		return String.fromCharCode(8747); // integral
	}
	else if (bt == 187) {
		return String.fromCharCode(170); // a_
	}
	else if (bt == 188) {
		return String.fromCharCode(186); // o_
	}
	else if (bt == 189) {
		return String.fromCharCode(937); // omega
	}
	else if (bt == 190) {
		return String.fromCharCode(230); // a uml nor
	}
	else if (bt == 191) {
		return String.fromCharCode(248); // o uml nor
	}
	else if (bt == 192) {
		return String.fromCharCode(191); // ? invers
	}
	else if (bt == 193) {
		return String.fromCharCode(161); // ! invers
	}
	else if (bt == 194) {
		return String.fromCharCode(172); // ende
	}
	else if (bt == 195) {
		return String.fromCharCode(8730); // wurzel
	}
	else if (bt == 196) { // f lat.
		return String.fromCharCode(402);
	}
	else if (bt == 197) {
		return String.fromCharCode(8776); // welle
	}
	else if (bt == 198) {
		return String.fromCharCode(8710); // math (dreieck)
	}
	else if (bt == 199) {
		//return String.fromCharCode(171); // doppelt links
		return String.fromCharCode(8810); // doppelt links (math) "\u226a"
	}
	else if (bt == 200) {
		//return String.fromCharCode(187); // doppelt rechts
		return String.fromCharCode(8811); // doppelt rechts (math) "\u226b"
	}
	else if (bt == 201) {
		//return String.fromCharCode(8424); // ...
		return String.fromCharCode(8230); // ...
	}
	else if (bt == 202) {
		//return " "; // space
		return String.fromCharCode(9251); // "\u2423"
	}
	else if (bt == 203) {
		return String.fromCharCode(192); // A acc g
	}
	else if (bt == 204) {
		return String.fromCharCode(195); // A ti
	}
	else if (bt == 205) {
		return String.fromCharCode(213); // O ti
	}
	else if (bt == 206) {
		return String.fromCharCode(338); // OE
	}
	else if (bt == 207) {
		return String.fromCharCode(339); // oe
	}
	else if (bt == 208) {
		return String.fromCharCode(8211); // En dash
	}
	else if (bt == 209) {
		return String.fromCharCode(8212); // Em dash
	}
	else if (bt == 210) {
		return String.fromCharCode(8220); // " begin
	}
	else if (bt == 211) {
		return String.fromCharCode(8221); // " end
	}
	else if (bt == 212) {
		return String.fromCharCode(8216); // ' begin   8216 8245
	}
	else if (bt == 213) {
		return String.fromCharCode(8217); // ' end     8217 8242
	}
	else if (bt == 214) {
		return String.fromCharCode(247); // division
	}
	else if (bt == 215) {
		return String.fromCharCode(9826); // rhombos
	}
	else if (bt == 216) {
		return String.fromCharCode(255); // y uml
	}
	else if (bt == 217) { // Y uml
		return String.fromCharCode(376);
	}
		
	else if (bt == 218) {
		return String.fromCharCode(8725);
		//return "/";
	}
	else if (bt == 220) {
		return String.fromCharCode(706);
		//return "<";
	}
	else if (bt == 221) {
		return String.fromCharCode(707);
		//return ">";
	}
	
	else if (bt == 224) {
		return String.fromCharCode(8225); // double dagger
	}
	else if (bt == 225) {
		return String.fromCharCode(183); // punkt
	}
	else if (bt == 226) {
		return String.fromCharCode(184); // ' unten  8218
	}
	else if (bt == 227) {
		return String.fromCharCode(8222); // " unten
	}
	else if (bt == 228) {
		return String.fromCharCode(8240); // promille
	}
	else if (bt == 229) {
		return String.fromCharCode(194); // A da
	}
	else if (bt == 230) {
		return String.fromCharCode(202); // E da
	}
	else if (bt == 231) {
		return String.fromCharCode(193); // A acc a
	}
	else if (bt == 232) {
		return String.fromCharCode(203); // E uml
	}
	else if (bt == 233) {
		return String.fromCharCode(200); // E acc g
	}
	else if (bt == 234) {
		return String.fromCharCode(205); // I acc a
	}
	else if (bt == 235) {
		return String.fromCharCode(206); // I da
	}
	else if (bt == 236) {
		return String.fromCharCode(207); // I uml
	}
	else if (bt == 237) {
		return String.fromCharCode(204); // I acc g
	}
	else if (bt == 238) {
		return String.fromCharCode(211); // O acc a
	}
	else if (bt == 239) {
		return String.fromCharCode(212); // O da
	}
	else if (bt == 240) {
		return String.fromCharCode(9787); // apple => 9787 (black smiley)
	}
	else if (bt == 241) {
		return String.fromCharCode(210); // O acc g
	}
	else if (bt == 242) {
		return String.fromCharCode(218); // U acc a
	}
	else if (bt == 243) {
		return String.fromCharCode(219); // U da
	}
	else if (bt == 244) {
		return String.fromCharCode(217); // U acc g
	}

	else if (bt == 251) {
		return String.fromCharCode(959); // grad (kleines griech. o)
	}
	else if (bt == 253) {
		return String.fromCharCode(698); // sekunde 698
	}
	else if (bt == 127) {
		return String.fromCharCode (8848);
	}
	else if (bt == 172) { // uml
		return String.fromCharCode (8849);
	}
	else if (bt == 222 || bt == 223) { // fi, fl
		return String.fromCharCode (bt + 8850 - 222);
	}
	
	else if (bt == 252 || bt == 254 || bt == 255 || (bt > 244 && bt < 251)) {
		return String.fromCharCode (bt + 8864 - 245); // ab 0x22A0 (8864)
	}

	else if (bt == 8) {
		return String.fromCharCode (10048); // #10024 is not shown
	}
	else if (bt >= 0 && bt < 32) {
		return String.fromCharCode(bt + 10016); // ab 0x2720
	}
	
	return ".";
}

private function readWinAnsi (bt:uint):String
{
	if (bt == 9 || bt == 10 || bt == 13) {
		return "";
	}

	if (bt == 171) {
		return String.fromCharCode(8810); // doppelt links (math) "\u226a"
	}
	//else if (bt == 170) {
	//	return "\u237a";
	//}
	else if (bt == 187) {
		return String.fromCharCode(8811); // doppelt rechts (math) "\u226b"
	}
	else if (bt > 160 && bt < 256) {
		return String.fromCharCode(bt); // 171, 187 geht nicht
	}
	else if (bt == 128) {
		return "\u20ac"; // Euro
	}
	else if (bt >= 0 && bt < 32) {
		return String.fromCharCode(bt + 10016); // ab 0x2720
	}
	else if (bt == 127 || (bt >128 && bt < 161)) { // ab 0x2290 (8848) - 0x22b1 oder 0x2720 (10016) - 0x2741
		return String.fromCharCode (bt + 8848 - 127);
	}
	
	//else if (bt == 138) {
	//	return String.fromCharCode(bt); // S (with hat) ?
	//}
	return ".";
}

private function readUTF8 (bt:uint):String
{
	if (bt == 9 || bt == 10 || bt == 13) {
		return "";
	}
	
	if (bt > 0xc1 && bt < 0xf5) {
		uft8Byte1_ = bt;
		return "";
	}
	else if (bt > 0x7f && bt < 0xc0) {
		var tmp:uint = 0;
		if (uft8Byte3_ != 0) {
			// 2 ^ 18 = 262144; 2 ^ 16 = 65536; 2 ^ 12 = 4096
			//tmp = (uft8Byte1_ - 240) * 262144 + ((uft8Byte2_ - 128) / 16) * 65536 + 
			//	(uft8Byte2_ % 16) * 4096 + (uft8Byte3_ - 128) * 64 + (bt - 128);
			var u1:uint = (uft8Byte1_ - 240) * 262144;
			//var u2:uint = (uft8Byte2_ / 16 - 8) * 65536; // wrong result !
			var u21:uint = uft8Byte2_ / 16;
			var u22:uint = u21 - 8;
			var u2:uint = u22 * 65536;
			var u3:uint = (uft8Byte2_ % 16) * 4096;
			var u4:uint = (uft8Byte3_ - 128) * 64;
			tmp = u1 + u2 + u3 + u4 + (bt - 128);
			clearUTF8Mem();
			var sur0:uint = tmp % 1024 + 0xDC00;
			var sur1:uint = (tmp - 65536) / 1024 + 0xD800;
			//return String.fromCharCode (tmp);
			return String.fromCharCode (sur1, sur0);
		}
		else if (uft8Byte2_ != 0) {
			if (uft8Byte1_ < 0xf0) {
				tmp = (uft8Byte1_ - 224) * 4096 + (uft8Byte2_ - 128) * 64 + (bt - 128);
				clearUTF8Mem();
				return String.fromCharCode (tmp);
			}
			uft8Byte3_ = bt;
			return "";
		}
		else if (uft8Byte1_ > 0) {
			if (uft8Byte1_ < 0xe0) {
				tmp = (uft8Byte1_ - 192) * 64 + (bt - 128);
				clearUTF8Mem();
				return String.fromCharCode (tmp);
			}
			uft8Byte2_ = bt;
			return "";
		}
	}
	return String.fromCharCode(0xfffd);
}

private function clearUTF8Mem():void
{
	uft8Byte1_ = 0;
	uft8Byte2_ = 0;
	uft8Byte3_ = 0;
}

protected function OnKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey; // Mac: Ctrl or Cmnd
	var isShiftKey:Boolean = event.shiftKey;
	var isAltKey:Boolean = event.altKey;
	var key:uint = event.keyCode;
	if (key == Keyboard.S && isControlKey) {
		try {
			if (isShiftKey) {
				var saveTarget:File = new File (docPath_);
				//saveTarget = saveTarget.parent;
				saveTarget.addEventListener (Event.SELECT, saveFileHandler);
				//saveTarget.addEventListener (Event.CANCEL, cancelFileHandler);
				saveTarget.browseForSave ("Save As");
			}
			else {
				var saveFs:File = new File (docPath_);
				saveFile (saveFs);
				//Alert.show ("Save File", "Save File", Alert.OK, this);
			}
		}
		catch (error:Error) {
			//trace("Failed:", error.message);
		}
	}
	else if (key == Keyboard.W && isControlKey) {
		this.close();
	}
	else if (key == Keyboard.M && isControlKey) {
		//storeActive_ = true;
		//curName_ = edittx.selectionAnchorPosition
		curName_ = edittx.text.substring (edittx.selectionAnchorPosition, edittx.selectionActivePosition);
		var chooser:ChooseMemoryView = new ChooseMemoryView();
		chooser.open();
	}
	else if (key == Keyboard.G && isControlKey) {
		if (isShiftKey) {
			findTextBackwards();
		}
		else {
			searchSelection (isAltKey);
		}
	}
	else if (key == Keyboard.F && isControlKey) {
		findDlg_ = new FindDialog();
		findDlg_.addEventListener (Event.CLOSE, OnFindClose);
		findDlg_.editView_ = this;
		findDlg_.setSearchString (edittx.text.substring (edittx.selectionAnchorPosition, edittx.selectionActivePosition));
		findDlg_.open();
	}
	else if (key == Keyboard.Z && isControlKey && lastVersion_.length > 0) {
		edittx.text = lastVersion_;
		lastVersion_ = "";
		edittx.setFocus();
	}
	
	if (key > 31 &&
		key != Keyboard.DOWN && key != Keyboard.LEFT && key != Keyboard.RIGHT && key != Keyboard.UP &&
		lastVersion_.length > 0)
	{
		lastVersion_ = "";
	}
	
	if (key >= Keyboard.NUMBER_1 && key <= Keyboard.NUMBER_9 && isControlKey) {
		var pos2:int = key - Keyboard.NUMBER_1 + 1;
		switch (pos2) {
			case 1: curName_ = mem_1_;
				break;
			case 2: curName_ = mem_2_;
				break;
			case 3: curName_ = mem_3_;
				break;
			case 4: curName_ = mem_4_;
				break;
			case 5: curName_ = mem_5_;
				break;
			case 6: curName_ = mem_6_;
				break;
			case 7: curName_ = mem_7_;
				break;
			case 8: curName_ = mem_8_;
				break;
			case 9: curName_ = mem_9_;
				break;
		}
		if (curName_.length > 0) {
			lastVersion_ = edittx.text;
			edittx.insertText (curName_);
			isModified_ = true;
			if (this.title.length < 3) {
				this.title += " *";
			}
			else if (this.title.charAt (this.title.length - 1) != "*" && this.title.charAt (this.title.length - 2) != " ") {
				this.title += " *";
			}
		}
	}

}

public function setMemoryNumber (num:int):void 
{
	switch (num) {
		case 1: mem_1_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr1(curName_);
			break;
		case 2: mem_2_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr2(curName_);
			break;
		case 3: mem_3_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr3(curName_);
			break;
		case 4: mem_4_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr4(curName_);
			break;
		case 5: mem_5_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr5(curName_);
			break;
		case 6: mem_6_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr6(curName_);
			break;
		case 7: mem_7_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr7(curName_);
			break;
		case 8: mem_8_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr8(curName_);
			break;
		case 9: mem_9_ = curName_;
			FlexGlobals.topLevelApplication.prefs_.setEditstr9(curName_);
			break;
	}
	RefreshStore();
}

private function searchSelection (newSelection:Boolean):void 
{
	if (newSelection) {
		searchStr_ = edittx.text.substring (edittx.selectionAnchorPosition, edittx.selectionActivePosition);
	}
	findText();
}

public function startFind (replace:Boolean, all:Boolean):void
{
	caseSensitive_ = findDlg_.getCaseSensitive();
	wholeWords_ = findDlg_.getIsWholeWords();
	searchStr_ = findDlg_.findString_;
	getInfo();
	if (replace) {
		replaceText (findDlg_.replaceString_, all);
	}
	else {
		findText();
	}
	edittx.setFocus();
}

protected function OnFindClose (event:Event):void
{
	caseSensitive_ = findDlg_.getCaseSensitive();
	wholeWords_ = findDlg_.getIsWholeWords();
	getInfo();
}

private function findText():void 
{
	var curPos:int = edittx.selectionActivePosition;
	edittx.selectRange (curPos, curPos);

	if (searchStr_.length == 0) {
		return;
	}
	var allText:String = edittx.text;
	if (!caseSensitive_) {
		allText = allText.toLocaleLowerCase();
		searchStr_ = searchStr_.toLocaleLowerCase();
	}
	var pos:int = findNextIndexOf (searchStr_, allText, curPos);
	if (pos == -1) {
		pos = findNextIndexOf (searchStr_, allText, 0);
	}
	if (pos != -1) {
		edittx.scrollToRange (pos, pos + searchStr_.length);
		edittx.selectRange (pos, pos + searchStr_.length);
		
		//var max:Number = edittx.scroller.verticalScrollBar.maximum;
		//var totalMax:Number = max + this.height;
		//var scrollPerLine:Number = totalMax / linePositions_.length;
		//var linesVisible:int = this.height / scrollPerLine;
		//getLineAndColumnNumber (pos);
		//if (curLineNum_ > linesVisible) {
		//	var scrollLines:int = curLineNum_ - linesVisible;
		//	var val:Number = scrollLines * scrollPerLine;
			//edittx.scroller.verticalScrollBar.value = val;
		//}
	}
	else {
		edittx.selectRange (curPos, curPos);
	}
}

private function findTextBackwards():void 
{
	var curPos:int = edittx.selectionActivePosition;
	edittx.selectRange (curPos, curPos);
	
	if (searchStr_.length == 0) {
		return;
	}
	var allText:String = edittx.text;
	if (!caseSensitive_) {
		allText = allText.toLocaleLowerCase();
		searchStr_ = searchStr_.toLocaleLowerCase();
	}

	var pos:int = 0; 
	var foundpos:int = -1; 
	var lastpos:int = -1; 
	do {
		foundpos = findNextIndexOf (searchStr_, allText, pos);
		if (foundpos > curPos - searchStr_.length - 1 || foundpos < 0) {
			break;
		}
		pos += searchStr_.length;
		lastpos = foundpos;
	} while (foundpos > -1);
	
	if (lastpos != -1) {
		edittx.scrollToRange (lastpos, lastpos + searchStr_.length);
		edittx.selectRange (lastpos, lastpos + searchStr_.length);
	}
	else {
		edittx.selectRange (curPos, curPos);
	}
}

private function findNextIndexOf (srchstr:String, txt:String, pos:int):int 
{
	var curPos:int = pos;
	var foundPos:int = -1;
	do {
		foundPos = txt.indexOf (srchstr, curPos);
		if (foundPos < 0) {
			break;
		}
		curPos += srchstr.length;
		foundPos = isWholeWordFound (txt, srchstr, foundPos, wholeWords_);
	} while (foundPos < 0 && curPos < txt.length);
	return foundPos;
}

public function findTextCount (s:String, cs:Boolean, whole:Boolean):int 
{
	if (s.length == 0) {
		return 0;
	}
	var retval:int = 0;
	var allText:String = edittx.text;
	if (!cs) {
		allText = allText.toLocaleLowerCase();
		s = s.toLocaleLowerCase();
	}
	var pos:int = 0;
	do {
		if (pos > 0) {
			pos += s.length;
		}
		pos = allText.indexOf (s, pos);
		var curPos:int = isWholeWordFound (allText, s, pos, whole);
		if (curPos != -1) {
			retval++;
		}
		if (retval > 999) {
			break;
		}
	} while (pos >= 0);
	return retval;
}

protected function isWholeWordFound (allText:String, searchStr:String, pos:int, whole:Boolean):int
{
	if (!whole) {
		return pos;
	}
	var beforeOK:Boolean = false;
	var afterOK:Boolean = false;
	if (pos == 0) {
		beforeOK = true;
	}
	else {
		var cb:uint = allText.charCodeAt (pos - 1);
		beforeOK = isDelimiter (cb);
	}

	if (pos + searchStr.length == allText.length) {
		afterOK = true;
	}
	else {
		var ca:uint = allText.charCodeAt (pos + searchStr.length);
		afterOK = isDelimiter (ca);
	}
	
	if (beforeOK && afterOK) {
		return pos;
	}
	return -1;
}

private function isDelimiter (ch:uint):Boolean 
{
	return ch < 35 || (ch > 39 && ch < 48) || (ch > 57 && ch < 64) || (ch > 90 && ch < 94) || (ch > 122 && ch < 126);
}

private function replaceText (newStr:String, all:Boolean):void 
{
	var beginPos:int = edittx.selectionAnchorPosition;
	var endPos:int = edittx.selectionActivePosition;
	var part3:String = "";
	var addLen:int = newStr.length - searchStr_.length;
	var newSel:int = endPos + addLen;
	var fdcount:int = findTextCount (searchStr_, caseSensitive_, wholeWords_);

	if (!all) {
		if (beginPos < 0 || endPos < 0 || endPos <= beginPos) {
			return;
		}
		edittx.selectRange (endPos, endPos);
		
		part3 = edittx.text.substring (endPos);
		edittx.text = edittx.text.substring (0, beginPos);
		edittx.text += newStr + part3;
		edittx.selectRange (newSel, newSel);
	}
	
	findText();
	
	if (all) {
		do {
			beginPos = edittx.selectionAnchorPosition;
			endPos = edittx.selectionActivePosition;
			
			if (beginPos < 0 || endPos < 0 || endPos <= beginPos) {
				break;
			}
			edittx.selectRange (endPos, endPos);
			
			part3 = edittx.text.substring (endPos);
			edittx.text = edittx.text.substring (0, beginPos);
			edittx.text += newStr + part3;
			newSel = endPos + addLen;
			edittx.selectRange (newSel, newSel);
			
			findText();
			
			fdcount--;
		} while (endPos > -1 && fdcount > 0);
	}

	isModified_ = true;
	if (this.title.length < 3) {
		this.title += " *";
	}
	else if (this.title.charAt (this.title.length - 1) != "*" && this.title.charAt (this.title.length - 2) != " ") {
		this.title += " *";
	}
}

protected function saveFileHandler (event:Event):void 
{
	try {
		var newFile:File = event.target as File;
		saveFile (newFile);
	}
	catch (error:Error) {
	}
	//FlexGlobals.topLevelApplication.fs_importFiles.refresh();
}

private function saveFile (target:File):void 
{
	var stream:FileStream = new FileStream();
	stream.open (target, FileMode.WRITE);
	content_.length = 0;
	
	var len:uint = edittx.text.length;
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = edittx.text.charCodeAt(ix);
		//if (lineEndings_ < 0 && (wasLF || wasCR) && bt != 10 && bt != 13) {
		//	if (wasLF && waswasCR) {
		//		lineEndings_ = 2;
		//	else if (wasCR) {
		//		lineEndings_ = 1;
		//	else {
		//		lineEndings_ = 0;
		if (bt == 10) {
			if (lineEndings_ == 1) {
				stream.writeByte(13);
				content_.push(13);
			}
			else if (lineEndings_ == 2) {
				stream.writeByte(13);
				stream.writeByte(10);
				content_.push(13);
				content_.push(10);
			}
			else {
				stream.writeByte(bt);
				content_.push(bt);
			}
		}
		else if (isMacEncoding_) {
			var mb:uint = getByteInMacRoman (bt);
			stream.writeByte (mb);
			content_.push(mb);
		}
		else if (isWinEncoding_) {
			var wb:uint = getByteInWinAnsi (bt);
			stream.writeByte (wb);
			content_.push(wb);
		}
		else if (isUtf8Encoding_) {
			var bts:Array = getBytesInUTF8 (bt);
			for (var iy:uint = 0; iy < bts.length; iy++) {
				stream.writeByte (bts[iy]);
				content_.push (bts[iy]);
			}
		}
		
		//getBytesInUTF8 (bt:uint):Array
		else {
			stream.writeByte (bt);
			content_.push(bt);
		}
	}
	
	//stream.writeUTFBytes(str);
	stream.close();
	isModified_ = false;
	this.title = target.name;

	linePositions_ = new Array();
	ShowTextContent();
}

protected function getByteInMacRoman (bt:uint):uint
{
	if ((bt > 31 && bt < 127) || bt == 9 || bt == 10 || bt == 13) {
		return bt;
	}
	else if (bt == 196) {
		return 128; // A uml
	}
	else if (bt == 214) {
		return 133; // O uml
	}
	else if (bt == 220) {
		return 134; // U uml
	}
	else if (bt == 228) {
		return 138; // a uml
	}
	else if (bt == 246) {
		return 154; // o uml
	}
	else if (bt == 252) {
		return 159; // u uml
	}
	else if (bt == 223) {
		return 167; // sz
	}
	else if (bt == 8364) { // "\u20ac"
		return 219; // euro
	}
	else if (bt == 197) {
		return 129; // A o
	}
	else if (bt == 199) {
		return 130; // Cedi
	}
	else if (bt == 201) {
		return 131; // E acc a
	}
	else if (bt == 209) {
		return 132; // N tilde
	}
	else if (bt == 225) {
		return 135; // a acc a
	}
	
	else if (bt == 224) {
		//else if (bt == 226) {
		return 136; // a acc g
	}
	else if (bt == 226) {
		//else if (bt == 227) {
		return 137; // a dach
	}
	else if (bt == 227) {
		//else if (bt == 228) {
		return 139; // a ti
	}
	
	else if (bt == 229) {
		return 140; // a o
	}
	else if (bt == 231) {
		return 141; // cedi
	}
	else if (bt == 233) {
		return 142; // e acc a
	}
	else if (bt == 232) {
		return 143;
	}
	else if (bt == 234) {
		return 144; // e da
	}
	else if (bt == 235) {
		return 145;
	}
	else if (bt == 237) {
		return 146; // i acc a
	}
	else if (bt == 236) {
		return 147;
	}
	else if (bt == 238) {
		return 148; // i da
	}
	else if (bt == 239) {
		return 149;
	}
	else if (bt == 241) {
		return 150; // n ti
	}
	else if (bt == 243) {
		return 151; // o acc a
	}
	else if (bt == 242) {
		return 152; // o acc g
	}
	else if (bt == 244) {
		return 153; // o da
	}
	else if (bt == 245) {
		return 155; // o ti
	}
	else if (bt == 250) {
		return 156; // u acc a
	}
	else if (bt == 249) {
		return 157; // u acc g
	}
	else if (bt == 251) {
		return 158;
	}
	else if (bt == 192) {
		return 203; // A acc g
	}
	else if (bt == 195) {
		return 204; // A ti
	}
	else if (bt == 213) {
		return 205; // o ti
	}
	else if (bt == 194) {
		return 229; // A da
	}
	else if (bt == 202) {
		return 230; // E da
	}
	else if (bt == 193) {
		return 231; // A acc a
	}
	else if (bt == 203) {
		return 232; // E uml
	}
	else if (bt == 200) {
		return 233; // E acc g
	}
	else if (bt == 205) {
		return 234; // I acc a
	}
	else if (bt == 206) {
		return 235; // I da
	}
	else if (bt == 207) {
		return 236; // I uml
	}
	else if (bt == 204) {
		return 237; // I acc g
	}
	else if (bt == 211) {
		return 238; // O acc a
	}
	else if (bt == 212) {
		return 239; // O da
	}
	else if (bt == 210) {
		return 241; // O acc g
	}
	else if (bt == 218) {
		return 242; // U acc a
	}
	else if (bt == 219) {
		return 243; // U da
	}
	else if (bt == 217) {
		return 244; // U acc g
	}
	
	else if (bt == 176) {
		return 161; // grad
	}
	else if (bt == 162) {
		return 162; // C |
	}
	else if (bt == 163) {
		return 163; // pound
	}
	else if (bt == 167) {
		return 164; // paragraph
	}
	else if (bt == 182) {
		return 166; // line end
	}
	else if (bt == 174) {
		return 168; // (R)
	}
	else if (bt == 169) {
		return 169; // (C)
	}
	else if (bt == 180) {
		return 171; // accent a
	}
	else if (bt == 198) {
		return 174; // A uml nor
	}
	else if (bt == 216) {
		return 175; // O uml nor
	}
	else if (bt == 177) {
		return 177; // +-
	}
	else if (bt == 165) {
		return 180; // Y=
	}
	else if (bt == 170) {
		return 187; // a_
	}
	else if (bt == 186) {
		return 188; // o_
	}
	else if (bt == 230) {
		return 190; // a uml nor
	}
	else if (bt == 248) {
		return 191; // o uml nor
	}
	else if (bt == 191) {
		return 192; // ? invers
	}
	else if (bt == 161) {
		return 193; // ! invers
	}
	else if (bt == 172) {
		return 194; // ende
	}
//	else if (bt == 171) {
//		return 199; // doppelt links
//	}
//	else if (bt == 187) {
//		return 200; // doppelt rechts
//}
//	else if (bt == 145) {
//	return 212; // ' begin
//}
//else if (bt == 146) {
//	return 213; // ' end
//}
	else if (bt == 247) {
		return 214; // division
	}
	else if (bt == 255) {
		return 216; // y uml
	}
	else if (bt == 183) {
		return 225; // punkt
	}
	else if (bt == 184) {
		return 226; // ' unten
	}
	
	else if (bt == 8725) {
		return 218; // "/"
	}
	else if (bt == 706) {
		return 220; // "<"
	}
	else if (bt == 707) {
		return 221; // ">"
	}
	
	else if (bt == 959) {
	//else if (bt == 176) { // doppelt vorhanden
		return 251;
	}
	else if (bt == 698) {
		return 253; // sekunde
	}

	else if (bt == 8224) {
		return 160; // dagger
	}
	else if (bt == 8226) {
		return 165; // bullet
	}
	else if (bt == 8482) {
		return 170; // TM
	}
	else if (bt == 8800) {
		return 173; // =|
	}
	else if (bt == 8734) {
		return 176; // oo
	}
	else if (bt == 8804) {
		return 178; // <=
	}
	else if (bt == 8805) {
		return 179; // >=
	}
	else if (bt == 956) {
		return 181; // my
	}
	else if (bt == 948) {
		return 182; // delta
	}
	else if (bt == 8721) {
		return 183; // summe
	}
	else if (bt == 8719) {
		return 184; // Pi
	}
	else if (bt == 960) {
		return 185; // pi
	}
	else if (bt == 8747) {
		return 186; // integral
	}
	else if (bt == 937) {
		return 189; // omega
	}
	else if (bt == 8730) {
		return 195; // wurzel
	}
	
	else if (bt == 402) {
		return 196; // f lat.
	}

	else if (bt == 8776) {
		return 197; // welle
	}
	else if (bt == 8710) {
		return 198; // math (dreieck)
	}
	else if (bt == 338) {
		return 206; // OE
	}
	else if (bt == 339) {
		return 207; // oe
	}
	else if (bt == 8211) {
		return 208; // En dash
	}
	else if (bt == 8212) {
		return 209; // Em dash
	}
	else if (bt == 8220) {
		return 210; // " begin
	}
	else if (bt == 8221) {
		return 211; // " end
	}
	else if (bt == 9826) {
		return 215; // rhombos
	}
	else if (bt == 376) {
		return 217; // Y uml
	}

	else if (bt == 8225) {
		return 224; // double dagger
	}
	else if (bt == 8222) {
		return 227; // " unten
	}
	else if (bt == 8240) {
		return 228; // promille
	}
	else if (bt == 9787) {
		return 240; // apple => 9787 (black smiley)
	}

	else if (bt == 8810) {
		return 199; // doppelt links
	}
	else if (bt == 8811) {
		return 200; // doppelt rechts
	}
	else if (bt == 8216) {
		return 212; // ' begin
	}
	else if (bt == 8217) {
		return 213; // ' end
	}
	else if (bt == 8230) {
		return 201; // ...
	}

	else if (bt == 9251) {
		return 202; //
	}
	else if (bt == 8848) {
		return 127; //
	}
	else if (bt == 8849) {
		return 172; //
	}
	else if (bt == 8850) {
		return 222; //
	}
	else if (bt == 8851) {
		return 223; //
	}
	else if (bt == 10048) {
		return 8;
	}
	else if (bt > 10015 && bt < 10048) {
		return (bt - 10016); // 0 ... 31
	}
	else if (bt > 8863 && bt < 8875) {
		return bt - 8864 + 245; // ab 0x22A0
	}
	
	return 63;
}


protected function getByteInWinAnsi (bt:uint):uint
{
	if ((bt > 31 && bt < 128) || bt == 9 || bt == 10 || bt == 13 || (bt > 160  && bt < 256) || bt == 145 || bt == 146) {
		return bt;
	}
	else if (bt == 8364) { // "\u20ac" Euro
		return 128;
	}
	else if (bt == 8810) { // doppelt links
		return 171;
	}
	else if (bt == 8811) { // doppelt rechts
		return 187;
	}
	else if (bt > 10015 && bt < 10048) {
		return bt - 10016; // 0 ... 31
	}
	else if (bt > 8847 && bt < 8882) { // ab 0x2290
		return bt - 8848 + 127;
	}
	return 63;
}

protected function getBytesInUTF8 (bt:uint):Array
{
	var bytes:Array = new Array();
	var tmp:uint = 0;

	if (bt < 128) {
		bytes.push(bt);
	}
	else if (bt < 2048) {
		tmp = 192 + bt / 64;
		bytes.push(tmp);
		var b0:uint = bt % 64;
		tmp = 128 + b0;
		bytes.push(tmp);
	}
	else if (bt < 65536) {
		if (bt >= 0xD800 && bt <= 0xDB7F) {
			uft16SuHigh_ = bt;
		}
		else if (bt >= 0xDC00 && bt <= 0xDFFF) {
			tmp = bt - 0xDC00 + (uft16SuHigh_ - 0xD800) * 1024 + 65536;
			var b2:uint = tmp / 262144; // 2 ^ 18
			var tmp2:uint = 240 + b2;
			bytes.push(tmp2);
			b2 = tmp / 65536;
			b2 = b2 % 4;
			var b3:uint = tmp % 65536;
			b3 = b3 / 4096;
			tmp2 = 128 + b2 * 16 + b3;
			bytes.push(tmp2);
			b2 = tmp % 4096;
			tmp2 = 128 + b2 / 64;
			bytes.push(tmp2);
			b2 = tmp % 64;
			tmp2 = 128 + b2;
			bytes.push(tmp2);
		}
		else { // simple UTF16
			tmp = 224 + bt / 4096;
			bytes.push(tmp);
			//bytes.push(224 + bt / 4096);
			var b1:uint = bt % 4096;
			tmp = 128 + b1 / 64;
			bytes.push(tmp);
			//bytes.push(128 + b1 / 64);
			b1 = bt % 64;
			tmp = 128 + b1;
			bytes.push(tmp);
			//bytes.push(128 + bt % 64);
		}
	}

	return bytes;
}


protected function OnTextChanging (event:TextOperationEvent):void
{
	//if (event.operation == InsertTextOperation) {
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	if (opstr == "[object CopyOperation]") {
		return;
	}
	isModified_ = true;
	if (this.title.length < 3) {
		this.title += " *";
	}
	else if (this.title.charAt (this.title.length - 1) != "*" && this.title.charAt (this.title.length - 2) != " ") {
		this.title += " *";
	}
}

protected function OnTextSelectionChange (event:FlexEvent):void
{
	//const var cman:ICursorManager = txt.cursorManager;
	//var xpos:int = txt.cursorManager.currentCursorXOffset;
	//var ypos:int = txt.cursorManager.currentCursorYOffset;
	//tx_cursor.text = "Line " + xpos.toString() + " Pos " + ypos.toString();
	
	//WriteDebugLogMessage("OnTextSelectionChange()");
	//var anc:int = edittx.selectionAnchorPosition;
	var anc:int = edittx.selectionActivePosition;
	tx_Index.text = "P: " + (anc + 1).toString();
	getLineAndColumnNumber (anc);
	tx_Line.text = "L: " + curLineNum_.toString();
	tx_Column.text = "C: " + curColNum_.toString();
}

protected function OnRadioBtnGroup (event:ItemClickEvent):void
{
	isMacEncoding_ = rb_mac.selected;
	isWinEncoding_ = rb_win.selected;
	isUtf8Encoding_ = rb_utf8.selected;
	isMacEncSetting_ = isMacEncoding_;
	isWinEncSetting_ = isWinEncoding_;
	isUtf8EncSetting_ = isUtf8Encoding_;
	linePositions_ = new Array();
	ShowTextContent();
}

private function getLineAndColumnNumber (pos:int):void
{
	curLineNum_ = 0;
	curColNum_ = 0;
	for (var ix:uint = 0; ix < linePositions_.length; ix++) {
		if (pos < linePositions_[ix].kStart + linePositions_[ix].kLength) {
			curLineNum_ = ix + 1;
			curColNum_ = pos - linePositions_[ix].kStart + 1;
			return;
		}
	}
}

protected function getInfo():void
{
	var cc:String = ".";
	var cw:String = ".";
	if (caseSensitive_) {
		cc = "C";
	}
	if (wholeWords_) {
		cw = "W";
	}
	tx_Info.text = cc + " " + cw;
}

protected function RefreshStore():void
{
	tx_Mem.text = ".";
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr1().length > 0) {
		tx_Mem.text = "1";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr2().length > 0) {
		tx_Mem.text += "2";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr3().length > 0) {
		tx_Mem.text += "3";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr4().length > 0) {
		tx_Mem.text += "4";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr5().length > 0) {
		tx_Mem.text += "5";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr6().length > 0) {
		tx_Mem.text += "6";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr7().length > 0) {
		tx_Mem.text += "7";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr8().length > 0) {
		tx_Mem.text += "8";
	}
	else {
		tx_Mem.text += ".";
	}
	if (FlexGlobals.topLevelApplication.prefs_.getEditstr9().length > 0) {
		tx_Mem.text += "9";
	}
	else {
		tx_Mem.text += ".";
	}
}


//=======================================================
/*
\history

WGo-2014-12-18: created
WGo-2015-01-05: editing + saving works
WGo-2015-01-07: nearly full conversion of Mac Roman
WGo-2015-03-13: 9 memories, onAfterTextEdit()
WGo-2015-03-18: bugfix after saving, content_ had old text
WGo-2015-03-24: text search
WGo-2015-03-26: replace
WGo-2015-04-08: undo, specially for insertion from one of the memories
WGo-2015-11-03: new empty file had invalid content_
WGo-2015-11-24: UTF8 decoding + encoding
WGo-2015-11-25: line + column info for UTF8 corrected
WGo-2015-11-30: read and write 4-byte UTF8, but the font does not display them correctly

*/

