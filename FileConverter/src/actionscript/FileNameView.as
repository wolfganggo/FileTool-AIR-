import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.events.FlexNativeWindowBoundsEvent;
import mx.events.ItemClickEvent;

import spark.events.TextOperationEvent;


//private var curName_:String = "";
private var storeActive_:Boolean = false;

static private var name_1_:String = "";
static private var name_2_:String = "";
static private var name_3_:String = "";
static private var name_4_:String = "";
static private var name_5_:String = "";
static private var name_6_:String = "";
static private var name_7_:String = "";
static private var name_8_:String = "";
static private var name_9_:String = "";

private function OnWindowComplete():void
{
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	edittx.addEventListener (KeyboardEvent.KEY_DOWN, OnEditKeyDown);
	//edittx.text = extension_;
	edittx.setFocus();
	RefreshStore();
}

public function SetDefaultName (name:String):void
{
	edittx.text = name;
}

protected function OnKeyDown(event:KeyboardEvent):void
{
	//var isControlKey:Boolean = event.altKey;
	var isControlKey:Boolean = event.ctrlKey;
	var isShiftKey:Boolean = event.shiftKey;
	var key:uint = event.keyCode;
	if (key == Keyboard.ESCAPE) {
		this.close();
	}
}

protected function OnEditKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey;
	var key:uint = event.keyCode;
	if (key == Keyboard.ENTER) {
		//extension_ = edittx.text;
		FlexGlobals.topLevelApplication.ChangeFileName (edittx.text);
		this.close();
		event.preventDefault();
	}
	else if (key == Keyboard.C && isControlKey) {
		storeActive_ = true;
	}
	else if (key >= Keyboard.NUMBER_1 && key <= Keyboard.NUMBER_9 && storeActive_) {
		var pos:int = key - Keyboard.NUMBER_1 + 1;
		storeActive_ = false;
		var selStr:String = "";
		if (edittx.selectionActivePosition > edittx.selectionAnchorPosition) {
			selStr = edittx.text.substring (edittx.selectionAnchorPosition, edittx.selectionActivePosition);
		}
		else {
			selStr = edittx.text.substring (edittx.selectionActivePosition, edittx.selectionAnchorPosition);
		}
		if (selStr.length == 0) {
			selStr = edittx.text;
		}
		switch (pos) {
			case 1: name_1_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr1(selStr);
				break;
			case 2: name_2_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr2(selStr);
				break;
			case 3: name_3_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr3(selStr);
				break;
			case 4: name_4_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr4(selStr);
				break;
			case 5: name_5_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr5(selStr);
				break;
			case 6: name_6_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr6(selStr);
				break;
			case 7: name_7_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr7(selStr);
				break;
			case 8: name_8_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr8(selStr);
				break;
			case 9: name_9_ = selStr;
				FlexGlobals.topLevelApplication.prefs_.setMemstr9(selStr);
				break;
		}
		RefreshStore();
		event.preventDefault();
	}
	else {
		storeActive_ = false;
	}

	if (key >= Keyboard.NUMBER_1 && key <= Keyboard.NUMBER_9 && isControlKey) {
		var pos2:int = key - Keyboard.NUMBER_1 + 1;
		switch (pos2) {
			case 1: edittx.insertText(name_1_);
				break;
			case 2: edittx.insertText(name_2_);
				break;
			case 3: edittx.insertText(name_3_);
				break;
			case 4: edittx.insertText(name_4_);
				break;
			case 5: edittx.insertText(name_5_);
				break;
			case 6: edittx.insertText(name_6_);
				break;
			case 7: edittx.insertText(name_7_);
				break;
			case 8: edittx.insertText(name_8_);
				break;
			case 9: edittx.insertText(name_9_);
				break;
		}
	}
}


protected function RefreshStore():void
{
	name_1_ = FlexGlobals.topLevelApplication.prefs_.getMemstr1();
	name_2_ = FlexGlobals.topLevelApplication.prefs_.getMemstr2();
	name_3_ = FlexGlobals.topLevelApplication.prefs_.getMemstr3();
	name_4_ = FlexGlobals.topLevelApplication.prefs_.getMemstr4();
	name_5_ = FlexGlobals.topLevelApplication.prefs_.getMemstr5();
	name_6_ = FlexGlobals.topLevelApplication.prefs_.getMemstr6();
	name_7_ = FlexGlobals.topLevelApplication.prefs_.getMemstr7();
	name_8_ = FlexGlobals.topLevelApplication.prefs_.getMemstr8();
	name_9_ = FlexGlobals.topLevelApplication.prefs_.getMemstr9();
	tx_1.text = "1: " + name_1_;
	tx_2.text = "2: " + name_2_;
	tx_3.text = "3: " + name_3_;
	tx_4.text = "4: " + name_4_;
	tx_5.text = "5: " + name_5_;
	tx_6.text = "6: " + name_6_;
	tx_7.text = "7: " + name_7_;
	tx_8.text = "8: " + name_8_;
	tx_9.text = "9: " + name_9_;
}

protected function OnCancel (event:FlexEvent):void
{
	this.close();
}

protected function OnOK (event:FlexEvent):void
{
	FlexGlobals.topLevelApplication.ChangeFileName (edittx.text);
	this.close();
}


protected function OnTextChanged (event:TextOperationEvent):void
{
}

protected function OnTextSelectionChange (event:FlexEvent):void
{
}


//=======================================================
/*
\history

WGo-2015-01-09: created
WGo-2015-02-11: event change (after change) is used instead of changing
WGo-2015-04-14: edittx uses selection for copy + insert

*/

