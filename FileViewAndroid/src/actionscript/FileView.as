import flash.events.Event;
import flash.events.GestureEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.events.TouchEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Timer;

import mx.events.FlexEvent;
import mx.events.StateChangeEvent;
import mx.managers.IFocusManager;
import mx.managers.IFocusManagerComponent;

import spark.components.Group;
import spark.components.supportClasses.ViewReturnObject;
import spark.core.NavigationUnit;
import spark.events.IndexChangeEvent;
import spark.events.PopUpEvent;
import spark.events.ViewNavigatorEvent;

import actionscript.Preferences;
import actionscript.Utilities;

import views.EditorView;
import views.PictInfoDialog;
import views.PictureView;
import views.ThumbnailView;


static public var curDirectory_:File = null;
[Bindable] private var copyright:String = "axaio software gmbh 2015";
private var versionStr:String = "FileViewAndroid Version 0.1.1"; // change also in FileViewAndroid-app.xml
private var full_len:Number = 0;
private var short_len:Number = 0;
static private var retData_:Object = null;
public var prefs_:Preferences = null;
private var filelist_:Array = null;
static private var multipleSelection_:Boolean = false;
private var imgPortrait_:Boolean = false;
private var fileCountInCurDir_:int = 0;
private var isLongPress_:Boolean = false;
private var mouseDownTimerActive_:Boolean = false;
private var mouseDownTimerValid_:Boolean = false;
private var isRangeSelection_:Boolean = false;
private var isRangeSelected_:Boolean = false;
private var firstSelOfRange_:int = -1;
private var mouseX_:Number = 0;
private var mouseY_:Number = 0;
private var infoFileSize_:Number = 0;
private var infoFileCount_:int = 0;
private var infoDirCount_:int = 0;
private var modelessTmpDlg_:LongPressConfirmDialog = null;
private var ixinval:int = -1;


//=======================================================

protected function OnViewComplete (event:FlexEvent):void
{
	//var plistTimer:Timer = new Timer(3000, 1);
	//plistTimer.addEventListener("timer", PrintJobListHandler);
	//plistTimer.start();
	//fs_importFiles.extensions = new Array("printjob","autojob");
	
	//filelist.dataProvider.addItem(obj);
	//filelist.dataProvider.addItemAt(obj,ix);
	filelist.dataProvider.removeAll();
	prefs_ = new Preferences();
	//filelist.dataProvider.setItemAt(obj,ix);
	//filelist.dataProvider.getItemAt(ix);
	//int ix = filelist.dataProvider.getItemIndex(obj);
	//filelist.dataProvider.toArray():Array
	
	//filelist.addEventListener(MouseEvent.CLICK, onMouseClick);
	filelist.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	filelist.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	filelist.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	filelist.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
	filelist.addEventListener(IndexChangeEvent.CHANGE, onSelection);
	filelist.allowMultipleSelection = false;

	img.addEventListener (MouseEvent.CLICK, onImgMouseClick);
	img_vt.addEventListener (MouseEvent.CLICK, onImgMouseClick);

	//filelist.addEventListener (TouchEvent.TOUCH_TAP, onTouchTap);
	//filelist.addEventListener(GestureEvent.GESTURE_TWO_FINGER_TAP, onTwoFingerTap);
	
	//filelist.currentState = "StateName";
	//filelist.addEventListener (StateChangeEvent.CURRENT_STATE_CHANGING, onListStateChange);

	tx_view.setStyle("fontFamily", "Courier");
	if (curDirectory_ == null || curDirectory_.nativePath.length == 0) {
		var dir:String = prefs_.getInitPath();
		if (dir.length > 0) {
			curDirectory_ = new File (dir);
			if (!curDirectory_.exists) {
				curDirectory_ = File.desktopDirectory;
			}
		}
		else {
			curDirectory_ = File.desktopDirectory;
		}
	}
	
	Utilities.logDebug("Directory is: " + curDirectory_.nativePath);
	showFileList();
	
	img.fillMode = "scale";
	img.scaleMode = "letterbox"; // init is "stretch"
	img_vt.fillMode = "scale";
	img_vt.scaleMode = "letterbox";
	img_vt.rotation = 270;
	
	//this.data  // Object
	//requestSoftKeyboard():Boolean
	// Event doubleClick, gestureLongPress, softKeyboardActivate, touchBegin, touchTap, viewActivate
	//list.setStyle("contentBackgroundColor", evt.color);
}

protected function onViewActivate (event:ViewNavigatorEvent):void
{
	filelist.allowMultipleSelection = multipleSelection_;
	if (multipleSelection_) {
		menuMulSel.label = "Single Selection";
	}
	else {
		menuMulSel.label = "Multiple Selection";
	}
	//var tm:Timer = new Timer(100, 1);
	//tm.addEventListener(TimerEvent.TIMER, OnAfterActivateTimer);
	//tm.start();

	if (retData_ != null && retData_.kOperation != null && retData_.kDirectory != null) {
		if (retData_.kOperation == "copy" || retData_.kOperation == "move") {
			retData_.kOperation = "none";
			//var retDir:String = retObj.object as String;
			var retDir:String = retData_.kDirectory;
			if (retDir.length < 1) {
				return;
			}
			if (retDir.length > 0) {
				var names:Array = retData_.kSelectedNames as Array;
				if (names == null) {
					return;
				}
				var targetDir:File = new File (retDir);

				for (var j:int = 0; j < names.length; j++) {
					var curext:String = "";
					//var selStr:String = retData_.kSrcSelection;
					var selStr:String = names[j];
					if (selStr == null || selStr.length == 0 || curDirectory_ == null) {
						continue;
					}
					var selFs:File = curDirectory_.resolvePath(selStr);
					if (!selFs.exists) {
						continue;
					}
					try {
						if (!targetDir.exists || targetDir.nativePath == curDirectory_.nativePath) {
							continue;
						}
						var target:File = targetDir.resolvePath (selStr);
						if (retData_.kOperation == "move") {
							selFs.moveTo (target, true);
						}
						else {
							selFs.copyTo (target, true);
						}
					}
					catch (error:Error) {
						var msg:String = error.message.toString();
						Utilities.logDebug ("onViewActivate, 'move' error");
						Utilities.logDebug (msg);
					}
				}
				
			}
			return;
		}
		else if (retData_.kOperation == "picture") {
			if (retData_.kPageIndex > -1) {
				var tmr:Timer = new Timer(50, 1);
				tmr.addEventListener (TimerEvent.TIMER, OnReturnToThumbView);
				tmr.start();
				return;
			}
			retData_.kOperation = "none";
			var f:File = new File(retData_.kSrcSelection);
			if (f.exists) {
				var ix:int = findTextItem (f.name);
				if (ix >= 0) {
					setSelectedIndex (ix);
					scrollToListIndex (ix);
					OnFileChoose();
				}
			}
			return;
		}
		else if (retData_.kOperation == "movie" || retData_.kOperation == "edit") {
			retData_.kOperation = "none";
			if (retData_.kSelectedIndex != null) {
				var sx:int = retData_.kSelectedIndex;
				if (sx >= 0) {
					setSelectedIndex (sx);
					scrollToListIndex (sx);
					OnFileChoose();
				}
			}
			return;
		}
		else if (retData_.kOperation == "newfile") {
			retData_.kOperation = "none";
			var newname:String = retData_.kSrcSelection;
			showFileList();
			var ix1:int = findTextItem (newname);
			if (ix1 >= 0) {
				setSelectedIndex (ix1);
				scrollToListIndex (ix1);
			}
			OnFileChoose();
			return;
		}
		else if (retData_.kOperation == "picturethumb") {
			var retStr:String = retData_.kSrcSelection;
			if (retStr != null && retStr.length > 0) {
				var tm:Timer = new Timer(50, 1);
				tm.addEventListener (TimerEvent.TIMER, OnPictureThumbSelect);
				tm.start();
			}
		}
	}
	showFileList();
	OnFileChoose();
}

