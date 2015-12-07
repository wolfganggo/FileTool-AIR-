import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.events.TouchEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Timer;

import mx.events.FlexEvent;
import mx.events.ItemClickEvent;

import spark.events.IndexChangeEvent;
import spark.events.PopUpEvent;
import spark.events.TextOperationEvent;

import flashx.textLayout.elements.TextFlow;
import flashx.textLayout.operations.FlowOperation;

import views.AlertDialog;


private var file_:File = null;
private var short_len:Number = 0;
private var content_:Array = null;
private var docPath_:String = "";
private var lineEndings_:int = -1; // 0 = lf, 1 = cr, 2 = cr/lf
private var linePositions_:Array = null;
private var curLineNum_:int = 0;
private var curColNum_:int = 0;
private var TextLengthInit_:int = 0; // initial length, where line end is always 1 char (CR+LF = 1 char)
private var isMacEncoding_:Boolean = false;
private var isWinEncoding_:Boolean = false;
private var isUTF8Encoding_:Boolean = false;
static private var isMacEncSetting_:Boolean = false;
static private var isWinEncSetting_:Boolean = false;
static private var isUTF8EncSetting_:Boolean = false;
private var initialized_:Boolean = false;
private var isModified_:Boolean = false;
private var uft8Byte1_:uint = 0;
private var uft8Byte2_:uint = 0;
private var uft8Byte3_:uint = 0;
private var uft16SuHigh_:uint = 0;

//=======================================================

protected function OnViewComplete (event:FlexEvent):void
{
	//if (this.data.kTouch == true) {
	//	tx_edit.text = "tap handler\n\n"; 
	//}
	if (isMacEncSetting_) {
		rb_mac.selected = true;
	}
	else if (isWinEncSetting_) {
		rb_win.selected = true;
	}
	else {
		rb_ascii.selected = true;
	}
	
	isMacEncoding_ = isMacEncSetting_;
	isWinEncoding_ = isWinEncSetting_;
	isUTF8Encoding_ = isUTF8EncSetting_;

	try {
		content_ = new Array();
		file_ = data.kFile;
		if (file_ == null) {
			return;
		}
		this.title = file_.name;
		var fstr:FileStream = new FileStream();
		fstr.open (file_, FileMode.READ);
		var len:Number = file_.size;
		if (len == 0 || len > 50000000) { // max 50 MB
			fstr.close();
			return;
		}
		for (var ix:uint = 0; ix < len; ix++) {
			content_.push (fstr.readUnsignedByte());
		}
		fstr.close();
		
		ShowTextContent();
		
		initialized_ = true;
	}
	catch (e:Error) {
	}
	
	var tmr:Timer = new Timer(400);
	tmr.addEventListener (TimerEvent.TIMER, onTextTimer);
	tmr.start();
}

private function onTextTimer (event:TimerEvent):void
{
	processTextSelectionChange();
}


protected function onTouchTap (event:TouchEvent):void
{
}

protected function onMouseClick (event:MouseEvent):void
{
}

protected function onButtonClose(event:MouseEvent):void
{
	if (isModified_) {
		var alert:AlertDialog = new AlertDialog();
		alert.message = "Save modified File ?";
		alert.addEventListener('close', closeHandler);
		alert.open (this, true);
	}
	else {
		navigator.popView();
	}
}

protected function closeHandler(event:PopUpEvent):void
{
	if (event.commit) {
		saveFile();
	}
	navigator.popView();
}


protected function onButtonSave(event:MouseEvent):void
{
	saveFile();
}

private function saveFile():void 
{
	if (file_ == null) {
		return;
	}
	var stream:FileStream = new FileStream();
	stream.open (file_, FileMode.WRITE);
	
	var len:uint = tx_edit.text.length;
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = tx_edit.text.charCodeAt(ix);
		if (bt == 10) {
			if (lineEndings_ == 1) {
				stream.writeByte(13);
			}
			else if (lineEndings_ == 2) {
				stream.writeByte(13);
				stream.writeByte(10);
			}
			else {
				stream.writeByte(bt);
			}
		}
		else if (isMacEncoding_) {
			stream.writeByte (getByteInMacRoman (bt));
		}
		else if (isWinEncoding_) {
			stream.writeByte (getByteInWinAnsi (bt));
		}
		else if (isUTF8Encoding_) {
			var bts:Array = getBytesInUTF8 (bt);
			for (var iy:uint = 0; iy < bts.length; iy++) {
				stream.writeByte (bts[iy]);
				content_.push (bts[iy]);
			}
		}
		else {
			stream.writeByte (bt);
		}
	}
	
	stream.close();
	isModified_ = false;
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
	tx_index.text = "Ix: 0";
	tx_line.text = "L: 0";
	tx_column.text = "C: 0";
	linePositions_ = new Array();
	
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
			else if (isUTF8Encoding_) {
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
	
	tx_edit.text = content;
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
		return "\u00e1"; // a acc a
	}
	else if (bt == 136) {
		return "\u00e2"; // a acc g
	}
	else if (bt == 137) {
		return "\u00e3"; // a dach
	}
	else if (bt == 139) {
		return "\u00e4"; // a ti
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
		return "/";
	}
	else if (bt == 220) {
		return "<";
	}
	else if (bt == 221) {
		return ">";
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
		return String.fromCharCode(176); // grad
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

protected function getByteInMacRoman (bt:uint):uint
{
	if ((bt > 31 && bt < 128) || bt == 9 || bt == 10 || bt == 13) {
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
	else if (bt == 226) {
		return 136; // a acc g
	}
	else if (bt == 227) {
		return 137; // a dach
	}
	else if (bt == 228) {
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
	else if (bt == 176) {
		return 251; // grad
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
	else if (bt == 8776) {
		return 197; // welle
	}
	else if (bt == 8710) {
		return 198; // math (dreieck)
	}
		//	else if (bt == 8424) {
		//		return 201; // ...
		//	}
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
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	if (!initialized_ || opstr == "[object CopyOperation]") {
		return;
	}
	isModified_ = true;
	if (this.title.charAt (this.title.length - 1) != "*") {
		this.title += " *";
	}
}

protected function OnTextSelectionChange (event:FlexEvent):void
{
	processTextSelectionChange(); // not handled in mobile
}

protected function processTextSelectionChange():void
{
	var anc:int = tx_edit.selectionAnchorPosition;
	tx_index.text = "Ix: " + (anc + 1).toString();
	getLineAndColumnNumber (anc);
	tx_line.text = "L: " + curLineNum_.toString();
	tx_column.text = "C: " + curColNum_.toString();
}

protected function OnRadioBtnGroup (event:ItemClickEvent):void
{
	isMacEncoding_ = rb_mac.selected;
	isWinEncoding_ = rb_win.selected;
	isUTF8Encoding_ = rb_utf8.selected;
	isMacEncSetting_ = isMacEncoding_;
	isWinEncSetting_ = isWinEncoding_;
	isUTF8EncSetting_ = isUTF8Encoding_;
	linePositions_ = new Array();
	initialized_ = false;
	ShowTextContent();
	initialized_ = true;
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

//=======================================================
/*
\history

WGo-2015-02-05: Created
WGo-2015-12-01: Read + write UTF8

*/

