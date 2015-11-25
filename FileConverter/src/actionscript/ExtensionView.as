import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.events.FlexNativeWindowBoundsEvent;
import mx.events.ItemClickEvent;
import mx.core.FlexGlobals;

import spark.events.TextOperationEvent;


private var docPath_:String = "";
private var cust_w_:int = 400;
private var isMacEncoding_:Boolean = false;

static private var extension_:String = "";

private function OnWindowComplete():void
{
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	edittx.addEventListener (KeyboardEvent.KEY_DOWN, OnEditKeyDown);
	edittx.text = extension_;
	edittx.setFocus();
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
	var key:uint = event.keyCode;
	if (key == Keyboard.ENTER) {
		//extension_ = edittx.text;
		FlexGlobals.topLevelApplication.ChangeFileExtension (extension_);
		this.close();
		event.preventDefault();
	}
}


protected function OnCancel (event:FlexEvent):void
{
	this.close();
}

protected function OnOK (event:FlexEvent):void
{
	FlexGlobals.topLevelApplication.ChangeFileExtension (extension_);
	this.close();
}


protected function OnTextChanged (event:TextOperationEvent):void
{
	extension_ = edittx.text;
}

protected function OnTextSelectionChange (event:FlexEvent):void
{
}


//=======================================================
/*
\history

WGo-2015-01-09: created
WGo-2015-02-11: event change (after change) is used instead of changing

*/