protected function OnApplicationClosing(event:ViewNavigatorEvent):void
{
	if (prefs_ != null) {
		prefs_.setInitPath (curDirectory_.nativePath);
		prefs_.save ();
	}
}

private function findTextItem (s:String):int
{
	for (var ix:int = 0; ix < filelist.dataProvider.length; ix++) {
		if (filelist.dataProvider.getItemAt(ix).label.toString() == s) {
			return ix;
		}
	}
	return -1;
}

private function scrollToListIndex (index:int):void
{
	if (index < 0) {
		return;
	}
	filelist.layout.verticalScrollPosition = 0;
	filelist.validateNow();
	var size_y:int = filelist.layout.target.height;
	var vsize_y:int = filelist.layout.getVerticalScrollPositionDelta (NavigationUnit.END) + size_y;
	var scroll:int = ((vsize_y / filelist.dataProvider.length) * index + 1) - size_y / 2;
	if (scroll < 10) {
		return;
	}
	filelist.layout.verticalScrollPosition = scroll;
}

private function setSelectedIndex (index:int):void
{
	if (index < 0) {
		return;
	}
	filelist.validateNow();
	var v:Vector.<int> = new Vector.<int>();
	v.push (index);
	filelist.selectedIndices = v;
}

private function getSelectedIndex ():int
{
	filelist.validateNow();
	if (filelist.selectedIndices.length > 0) {
		return filelist.selectedIndices[0];
	}
	return -1;
}

private function getSelectedString ():String
{
	filelist.validateNow();
	if (filelist.selectedItems.length > 0) {
		return filelist.selectedItems[0].label.toString();
	}
	return "";
}

//protected function onMouseClick (event:MouseEvent):void
//{
//	Utilities.logDebug("FileView:onMouseClick");
//}

protected function onMouseDown (event:MouseEvent):void
{
	Utilities.logDebug("FileView:onMouseDown");
	if (mouseDownTimerActive_) {
		mouseDownTimerValid_ = false;
	}
	else {
		mouseDownTimerValid_ = true;
		//mouseX_ = event.localX;
		//mouseY_ = event.localY;
		mouseX_ = event.stageX;
		mouseY_ = event.stageY;
		isLongPress_ = false;
		mouseDownTimerActive_ = true;
		var tm:Timer = new Timer (1000, 1);
		tm.addEventListener(TimerEvent.TIMER, onMouseDownTimer);
		tm.start();
	}
}

protected function onMouseUp (event:MouseEvent):void
{
	if (mouseDownTimerActive_) {
		mouseDownTimerValid_ = false;
	}

	if (isLongPress_) {
		isLongPress_ = false;
		if (modelessTmpDlg_ != null) {
			modelessTmpDlg_.close();
		}

		var dlg:LongPressConfirmDialog = new LongPressConfirmDialog();
		//dlg.message = "To make a range selection select the end of the range";
		dlg.addEventListener('close', longPressHandler);
		dlg.open (this, true);
	}
}

protected function onMouseMove (event:MouseEvent):void
{
	if (!mouseDownTimerActive_) {
		return;
	}
	if (mouseX_ > event.stageX + 50 || mouseX_ < event.stageX - 50 || mouseY_ > event.stageY + 50 || mouseY_ < event.stageY - 50) {
		mouseDownTimerValid_ = false;
	}
}

protected function onDoubleClick (event:MouseEvent):void
{
	Utilities.logDebug("FileView:onDoubleClick");
	onDoubleClick_ ("");
}

private function onMouseDownTimer (event:TimerEvent):void
{
	mouseDownTimerActive_ = false;
	if (!mouseDownTimerValid_) {
		return;
	}
	mouseDownTimerValid_ = false;
	if (!multipleSelection_) {
		isLongPress_ = true;

		modelessTmpDlg_ = new LongPressConfirmDialog();
		modelessTmpDlg_.open (this, false);
	}
}

protected function longPressHandler(event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	if (event.data != null) {
		var cmd:String = event.data as String;
		if (cmd == "R") {
			firstSelOfRange_ = filelist.selectedIndex;
			filelist.allowMultipleSelection = true;
			isRangeSelection_ = true;
		}
		else if (cmd == "C") {
			doCopyFile();
		}
		else if (cmd == "M") {
			doMoveFile();
		}
		else if (cmd == "D") {
			doDeleteFile();
		}
		else if (cmd == "U") {
			doDuplicate();
		}
		else if (cmd == "I") {
			doGetInfo();
		}
		else if (cmd == "T") {
			onThumbnails();
		}
	}
}

