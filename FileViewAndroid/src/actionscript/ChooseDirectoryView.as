import flash.events.Event;
import flash.events.GestureEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import mx.core.FlexGlobals;
import mx.events.FlexEvent;

import spark.events.IndexChangeEvent;
import spark.events.PopUpEvent;

import actionscript.Preferences;

import views.EditorView;


static private var curDirectory_:File = null;
[Bindable] private var copyright:String = "© axaio software gmbh 2015";
private var full_len:Number = 0;
private var short_len:Number = 0;

//=======================================================

protected function OnViewComplete (event:FlexEvent):void
{
	filelist.addEventListener(IndexChangeEvent.CHANGE, onSelection);
	filelist.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
	
	if (curDirectory_ == null) {
		curDirectory_ = File.desktopDirectory;
	}
	showFileList();
	
}

protected function onSelection (event:IndexChangeEvent):void
{
	OnFileChoose();
}

protected function onDoubleClick (event:MouseEvent):void
{
	var selStr:String = filelist.selectedItem.label.toString();
	
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs.isDirectory) {
		curDirectory_ = selFs;
		showFileList();
	}
}

protected function OnFileChoose():void
{
	//var ix:int = filelist.selectedIndex;
}

protected function onButtonUp (event:MouseEvent):void
{
	var par:File = curDirectory_.parent;
	if (par != null) {
		curDirectory_ = par;
		//st_path.text = curDirectory_.nativePath;
		showFileList();
	}
}

protected function onButtonHome (event:MouseEvent):void
{
	curDirectory_ = File.desktopDirectory;
	//st_path.text = curDirectory_.nativePath;
	showFileList();
}

protected function onButtonDir1 (event:MouseEvent):void
{
	var prefs:Preferences = new Preferences(); 
	var p:String = prefs.getCustomPath1();
	if (p.length > 0) {
		var newDir:File = new File (p);
		if (newDir.exists) {
			curDirectory_ = newDir;
			showFileList();
		}
	}
}

protected function onButtonDir2 (event:MouseEvent):void
{
	var prefs:Preferences = new Preferences(); 
	var p:String = prefs.getCustomPath2();
	if (p.length > 0) {
		var newDir:File = new File (p);
		if (newDir.exists) {
			curDirectory_ = newDir;
			showFileList();
		}
	}
}

protected function onBtChoose (event:MouseEvent):void
{
	this.data.kDirectory = curDirectory_.nativePath;
	if (filelist.selectedIndex >= 0) {
		var selStr:String = filelist.selectedItem.label.toString();
		var selFs:File = curDirectory_.resolvePath(selStr);
		if (selFs.isDirectory) {
			this.data.kDirectory = selFs.nativePath;
		}
	}
	navigator.popView();
}

protected function onBtCancel (event:MouseEvent):void
{
	this.data.kDirectory = "";
	navigator.popView();
}

override public function createReturnObject():Object
{
	return this.data.kDirectory;
}

private function showFileList():void
{
	filelist.dataProvider.removeAll();
	var files:Array = getFileListing (curDirectory_);
	if (files == null) {
		return;
	}
	for (var i1:uint = 0; i1 < files.length; i1++) {
		var obj:Object = new Object();
		obj.label = files[i1];
		obj.data = "d";
		filelist.dataProvider.addItem (obj);
	}
	st_path.text = curDirectory_.nativePath;
}

private function getFileListing (dir:File):Array
{
	var retval:Array = new Array();
	if (dir == null) {
		return retval;
	}
	try {
		var files:Array = dir.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			if (f.isDirectory) {
				retval.push (f.name);
			}
			else {
				//filesar.push (f.name);
			}
		}
		retval.sort();
	}
	catch (error:Error) {
	}
	return retval;
}


//=======================================================
/*
\history

WGo-2015-02-06: Created

*/

