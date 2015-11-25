import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;

import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.events.ItemClickEvent;


private function OnWindowComplete():void
{
	this.addEventListener (KeyboardEvent.KEY_DOWN, OnKeyDown);
	rb_in2.selected = true;
	rb_out2.selected = true;
	tx_begin.setFocus();
}


protected function OnCancel (event:FlexEvent):void
{
	this.close();
}

protected function OnOK (event:FlexEvent):void
{
	actionOK();
	event.preventDefault();
}

private function actionOK():void
{
	bt_ok.label = "wait...";
	this.enabled = false;

	var tm:Timer = new Timer(50, 1);
	tm.addEventListener(TimerEvent.TIMER, OnAfterKeyTimer);
	tm.start();
}

private function OnAfterKeyTimer(event:TimerEvent):void
{
	var beg:int = 0;
	if (tx_begin.text.length > 0) {
		beg = parseInt (tx_begin.text, 10);
	}
	var len:int = 0;
	if (tx_len.text.length > 0) {
		len = parseInt (tx_len.text, 10);
	}
	if (! ch_ms.selected) {
		beg *= 1000;
		len *= 1000;
	}
	var inseconds:int = 0;
	var outseconds:int = 0;
	if (ch_fadeIn.selected) {
		if (rb_in2.selected) {
			inseconds = 2;
		}
		else if (rb_in5.selected) {
			inseconds = 5;
		}
		else if (rb_in10.selected) {
			inseconds = 10;
		}
	}
	if (ch_fadeOut.selected) {
		if (rb_out2.selected) {
			outseconds = 2;
		}
		else if (rb_out5.selected) {
			outseconds = 5;
		}
		else if (rb_out10.selected) {
			outseconds = 10;
		}
	}
	FlexGlobals.topLevelApplication.EditWaveFile (beg, len, ch_norm.selected, ch_swap.selected, ch_convert.selected, inseconds, outseconds);
	this.close();
}

protected function OnKeyDown(event:KeyboardEvent):void
{
	var isControlKey:Boolean = event.ctrlKey;
	var key:uint = event.keyCode;
	if (key == Keyboard.ESCAPE) {
		this.close();
	}
	if (key == Keyboard.ENTER) {
		actionOK();
		event.preventDefault();
	}
}


//=======================================================
/*
\history

WGo-2015-01-30: created
WGo-2015-02-02: timer needed to change the button text + disable dialog, handle ESCAPE + ENTER
WGo-2015-03-20: fade in and out

*/