protected function onThumbnails():void
{
	var selStr:String = getSelectedString();
	if (selStr.length == 0) {
		return;
	}
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs == null) {
		return;
	}
	
	var curext:String = "";
	if (selFs.extension != null) {
		curext = selFs.extension;
	}
	var extU:String = curext.toLocaleUpperCase(); 
	
	if (selFs.isDirectory) {
		return;
	}
	else if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
		retData_ = new Object;
		retData_.kSrcSelection = selFs.nativePath;
		retData_.kOperation = "picturethumb";
		retData_.kDirectory = "";
		retData_.kPageIndex = ixinval;
		navigator.pushView (views.ThumbnailView, retData_);
		return;
	}
}

protected function onSelection (event:IndexChangeEvent):void
{
	if (isRangeSelected_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
	}
	if (isRangeSelection_) {
		isRangeSelected_ = true;
		
		var tm:Timer = new Timer (50, 1);
		tm.addEventListener(TimerEvent.TIMER, onRangeSelectedTimer);
		tm.start();
		return;
	}
	OnFileChoose();
	
	if (multipleSelection_ && filelist.selectedIndices.length > 0) {
		showDirInfo();
	}
}

private function onRangeSelectedTimer (event:TimerEvent):void
{
	var curSel:int = filelist.selectedIndex;
	if (firstSelOfRange_ >= filelist.dataProvider.length) {
		return;
	}
	var selection:Vector.<int> = new Vector.<int>();
	if (curSel > firstSelOfRange_) {
		for (var ix:int = firstSelOfRange_; ix <= curSel; ix++) {
			selection.push (ix);
		}
	}
	else {
		for (var iy:int = curSel; iy <= firstSelOfRange_; iy++) {
			selection.push (iy);
		}
	}
	if (selection.length > 0) {
		filelist.selectedIndices = selection;
	}
	showDirInfo();
}

protected function onImgMouseClick (event:MouseEvent):void
{
	Utilities.logDebug("FileView:onImgMouseClick");
	var ix:int = getSelectedIndex();
	if (ix + 1 < filelist.dataProvider.length) {
		setSelectedIndex (ix + 1);
		scrollToListIndex (ix + 1);
		OnFileChoose();
	}
}

protected function OnFileChoose():void
{
	var ix:int = getSelectedIndex();
	//tx_view.text += "\n" + selStr;
	//var selStr2:String = filelist.dataProvider.getItemAt(ix).toString(); // OK
	var isFull:Boolean = ch_Full.selected;
	var isBinary:Boolean = ch_Binary.selected;
	img.visible = false;
	img_vt.visible = false;
	tx_view.visible = true;
	st_imginfo.text = "Image:";
	st_size.text = "";
	st_date.text = "";
	tx_InfoMake.text = "";
	tx_InfoModel.text = "";
	tx_InfoDate.text = "";
	tx_InfoSens.text = "";
	tx_InfoExpo.text = "";
	tx_InfoFNum.text = "";
	tx_InfoFocal.text = "";
	tx_InfoFlash.text = "";

	if (ix < 0) {
		tx_view.text = copyright;
		return;
	}
	var selStr:String = getSelectedString();
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs.isSymbolicLink || selFs.isHidden) {
		tx_view.text = copyright;
		return;
	}
	var dt:Date = selFs.modificationDate;
	st_date.text = dt.toLocaleString();
	
	if (selFs.isDirectory) {
		tx_view.text = copyright;
		var numFiles:uint = 0;
		var info:Object = new Object();
		info.kDirCount = numFiles;
		info.kFileCount = numFiles;
		var files:Array = getFileListing (selFs, info);
		st_size.text = "Directory with " + info.kDirCount.toString() + " subfolder(s) and " + info.kFileCount.toString() + " file(s)";
		return;
	}
	
	full_len = selFs.size;
	st_size.text = getSizeStr (full_len) + " bytes";
	
	var curext:String = "";
	if (selFs.extension != null) {
		curext = selFs.extension;
	}
	var extU:String = curext.toLocaleUpperCase(); 
	//txt.text = "File extension is: " + ext;
	//var curLine:String = "";
	var fstr:FileStream = new FileStream();
	fstr.open (selFs, FileMode.READ);
	var len:Number = full_len;
	if (len == 0) {
		fstr.close();
		tx_view.text = copyright;
		return;
	}
	else if (!isFull && len > 100000) {
		len = 100000;
	}
	else if (isFull && len > 50000000) {
		len = 50000000;
	}
	var urlstr:String = "file://";
	urlstr += selFs.nativePath;
	
	if (isBinary) {
		ShowBinaryContent (fstr, len);
		
	}
	else if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
		tx_view.visible = false;
		imgPortrait_ = false;
		showExifInfo (fstr, full_len);
		fstr.close();
		if (imgPortrait_) {
			img_vt.source = urlstr;
			img_vt.visible = true;
			img_vt.addEventListener(Event.COMPLETE, onLoadComplete);
		}
		else {
			img.source = urlstr;
			img.visible = true;
			img.addEventListener(Event.COMPLETE, onLoadComplete);
		}
	}
	else {
		//tx_view.setStyle("fontFamily", "Arial");
		ShowTextContent (fstr, len);
	}
}

private function onLoadComplete (event:Event):void
{
	if (img.visible) {
		st_imginfo.text = "Image: " + img.sourceWidth.toString() + " x " + img.sourceHeight.toString();
		img.removeEventListener(Event.COMPLETE, onLoadComplete);
	}
	else {
		st_imginfo.text = "Image: " + img_vt.sourceWidth.toString() + " x " + img_vt.sourceHeight.toString();
		img_vt.removeEventListener(Event.COMPLETE, onLoadComplete);
	}
}

protected function onChBinary (event:MouseEvent):void
{
	OnFileChoose();
}

protected function onChFull (event:MouseEvent):void
{
	OnFileChoose();
}

