import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.system.System;
import flash.ui.Keyboard;
import flash.utils.Timer;

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
private var rawContentString_:String = ""; // without line breaks
private var linePositions_:Array = null;
private var TextLengthInit_:int = 0;
private var lineLength_:int = 128;
private var isModified_:Boolean = false;
private var lastPos_:int = -1;
private var lastInsertPos_:int = -1;

static private var searchStr_:String = "";

private var curName_:String = "";
private var findDlg_:FindBinDialog = null;

private var hexInputActive_:Boolean = false;
private var hexInputStr_:String = "";


private function OnWindowComplete():void
{
	this.nativeWindow.x = 50;
	this.nativeWindow.y = 0;
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
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
	FlexGlobals.topLevelApplication.setTextBinViewParameter (this.width, this.height);
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
	//linePositions_ = new Array();

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
	var len:uint = content_.length;
	var content:String = "";
	tx_Index.text = "Pos: 0";
	edittx.text = "";
	
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = content_[ix];
		if (ix > 0 && (ix % lineLength_ == 0)) {
			content += "\n";
		}
		var curCh:String = readMacRoman (bt);
		content += curCh;
		rawContentString_ += curCh;
	}
	//TextLengthInit_ = ix_txt;
	edittx.text = content;
}

static private function readMacRoman (bt:uint):String
{
	if (bt > 31 && bt < 127) {
		return String.fromCharCode(bt);
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
		return String.fromCharCode(959); // grad
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
	else if (key == Keyboard.J && isControlKey) {
		hexInputActive_ = true;
		hexInputStr_ = "";
		tx_status.text = "hex input active";
		return;
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
		findDlg_ = new FindBinDialog();
		findDlg_.editView_ = this;
		findDlg_.setSearchString (edittx.text.substring (edittx.selectionAnchorPosition, edittx.selectionActivePosition));
		findDlg_.open();
	}
	
	if (hexInputActive_) {
		if (hexInputStr_.length < 2 && key >= Keyboard.NUMBER_0 && key < Keyboard.G) {
			hexInputStr_ += String.fromCharCode(key);
			if (hexInputStr_.length == 2) {
				edittx.insertText (readMacRoman (getByteFromHexInput(hexInputStr_)));
				hexInputActive_ = false;
				hexInputStr_ = "";
				tx_status.text = "Cmd/Ctrl-J for hex input";
				isModified_ = true;
				if (this.title.charAt (this.title.length - 1) != "*") {
					this.title += " *";
				}
				lastPos_ = edittx.selectionActivePosition;
				getRawTextAndUpdate(true);
			}
			event.preventDefault();
		}
		else {
			hexInputActive_ = false;
			tx_status.text = "Cmd/Ctrl-J for hex input";
		}
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
		if (bt == 10) {
			continue;
		}
		var mb:uint = getByteInMacRoman (bt);
		stream.writeByte (mb);
		content_.push(mb);
	}
	
	//stream.writeUTFBytes(str);
	stream.close();
	isModified_ = false;
	this.title = target.name;

	//linePositions_ = new Array();
	ShowTextContent();
}

protected function getByteInMacRoman (bt:uint):uint
{
	if (bt > 31 && bt < 127) {
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

	else if (bt == 402) {
		return 196; // f lat.
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
	
	else if (bt == 8725) {
		return 218; // "/"
	}
	else if (bt == 706) {
		return 220; // "<"
	}
	else if (bt == 707) {
		return 221; // ">"
	}
	
	else if (bt == 183) {
		return 225; // punkt
	}
	else if (bt == 184) {
		return 226; // ' unten
	}
	else if (bt == 959) {
	//else if (bt == 176) { // doppelt vorhanden
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


protected function OnTextChanging (event:TextOperationEvent):void
{
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	if (opstr == "[object CopyOperation]") {
		return;
	}
	//trace("OnTextChanging FlowOperation: " +  opstr); // [object UndoOperation]
	lastInsertPos_ = edittx.selectionActivePosition;
}


protected function OnTextHasChanged (event:TextOperationEvent):void
{
	var op:FlowOperation = event.operation;
	var opstr:String = String (op);
	if (opstr == "[object CopyOperation]") {
		return;
	}
	isModified_ = true;
	if (this.title.charAt (this.title.length - 1) != "*") {
		this.title += " *";
	}
	lastPos_ = edittx.selectionActivePosition;
	var updatetimer:Timer = new Timer(20, 1);
	updatetimer.addEventListener (TimerEvent.TIMER, onUpdateTimer);
	updatetimer.start();
}

private function onUpdateTimer (event:TimerEvent):void
{
	getRawTextAndUpdate(true);
}

protected function OnTextSelectionChange (event:FlexEvent):void
{
	var pos:int = edittx.selectionActivePosition;
	var curUTF16Char:uint = edittx.text.charCodeAt (pos);
	var curChar:uint = getByteInMacRoman (curUTF16Char);
	var linecount:int = (pos + 1) / (lineLength_ + 1);
	pos = pos + 1 - linecount;
	tx_Index.text = "Pos: " + pos.toString() + "   0x" + getHexAscii (pos.toString(16));
	if (curUTF16Char > 31) {
		tx_code.text = "Code: " + curChar.toString() + "   0x" + getHexAscii (curChar.toString(16));
	}
	else {
		tx_code.text = "Code: ";
	}
}

private function getHexAscii (s:String):String
{
	var res:String = s.toLocaleUpperCase();
	if (res.length < 2) {
		res = "0" + res;
	}
	return res;
}

static private function getByteFromHexInput (hexStr:String):uint
{
	var bt:uint = 63;
	
	if (hexStr.length < 2) {
		return bt;
	}
	var b1:uint = hexStr.charCodeAt(0);
	var b2:uint = hexStr.charCodeAt(1);

	if (b2 > 47 && b2 < 58) {
		bt = b2 - 48;
	}
	else if (b2 > 64 && b2 < 71) {
		bt = b2 - 55;
	}
	else if (b2 > 96 && b2 < 103) {
		bt = b2 - 87;
	}
	else {
		return bt;
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
	else {
		return 63;
	}
	return bt;
}

static public function getMacRomanCharFromHex (hexStr:String):String
{
	return readMacRoman (getByteFromHexInput (hexStr));
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
	searchStr_ = findDlg_.findString_;
	if (replace) {
		replaceText (findDlg_.replaceString_, all);
	}
	else {
		findText();
	}
	edittx.setFocus();
}

private function findText():void 
{
	var curPos:int = edittx.selectionActivePosition;
	edittx.selectRange (curPos, curPos);
	
	if (searchStr_.length == 0) {
		return;
	}
	//var allText:String = edittx.text;
	//var pos:int = findNextIndexOf (searchStr_, allText, curPos);
	var pos:int = findNextIndexOf (searchStr_, rawContentString_, curPos);
	if (pos == -1) {
		pos = findNextIndexOf (searchStr_, rawContentString_, 0);
	}
	if (pos != -1) {
		setFoundSelection (pos, pos + searchStr_.length);
		//edittx.scrollToRange (pos, pos + searchStr_.length);
		//edittx.selectRange (pos, pos + searchStr_.length);
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
	//var allText:String = edittx.text;
	
	var pos:int = 0; 
	var foundpos:int = -1; 
	var lastpos:int = -1; 
	do {
		//foundpos = findNextIndexOf (searchStr_, allText, pos);
		foundpos = findNextIndexOf (searchStr_, rawContentString_, pos);
		if (foundpos > curPos - searchStr_.length - 1 || foundpos < 0) {
			break;
		}
		pos += searchStr_.length;
		lastpos = foundpos;
	} while (foundpos > -1);
	
	if (lastpos != -1) {
		setFoundSelection (lastpos, lastpos + searchStr_.length);
		//edittx.scrollToRange (lastpos, lastpos + searchStr_.length);
		//edittx.selectRange (lastpos, lastpos + searchStr_.length);
	}
	else {
		edittx.selectRange (curPos, curPos);
	}
}

private function setFoundSelection (first:int, second:int):void 
{
	var begSel:int = first + first / lineLength_;
	var endSel:int = second + second / lineLength_;
	edittx.scrollToRange (begSel, endSel);
	edittx.selectRange (begSel, endSel);
}

private function findNextIndexOf (srchstr:String, txt:String, pos:int):int 
{
	var curPos:int = pos;
	var len:int = srchstr.length;
	var foundPos:int = -1;
	do {
		foundPos = txt.indexOf (srchstr, curPos);
		if (foundPos < 0) {
			break;
		}
		curPos += srchstr.length;
	} while (foundPos < 0 && curPos < txt.length);
	return foundPos;
}

public function findTextCount (s:String):int 
{
	if (s.length == 0) {
		return 0;
	}
	var retval:int = 0;
	//var allText:String = edittx.text;
	var pos:int = -1;
	do {
		if (pos >= 0) {
			pos += s.length;
		}
		else {
			pos = 0;
		}
		pos = rawContentString_.indexOf (s, pos);
		//pos = allText.indexOf (s, pos);
		if (pos != -1) {
			retval++;
		}
		if (retval > 999) {
			break;
		}
	} while (pos >= 0);
	return retval;
}

private function replaceText (newStr:String, all:Boolean):void 
{
	var beginPos:int = edittx.selectionAnchorPosition;
	var endPos:int = edittx.selectionActivePosition;
	var part3:String = "";
	
	if (!all) {
		if (beginPos < 0 || endPos < 0 || endPos <= beginPos) {
			return;
		}
		edittx.selectRange (endPos, endPos);
		
		part3 = edittx.text.substring (endPos);
		edittx.text = edittx.text.substring (0, beginPos);
		edittx.text += newStr + part3;
		getRawTextAndUpdate(false);
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
			getRawTextAndUpdate(false);
			
			findText();
			
		} while (endPos > -1);
	}
	
	isModified_ = true;
	if (this.title.charAt (this.title.length - 1) != "*") {
		this.title += " *";
	}
}

private function getRawTextAndUpdate (updateSelection:Boolean):void 
{
	var len:int = edittx.text.length;
	rawContentString_ = "";
	var newContent:String = "";

	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = edittx.text.charCodeAt(ix);
		if (bt == 10) {
			continue;
		}
		//rawContentString_ += edittx.text.charAt(ix);
		rawContentString_ += String.fromCharCode(bt);
	}

	var rawlen:uint = rawContentString_.length;
	for (var iy:uint = 0; iy < rawlen; iy++) {
		if (iy > 0 && (iy % lineLength_ == 0)) {
			newContent += "\n";
		}
		newContent += rawContentString_.charAt(iy);
	}
	edittx.text = newContent;
	if (updateSelection && lastPos_ != -1) {
		var linesBefore:int = (lastInsertPos_) / (lineLength_ + 1);
		var linesAfter:int = (lastPos_) / (lineLength_ + 1);
		if (linesBefore < linesAfter) {
			lastPos_++; // the new selection is now after a line break
		}
		edittx.scrollToRange (lastPos_, lastPos_);
		edittx.selectRange (lastPos_, lastPos_);
	}
}

//=======================================================
/*
\history

WGo-2015-03-26: created
WGo-2015-03-27: all character codes verified
WGo-2015-03-31: "find" works
WGo-2015-04-01: "find" over line breaks with correct selection
WGo-2015-04-07: find dialog remembers entries
WGo-2015-04-08: hex input with Cmd-J also in find dialog
WGo-2015-11-03: new empty file had invalid content_

*/