protected function onDoubleClick_ (path:String):void
{
	var selFs:File = null;
	if (path.length > 0) {
		selFs = new File (path);
	}
	else {
		var selStr:String = getSelectedString();
		if (selStr.length == 0) {
			return;
		}
		selFs = curDirectory_.resolvePath(selStr);
	}
	if (selFs == null) {
		return;
	}

	var curext:String = "";
	if (selFs.extension != null) {
		curext = selFs.extension;
	}
	var extU:String = curext.toLocaleUpperCase(); 
	
	if (selFs.isDirectory) {
		curDirectory_ = selFs;
		//st_path.text = curDirectory_.nativePath;
		showFileList();
		OnFileChoose();
		return;
	}
	else if (extU == "JPG" || extU == "JPEG" || extU == "PNG" || extU == "GIF") {
		retData_ = new Object;
		retData_.kSrcSelection = selFs.nativePath;
		retData_.kOperation = "picture";
		retData_.kDirectory = "";
		retData_.kPageIndex = ixinval;
		navigator.pushView (views.PictureView, retData_);
		return;
	}
	else if (extU == "MP4" || extU == "M4V" || extU == "F4V" || extU == "FLV"
		|| extU == "MOV" || extU == "3GP" || extU == "3G2"
		|| extU == "AVI" || extU == "WMV")
	{
		retData_ = new Object;
		retData_.kSrcSelection = selFs.nativePath;
		retData_.kOperation = "movie";
		retData_.kDirectory = "";
		navigator.pushView (views.MovieView, retData_);
		return;
	}
	
	if (retData_ == null) {
		retData_ = new Object();
	}
	if (retData_.kOperation == null) {
		retData_.kOperation = "edit";
	}
	retData_.kFile = selFs;
	retData_.kTouch = false;
	retData_.kDirectory = "";
	if (retData_.kOperation != "newfile") {
		retData_.kOperation = "edit";
		retData_.kSelectedIndex = getSelectedIndex();
	}
	navigator.pushView (views.EditorView, retData_);
}

private function OnPictureThumbSelect (event:TimerEvent):void
{
	//retData_.kSrcSelection = selFs.nativePath; // keep value from picturethumb
	retData_.kOperation = "picture";
	//retData_.kPageIndex = ixinval; // keep value
	navigator.pushView (views.PictureView, retData_);
}

private function OnReturnToThumbView (event:TimerEvent):void
{
	retData_.kOperation = "picturethumb";
	navigator.pushView (views.ThumbnailView, retData_);
}

protected function selectHandler (event:IndexChangeEvent):void
{
	var index:int = getSelectedIndex();
	var itm:Object = filelist.selectedItem;
	//var lbl:String = filelist.itemToLabel(lbl);
	
	//navigator.pushView(views.secondView, data);
}

protected function onButtonUp (event:MouseEvent):void
{
	var par:File = curDirectory_.parent;
	if (par != null) {
		var curName:String = curDirectory_.name;
		curDirectory_ = par;
		//st_path.text = curDirectory_.nativePath;
		showFileList();
		var ix:int = findTextItem (curName);
		if (ix >= 0) {
			setSelectedIndex (ix);
			scrollToListIndex (ix);
		}
		OnFileChoose();
	}
	tx_view.text = copyright;
}

protected function onButtonHome (event:MouseEvent):void
{
	curDirectory_ = File.desktopDirectory;
	//st_path.text = curDirectory_.nativePath;
	showFileList();
	OnFileChoose();
}

protected function onButtonDir1 (event:MouseEvent):void
{
	var p:String = prefs_.getCustomPath1();
	if (p.length > 0) {
		var newDir:File = new File (p);
		if (newDir.exists) {
			curDirectory_ = newDir;
			showFileList();
			OnFileChoose();
		}
	}
}

protected function onButtonDir2 (event:MouseEvent):void
{
	var p:String = prefs_.getCustomPath2();
	if (p.length > 0) {
		var newDir:File = new File (p);
		if (newDir.exists) {
			curDirectory_ = newDir;
			showFileList();
			OnFileChoose();
		}
	}
}

protected function onButtonMenu (event:MouseEvent):void
{
	mx.core.FlexGlobals.topLevelApplication.viewMenuOpen = true;
}

private function onEditName (event:MouseEvent):void
{
	var curext:String = "";
	var selStr:String = getSelectedString();
	if (selStr == null || selStr.length == 0 || curDirectory_ == null) {
		return;
	}
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs.extension != null && selFs.extension.length < 5) {
		curext = selFs.extension;
	}
	if (curext.length > 0) {
		curext = "." + curext;
	}
	var nameDlg:FileNameDialog = new FileNameDialog();
	nameDlg.filename = selFs.name.substr(0, selFs.name.length - curext.length);
	nameDlg.addEventListener('close', nameDlgCloseHandler);
	nameDlg.open (this, true);
}
	
private function onEditExtension (event:MouseEvent):void
{
	var extDlg:ExtensionDialog = new ExtensionDialog();
	extDlg.addEventListener('close', extDlgCloseHandler);
	extDlg.open (this, true);
}

protected function nameDlgCloseHandler(event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	ChangeFileName (event.data as String);
}            

protected function extDlgCloseHandler(event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	ChangeFileExtension (event.data as String);
}            

private function onDuplicate (event:MouseEvent):void
{
	doDuplicate();
}

private function doDuplicate():void
{
	if (isRangeSelected_ || isRangeSelection_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
		return;
	}
	if (filelist.allowMultipleSelection) {
		return;
	}
	var curext:String = "";
	var selStr:String = getSelectedString();
	if (selStr == null || selStr.length == 0 || curDirectory_ == null) {
		return;
	}
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs.extension != null) {
		curext = selFs.extension;
	}

	try {
		var par:String = selFs.parent.nativePath;
		if (curext.length > 0) {
			curext = "." + curext;
		}
		var nm:String = selFs.name.substr(0, selFs.name.length - curext.length);
		nm += "_1";
		var targetpar:File = new File (par);
		var target:File = targetpar.resolvePath (nm + curext);
		while(target.exists) {
			nm += "1";
			if (nm.length > 200) {
				return;
			}
			target = targetpar.resolvePath (nm + curext);
		}
		selFs.copyTo (target, true);
		showFileList();
	}
	catch (error:Error) {
		var msg:String = error.message.toString();
		Utilities.logDebug ("doDuplicate error");
		Utilities.logDebug (msg);
	}
	
}

private function onCopyFile (event:MouseEvent):void
{
	doCopyFile();
}

private function doCopyFile():void
{
	if (filelist.selectedItems.length == 0) {
		return;
	}
	retData_ = new Object;
	retData_.kDirectory = curDirectory_;
	var sources:Array = new Array();
	for (var ix:int = 0; ix < filelist.selectedItems.length; ix++) {
		sources.push (filelist.selectedItems[ix].label.toString());
	}
	
	if (isRangeSelected_ || isRangeSelection_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
	}
	//retData_.kSrcSelection = filelist.selectedItem.label.toString();
	retData_.kSelectedNames = sources;
	retData_.kOperation = "copy";
	navigator.pushView (views.ChooseDirectoryView, retData_);
}

private function onMoveFile (event:MouseEvent):void
{
	doMoveFile();
}

private function doMoveFile():void
{
	if (filelist.selectedItems.length == 0) {
		return;
	}
	retData_ = new Object;
	retData_.kDirectory = curDirectory_;
	var sources:Array = new Array();
	for (var ix:int = 0; ix < filelist.selectedItems.length; ix++) {
		sources.push (filelist.selectedItems[ix].label.toString());
	}
	
	if (isRangeSelected_ || isRangeSelection_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
	}
	retData_.kSelectedNames = sources;
	retData_.kOperation = "move";
	navigator.pushView (views.ChooseDirectoryView, retData_);
}

private function onDelete (event:MouseEvent):void
{
	doDeleteFile();
}

private function doDeleteFile():void
{
	if (filelist.selectedItems.length == 0) {
		return;
	}
	var alert:AlertDialog = new AlertDialog();
	alert.message = "Delete File(s) ?";
	alert.addEventListener('close', deleteHandler);
	alert.open (this, true);
}

private function onSetDir1 (event:MouseEvent):void
{
	if (curDirectory_ != null) {
		prefs_.setCustomPath1 (curDirectory_.nativePath);
	}
}

private function onSetDir2 (event:MouseEvent):void
{
	if (curDirectory_ != null) {
		prefs_.setCustomPath2 (curDirectory_.nativePath);
	}
}

private function onMultipleSelection (event:MouseEvent):void
{
	if (isRangeSelected_ || isRangeSelection_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
		return;
	}
	multipleSelection_ = !multipleSelection_;
	filelist.allowMultipleSelection = multipleSelection_;
	if (multipleSelection_) {
		menuMulSel.label = "Single Selection";
	}
	else {
		menuMulSel.label = "Multiple Selection";
	}
	showDirInfo();
}

private function onCreateFolder (event:MouseEvent):void
{
	var nameDlg:FileNameDialog = new FileNameDialog();
	nameDlg.addEventListener('close', folderDlgCloseHandler);
	nameDlg.open (this, true);
}

protected function folderDlgCloseHandler(event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	if (curDirectory_ != null && curDirectory_.exists) {
		var name:String = event.data as String;
		if (name.length < 1) {
			return;
		}
		var dir:File = curDirectory_.resolvePath (name);
		if (dir.exists) {
			return;
		}
		dir.createDirectory();
		
		showFileList();
		var ix:int = findTextItem (name);
		if (ix >= 0) {
			setSelectedIndex (ix);
			scrollToListIndex (ix);
			OnFileChoose();
		}
	}
}

private function onShowLog (event:MouseEvent):void
{
	var dlg:DebugLogDialog = new DebugLogDialog();
	dlg.message = Utilities.log_;
	dlg.open (this, true);
}

protected function deleteHandler(event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	DeleteAction();
}

private function DeleteAction():void
{
	if (filelist.selectedItems.length == 0) {
		return;
	}
	//var selStr:String = filelist.selectedItem.label.toString();
	
	var sources:Array = new Array();
	for (var ix:int = 0; ix < filelist.selectedItems.length; ix++) {
		//sources.push (filelist.selectedItems[ix].label.toString());
		var selStr:String = filelist.selectedItems[ix].label.toString();
		if (selStr == null || selStr.length == 0 || curDirectory_ == null) {
			continue;
		}
		var selFs:File = curDirectory_.resolvePath(selStr);
		if (selFs.nativePath.length > 7 && selFs.exists) {
			try {
				selFs.moveToTrash();
			}
			catch (error:Error) {
				var msg:String = error.message.toString();
				Utilities.logDebug ("DeleteAction error");
				Utilities.logDebug (msg);
				continue;
			}
		}
	}
	if (isRangeSelected_ || isRangeSelection_) {
		isRangeSelected_ = false;
		isRangeSelection_ = false;
		filelist.allowMultipleSelection = false;
	}

	showFileList();
	StartAfterDelNewTimer();
}

protected function onClean (event:MouseEvent):void
{
	var alert:AlertDialog = new AlertDialog();
	alert.message = "Delete all files beginning with \"._\" ?";
	alert.addEventListener('close', cleanHandler);
	alert.open (this, true);
}

protected function cleanHandler (event:PopUpEvent):void
{
	if (!event.commit) {
		return;
	}
	cleanAction (curDirectory_);
	showFileList();
	StartAfterDelNewTimer();
}

private function cleanAction (dir:File):void
{
	if (dir == null) {
		return;
	}
	var arr:Array = dir.getDirectoryListing();
	
	for (var ix:int = 0; ix < arr.length; ix++) {
		var f:File = arr[ix] as File;
		if (f == null) {
			continue;
		}
		if (f.isDirectory) {
			cleanAction (f);
			continue;
		}
		if (f.name.length > 1 && (f.name.substr (0, 2) == "._" || f.name == ".DS_Store")) {
			try {
				f.moveToTrash();
			}
			catch (error:Error) {
				var msg:String = error.message.toString();
				Utilities.logDebug ("cleanAction error");
				Utilities.logDebug (msg);
				continue;
			}
		}
	}
}

private function StartAfterDelNewTimer():void
{
	var tm:Timer = new Timer(50, 1);
	tm.addEventListener(TimerEvent.TIMER, OnAfterDelNewTimer);
	tm.start();
}

private function OnAfterDelNewTimer (event:TimerEvent):void
{
	OnFileChoose();
}

private function onNewFile (event:MouseEvent):void
{
	if (curDirectory_ != null) {
		try {
			var cnt:uint = 0;
			var newFs:File = null;
			do {
				cnt++;
				if (cnt > 99) {
					return;
				}
				newFs = curDirectory_.resolvePath ("newfile_" + cnt + ".txt");
			} while (newFs.exists);
			var target:FileStream = new FileStream();
			target.open (newFs, FileMode.WRITE);
			target.close();
			if (retData_ == null) {
				retData_ = new Object();
			}
			retData_.kOperation = "newfile";
			retData_.kSrcSelection = newFs.name;
			onDoubleClick_ (newFs.nativePath);
			//showFileList();
			//StartAfterDelNewTimer();
		}
		catch (error:Error) {
			var msg:String = error.message.toString();
			Utilities.logDebug ("onNewFile error");
			Utilities.logDebug (msg);
		}
	}
	
}

private function onGetInfo (event:MouseEvent):void
{
	doGetInfo();
}

private function doGetInfo():void
{
	if (curDirectory_ == null) {
		return;
	}
	var dirFs:File = null;
	var dlg:DirInfoDialog = new DirInfoDialog();
	var selStr:String = getSelectedString();
	if (selStr == null || selStr.length == 0) {
		dirFs = curDirectory_;
	}
	else {
		dirFs = curDirectory_.resolvePath(selStr);
		if (!dirFs.isDirectory) {
			dirFs = curDirectory_;
		}
	}
	if (dirFs != null) {
		infoFileSize_ = 0;
		infoFileCount_ = 0;
		infoDirCount_ = 0;
		getInfo (dirFs);
		dlg.message = "Directory is:\n";
		dlg.message += dirFs.nativePath + "\n";
		dlg.message += "Created on: " + dirFs.creationDate.toLocaleString() + "\n";
		dlg.message += "Modified on: " + dirFs.modificationDate.toLocaleString() + "\n";
		dlg.message += "Total number of Subdirectories: " + infoDirCount_.toString() + "\n";
		dlg.message += "Total number of files: " + infoFileCount_.toString() + "\n";
		dlg.message += "Total size: " + getSizeStr (infoFileSize_) + "\n";
		dlg.open (this, true);
	}
}

private function getInfo (dirFs:File):void
{
	try {
		var files:Array = dirFs.getDirectoryListing();
		for (var i1:uint = 0; i1 < files.length; i1++) {
			var f:File = files[i1];
			if (f.isDirectory) {
				infoDirCount_++;
				getInfo (f);
			}
			else {
				infoFileCount_++;
				infoFileSize_ += f.size;
			}
		}
	}
	catch (error:Error) {
		var msg:String = error.message.toString();
		Utilities.logDebug ("getInfo error");
		Utilities.logDebug (msg);
	}
}

public function ChangeFileExtension (ext:String):void
{
	var selStr:String = getSelectedString();
	if (selStr == null || selStr.length == 0 || curDirectory_ == null) {
		return;
	}
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs != null) {
		try {
			var oldext:String = "";
			if (selFs.extension != null) {
				oldext = selFs.extension;
				oldext = "." + oldext;
			}
			var path:String = selFs.nativePath;
			path = path.substr (0, path.length - oldext.length);
			path += "." + ext;
			var newFs:File = new File(path);
			if (newFs.exists) {
				//Alert.show ("The file exists already.", "Rename");
			}
			else {
				selFs.moveTo (newFs);
				showFileList();
			}
		}
		catch (error:Error) {
			var msg:String = error.message.toString();
			Utilities.logDebug ("ChangeFileExtension error");
			Utilities.logDebug (msg);
		}
	}
}

public function ChangeFileName (name:String):void
{
	var selStr:String = getSelectedString();
	if (selStr == null || selStr.length == 0 || curDirectory_ == null || name.length < 1) {
		return;
	}
	var selFs:File = curDirectory_.resolvePath(selStr);
	if (selFs != null) {
		try {
			var path:String = selFs.nativePath;
			var oldext:String = "";
			if (selFs.extension != null && selFs.extension.length < 5) {
				oldext = selFs.extension;
			}
			var oldname:String = selFs.name;
			var oldpath:String = selFs.parent.nativePath;
			if (oldext.length > 0) {
				oldext = "." + oldext;
			}
			path = path.substr (0, path.length - oldext.length);
			var newFs:File = new File(oldpath);
			newFs = newFs.resolvePath (name + oldext);
			if (newFs.exists) {
				//Alert.show ("The file exists already.", "Rename");
			}
			else {
				selFs.moveTo (newFs);
				showFileList();
			}
		}
		catch (error:Error) {
			var msg:String = error.message.toString();
			Utilities.logDebug ("ChangeFileName error");
			Utilities.logDebug (msg);
		}
	}
}


private function showFileList():void
{
	filelist.dataProvider.removeAll();
	if (curDirectory_ == null) {
		return;
	}
	var files:Array = getFileListing (curDirectory_, null);
	if (files == null) {
		return;
	}
	for (var i1:uint = 0; i1 < files.length; i1++) {
		var obj:Object = new Object();
		obj.label = files[i1];
		//obj.icon = "/Volumes/Development/Development/AIR/FlexProjects/FileViewAndroid/src/res/Generic_Document.png')";
		var f:File = curDirectory_.resolvePath(files[i1]);
		if (f.isDirectory) {
			obj.data = "d";
			//obj.icon = "@Embed(source='res/Folder_Closed.jpg')";
			//obj.icon = "@Embed('res/Folder_Closed.png')";
		}
		else {
			obj.data = "f";
			//obj.icon = "@Embed(source='res/Generic_Document.jpg')";
		}
		filelist.dataProvider.addItem (obj);
	}
	fileCountInCurDir_ = files.length;
	showDirInfo();
}

private function showDirInfo():void
{
	st_path.text = curDirectory_.nativePath + " (" + fileCountInCurDir_.toString() + ")";
	if (multipleSelection_ || isRangeSelected_) {
		filelist.validateNow();
		st_path.text += "(" + filelist.selectedIndices.length.toString() + " sel)";
	}
}


private function getFileListing (dir:File, info:Object):Array
{
	var retval:Array = new Array();
	var filesar:Array = new Array();
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
				filesar.push (f.name);
			}
		}
		if (info != null) {
			info.kDirCount = retval.length;
			info.kFileCount = filesar.length;
		}
		retval.sort();
		filesar.sort();
		filelist_ = filesar;
		for (var i2:uint = 0; i2 < filesar.length; i2++) {
			retval.push (filesar[i2]);
		}
	}
	catch (error:Error) {
		var msg:String = error.message.toString();
		Utilities.logDebug ("getFileListing error");
		Utilities.logDebug (msg);
	}
	return retval;
}

private function ShowTextContent (fstr:FileStream, len:int):void
{
	var wasLF:Boolean = false;
	var wasCR:Boolean = false;
	var content:String = "";
	var lineLength:int = 0;
	var isWrap:Boolean = true;
	
	for (var ix:uint = 0; ix < len; ix++, lineLength++) {
		if (lineLength > 1000 && !isWrap) {
			content += "\n";
			lineLength = 0;
		}
		var bt:int = fstr.readByte();
		if (bt == 10) {
			if (!wasCR) {
				content += "\n";
				lineLength = 0;
			}
			wasLF = true;
			wasCR = false;
		}
		else if (bt == 13) {
			//if (!wasLF) {
			content += "\n";
			lineLength = 0;
			//}
			wasCR = true;
			wasLF = false;
		}
		else if (bt == 9) {
			wasLF = false;
			wasCR = false;
			content += "    ";
		}
		else if (bt < 32 && bt != 127) {
			wasLF = false;
			wasCR = false;
			content += ".";
		}
		else {
			wasLF = false;
			wasCR = false;
			content += String.fromCharCode(bt);
		}
	}
	tx_view.text = content;
}

private function ShowBinaryContent (fstr:FileStream, len:int):void
{
	var cl:int = 0;
	var tx:String = "";
	var content:String = "";
	
	for (var ixb:uint = 0; ixb < len; ixb++) {
		var b:uint = fstr.readUnsignedByte();
		if (cl == 0) {
			content += getFixString (ixb);
			content += "  ";
			content += getHex (b);
			content += " ";
		}
		else if (cl == 7) {
			content += getHex (b);
			content += "  ";
		}
		else {
			content += getHex (b);
			content += " ";
		}
		if (b < 32 || b > 127) {
			tx += ".";
		}
		else {
			tx += String.fromCharCode(b);
		}
		cl++;
		if (cl == 16 || ixb == len - 1) {
			for (var i:int = 0; i < 16 - cl; i++) {
				content += "   ";
				if (i == 7) {
					content += " ";
				}
			}
			cl = 0;
			content += "  ";
			content += tx;
			content += "\n";
			tx = "";
		}
	}
	tx_view.text = content;
	//text_len = content.length;
}

private function onShowHelp (event:MouseEvent):void
{
	var tx:String = "";
	var content:String = versionStr;
	
	content += "\n\nThis is a tool for viewing the content of any file.\n";
	content += "Text editing, copying, moving and deleting files works on the\n";
	content += "internal memory and on USB sticks but not on inserted SD cards\n";
	content += "due to the newly introduced limitation in the Android system.\n";
	content += "Gestures do not work, so only click, double click and long click can be used.\n";
	content += "Double click in the file list opens a text editor,\n";
	content += "shows images or steps into a directory. Long click opens a context menu.\n";
	content += "Double click in the middle of an image zooms in, simple click zooms out.\n";
	content += "Long click in the middle shows file info,\n";
	content += "click in the outer region pans (when zoomed) or steps forward and backward.\n";
	content += "The menu item 'Clean Files' removes all '.DS_Store' and all files beginning with '._' recursively.\n";
	
	tx_view.text = content;
}

private function showExifInfo (fs:FileStream, len:int):void
{
	var record:Array = new Array();
	var idstr:String = "";
	var bt14:uint = 0;
	var bt_1:uint = 0; 
	var bigEnd:Boolean = false;
	var firstByte:Boolean = true;
	const make_id:uint = 0x010f;
	const model_id:uint = 0x0110;
	const orient_id:uint = 0x0112;
	const date_id:uint = 0x0132;
	const exposure_id:uint = 0x829a;
	const fnum_id:uint = 0x829d;
	const sens_id:uint = 0x8827;
	const iso_id:uint = 0x8833;
	const flash_id:uint = 0x9209;
	const focal_id:uint = 0x920a;
	const focal35_id:uint = 0xa405;
	const program_id:uint = 0x8822;
	const lensmake_id:uint = 0xa433;
	const lensmodel_id:uint = 0xa434;
	
	if (len > 10000) {
		len = 10000;
	}
	for (var ix:uint = 0; ix < len; ix++) {
		var bt:uint = 0;
		bt = fs.readUnsignedByte();
		if (ix > 5 && ix < 10) {
			idstr += String.fromCharCode (bt);
		}
		if (ix == 14) {
			bt14 = bt;
		}
		if (ix == 15) {
			if (bt14 == 0 && bt > 0) {
				bigEnd = false;
			}
			else if (bt14 > 0 && bt == 0) {
				bigEnd = true;
			}
			else {
				return;
			}
			if (idstr != "Exif") {
				return;
			}
		}
		if (ix > 11) {
			if (firstByte) {
				bt_1 = bt;
				firstByte = false;
			}
			else {
				if (bigEnd) {
					record.push (bt * 256 + bt_1);
				}
				else {
					record.push (bt_1 * 256 + bt);
				}
				firstByte = true;
			}
		}
	}
	var entry:Object = new Object();
	entry.kStr = "";
	entry.kStr2 = "";
	entry.kStr3 = "";
	entry.kInt = 0;
	if (getExifValueFromString (record, make_id, entry, bigEnd)) {
		tx_InfoMake.text = "Make: " + entry.kStr;
	}
	if (getExifValueFromString (record, model_id, entry, bigEnd)) {
		tx_InfoModel.text = "Model: " + entry.kStr;
	}
	//if (getExifValueFromString (record, lensmodel_id, entry, bigEnd)) {
	//	tx_InfoLensMake.text = "Lens Model: ";
	//	tx_InfoLensModel.text = entry.kStr;
	//}
	if (getExifValueFromString (record, date_id, entry, bigEnd)) {
		tx_InfoDate.text = "Date: " + entry.kStr;
	}
	if (getExifValueFromShort (record, orient_id, entry, bigEnd)) {
		//tx_InfoFlash.text = "Orientation: ";
		if (entry.kInt > 0 && entry.kInt < 5) {
			//tx_InfoFlash.text += " landscape";
			imgPortrait_ = false;
		}
		else if (entry.kInt > 0 && entry.kInt < 9) {
			//tx_InfoFlash.text += " portrait";
			imgPortrait_ = true;
		}
	}
	tx_InfoSens.text = "Sensitivity: ";
	if (getExifValueFromLong (record, iso_id, entry, bigEnd)) {
		tx_InfoSens.text += entry.kStr;
	}
	else if (getExifValueFromShort (record, sens_id, entry, bigEnd)) {
		tx_InfoSens.text += entry.kStr;
	}
	tx_InfoExpo.text = "Exposure time: ";
	if (getExifValueFromRational (record, exposure_id, entry, bigEnd)) {
		tx_InfoExpo.text += entry.kStr;
	}
	tx_InfoFNum.text = "F Number: ";
	if (getExifValueFromRational (record, fnum_id, entry, bigEnd)) {
		tx_InfoFNum.text += entry.kStr3;
	}
	tx_InfoFocal.text = "Focal length: ";
	if (getExifValueFromRational (record, focal_id, entry, bigEnd)) {
		tx_InfoFocal.text += entry.kStr2;
	}
	if (getExifValueFromShort (record, focal35_id, entry, bigEnd)) {
		tx_InfoFocal.text += " (equ " + entry.kStr + ")";
	}
	//if (getExifValueFromShort (record, program_id, entry, bigEnd)) {
	if (getExifValueFromShort (record, flash_id, entry, bigEnd)) {
		tx_InfoFlash.text = "Flash used: ";
		if (entry.kInt % 2 > 0) { // bit 0 is set
			tx_InfoFlash.text += "Yes";
		}
		else {
			tx_InfoFlash.text += "No";
		}
	}
}

private function getExifValueFromString (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 2) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len < 100) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (bigEnd) {
						offs = arr[pos + 4] + arr[pos + 5] * 65536;
					}
					else {
						offs = arr[pos + 4] * 65536 + arr[pos + 5];
					}
					for (var ix:int = offs / 2; ix < arlen; ix++) {
						if (bigEnd) {
							value.kStr += String.fromCharCode (arr[ix] % 256); // second byte at first
							value.kStr += String.fromCharCode (arr[ix] / 256);
						}
						else {
							value.kStr += String.fromCharCode (arr[ix] / 256);
							value.kStr += String.fromCharCode (arr[ix] % 256);
						}
						if (value.kStr.length >= len) {
							break;
						}
					}
					return true;
				}
			}
		}
		
	} while(pos > 0);
	return false;
}

private function getExifValueFromShort (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 3) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					value.kInt = arr[pos + 4];
					value.kStr = arr[pos + 4].toString();
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}

private function getExifValueFromLong (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kInt = 0;
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			if (arr[pos + 1] == 4 || arr[pos + 1] == 9) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					if (bigEnd) {
						value.kInt = arr[pos + 4] + arr[pos + 5] * 65536;
						value.kStr = value.kInt.toString();
					}
					else {
						value.kInt = arr[pos + 4] * 65536 + arr[pos + 5];
						value.kStr = value.kInt.toString();
					}
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}

private function getExifValueFromRational (arr:Array, id:uint, value:Object, bigEnd:Boolean):Boolean
{
	var pos:int = 0;
	value.kStr = "";
	value.kStr2 = "";
	value.kStr3 = "";
	do {
		pos = arr.indexOf (id, pos + 1);
		if (pos > 0) {
			var signed:int = -1;
			if (arr[pos + 1] == 5) {
				signed = 0;
			}
			else if (arr[pos + 1] == 10) {
				signed = 1;
			}
			if (signed >= 0) {
				var len:uint = 0;
				if (bigEnd) {
					len = arr[pos + 2] + arr[pos + 3] * 65536;
				}
				else {
					len = arr[pos + 2] * 65536 + arr[pos + 3];
				}
				if (len == 1) {
					var offs:uint = 0;
					var arlen:int = arr.length;
					if (bigEnd) {
						offs = arr[pos + 4] + arr[pos + 5] * 65536;
					}
					else {
						offs = arr[pos + 4] * 65536 + arr[pos + 5];
					}
					
					var ix:int = offs / 2;
					var n1:Number = 0;
					var n2:Number = 0;
					var n3:Number = 0;
					if (signed) {
						var ras1:int = 0; 
						var ras2:int = 0; 
						if (bigEnd) {
							ras1 = int (arr[ix] + arr[ix + 1] * 65536);
							ras2 = int (arr[ix + 2] + arr[ix + 3] * 65536);
						}
						else {
							ras1 = int (arr[ix] * 65536 + arr[ix + 1]);
							ras2 = int (arr[ix + 2] * 65536 + arr[ix + 3]);
						}
						if (ras1 >= ras2) {
							value.kStr = (ras1/ras2).toFixed(2);
						}
						else {
							n1 = ras2/ras1;
							if (n1 < 3) {
								value.kStr = "1/" + n1.toFixed(2);
							}
							else {
								value.kStr = "1/" + n1.toFixed(0);
							}
						}
						n1 = ras1;
						n2 = ras2;
						if (n2 != 0) {
							n3 = n1/n2;
							value.kStr2 = n3.toFixed(0);
							value.kStr3 = n3.toFixed(1);
						}
					}
					else {
						var ra1:uint = 0; 
						var ra2:uint = 0; 
						if (bigEnd) {
							ra1 = arr[ix] + arr[ix + 1] * 65536;
							ra2 = arr[ix + 2] + arr[ix + 3] * 65536;
						}
						else {
							ra1 = arr[ix] * 65536 + arr[ix + 1];
							ra2 = arr[ix + 2] * 65536 + arr[ix + 3];
						}
						if (ra1 >= ra2) {
							value.kStr = (ra1/ra2).toFixed(2);
						}
						else {
							n1 = ra2/ra1;
							if (n1 < 3) {
								value.kStr = "1/" + n1.toFixed(2);
							}
							else {
								value.kStr = "1/" + n1.toFixed(0);
							}
						}
						n1 = ra1;
						n2 = ra2;
						if (n2 != 0) {
							n3 = n1/n2;
							value.kStr2 = n3.toFixed(0);
							value.kStr3 = n3.toFixed(1);
						}
					}
					return true;
				}
			}
		}
	} while(pos > 0);
	return false;
}


private function getHex (b:uint):String
{
	var s:String = b.toString(16);
	if (s.length == 1) {
		s = "0" + s;
	}
	return s;
}

private function getFixString (b:uint):String
{
	var s:String = b.toString(10);
	if (s.length == 1) {
		s = "00000" + s;
	}
	else if (s.length == 2) {
		s = "0000" + s;
	}
	else if (s.length == 3) {
		s = "000" + s;
	}
	else if (s.length == 4) {
		s = "00" + s;
	}
	else if (s.length == 5) {
		s = "0" + s;
	}
	
	return s;
}


protected function getSizeStr (len:Number):String
{
	var str:String = "";
	var numstr:String = len.toString();
	var sz:int = numstr.length;
	var fst:int = sz % 3;
	if (sz < 4) {
		return numstr;
	}
	if (fst > 0) {
		str = numstr.substr(0, fst);
		numstr = numstr.substr(fst);
		str += ".";
	}
	do {
		if (numstr.length < 4) {
			str += numstr;
			return str;
		}
		str += numstr.substr (0, 3);
		numstr = numstr.substr (3);
		str += ".";
	} while (numstr.length > 0);
	
	return str;
}

// Setting in Flex Compiler to load local images
// -use-network=false

//=======================================================
/*
\history

WGo-2015-02-04: Created

*/

