//-----------------------------------------------------------------------------
/*!
 **	\file	Common/FileSystemList.cpp
 **
 **	\author	Wolfgang Goldbach
 */
//-----------------------------------------------------------------------------


#include "FileSystemList.h"

// wxWidgets
#include <wx/dir.h>
#include <wx/filefn.h>
#include <wx/filename.h>
#include "wx/image.h"
#include "wx/imaglist.h"

//#include "_Res/icon_newfolder.xpm"
//#include "_Res/icon_new.xpm"
#include "_Res/icon_folder.xpm"
#include "_Res/icon_setting.xpm"

namespace {
	
	//const wxColour green_m (235, 255, 220);
	//const wxColour yellow_m (255, 255, 210);
	const wxColour green_m (225, 255, 210);
	const wxColour yellow_m (255, 255, 190);
	const wxColour green_l (240, 255, 225);
	const wxColour yellow_l (255, 255, 220);
	const wxColour grey_l (245, 245, 245);

	
	void addSorted (TFileNames &targetList, const TFileNames &sourceList)
	{
		for (unsigned int srcix = 0; srcix < sourceList.size(); ++srcix) {
			if (targetList.size() == 0) {
				targetList.push_back (sourceList[srcix]);
			}
			else {
				bool inserted = false;
				for (TFileNames::iterator tgit = targetList.begin(); tgit != targetList.end(); ++tgit) {
					if (tgit->CmpNoCase(sourceList[srcix]) > 0) {
						targetList.insert (tgit, sourceList[srcix]);
						inserted = true;
						break;
					}
				}
				if (!inserted) {
					targetList.push_back (sourceList[srcix]);
				}
			}
		}
	}
	
	void setListItemGray_ (wxListCtrl *listbox, int sel)
	{
		int count = listbox->GetItemCount();
		if (sel < 0 || sel >= count) {
			return;
		}
		wxListItem info;
		info.SetId (sel);
		info.SetColumn (0);
		listbox->GetItem (info);
		info.SetTextColour (wxColour(128, 128, 128));
		listbox->SetItem (info);
		//info.SetBackgroundColour();
	}
	
	wxString getSizeString (wxULongLong sz)
	{
		wxString retstr;
		wxULongLong szg = sz / 1000000000;
		if (szg > 0) {
			retstr << szg << L".";
		}

		sz = sz % 1000000000;
		wxULongLong szm = sz / 1000000;
		if (szm > 0 || szg > 0) {
			wxString sm;
			sm << szm;
			if (!retstr.empty()) {
				if (sm.size() == 1) {
					sm.Prepend (L"00");
				}
				else if (sm.size() == 2) {
					sm.Prepend (L"0");
				}
			}
			retstr << sm << L".";
		}

		sz = sz % 1000000;
		wxULongLong szt = sz / 1000;
		if (szt > 0 || szm > 0 || szg > 0) {
			wxString st;
			st << szt;
			if (!retstr.empty()) {
				if (st.size() == 1) {
					st.Prepend (L"00");
				}
				else if (st.size() == 2) {
					st.Prepend (L"0");
				}
			}
			retstr << st << L".";
		}
		
		sz = sz % 1000;
		wxString se;
		se << sz;
		if (!retstr.empty()) {
			if (se.size() == 1) {
				se.Prepend (L"00");
			}
			else if (se.size() == 2) {
				se.Prepend (L"0");
			}
		}
		retstr << se << L" Bytes";
		
		return retstr;
	}
	
	wxString getExtension (const wxString &fname)
	{
		wxString::size_type ix = fname.find_last_of (L'.');
		if (ix != wxString::npos && ix < fname.size() - 1) {
			return fname.substr(ix + 1).MakeLower();
		}
		return L"";
	}

}


wxBEGIN_EVENT_TABLE(FileSystemList, wxListCtrl)
	//EVT_LISTBOX(wxID_ANY, FileSystemList::OnListClick)
	//EVT_LISTBOX_DCLICK(wxID_ANY, FileSystemList::OnListDClick)
	//EVT_COMMAND_ENTER(wxID_ANY, FileSystemList::OnListDClick)
	EVT_LIST_ITEM_SELECTED(wxID_ANY, FileSystemList::OnListClick)
	//EVT_LIST_ITEM_DESELECTED(wxID_ANY, FileSystemList::OnListClick)
	EVT_LIST_ITEM_ACTIVATED(wxID_ANY, FileSystemList::OnListDClick)
	EVT_KEY_DOWN(FileSystemList::OnKeyDown)
	EVT_KEY_UP(FileSystemList::OnKeyUp)
	EVT_SIZE(FileSystemList::OnSize)
wxEND_EVENT_TABLE()



FileSystemList::FileSystemList (wxWindow *parent,
								wxWindowID id)
: wxListCtrl (parent, id, wxDefaultPosition, wxDefaultSize, wxLC_REPORT | wxLC_NO_HEADER | wxBORDER_STATIC)
, updating_(false)
, changeCallback_(NULL)
, selCallback_(NULL)
, execCallback_(NULL)
{
	InsertColumn (0, L"");
	
	wxImageList *imgList = new wxImageList (16, 16, false);
	imgList->Add (wxBitmap(icon_setting));
	imgList->Add (wxBitmap(icon_folder));
	AssignImageList (imgList, wxIMAGE_LIST_SMALL);
}

//btNewJob_ = new wxBitmapButton (this, BT_NEWJOB, wxBitmap(icon_new));
//btNewSet_ = new wxBitmapButton (this, BT_NEWSET, wxBitmap(icon_newfolder));

//void addToImageList (wxImageList *imgList, bool autoMode)
		//imgList->Add (Window::CreateBitmapFromPng(autojobPngStr, sizeof(autojobPngStr) / sizeof(char*)));
//		imgList->Add (createBitmap(autojobPngStr, sizeof(autojobPngStr) / sizeof(char*)));



bool FileSystemList::SetDirectory (const std::wstring &path)
{
	lastDirectory_ = directory_;
	directory_ = path;
	return getFiles();
}

bool FileSystemList::ChangeDirectory (const std::wstring &name)
{
	return true;
}

bool FileSystemList::ChangeToParent()
{
	return true;
}

void FileSystemList::SetSelectedFile (const std::wstring &name)
{
	int count = GetItemCount();
	for (int ix = 0; ix < count; ++ix) {
		if (wxString(name).IsSameAs (GetItemText(ix))) {
			SetListSelection (ix);
			return;
		}
	}
}

std::wstring FileSystemList::GetDirectory()
{
	return directory_.wc_str();
}

TFilePaths FileSystemList::GetSelection()
{
	TFilePaths retval;
	wxFileName fname (directory_, selName_);
	retval.push_back (fname.GetFullPath().wc_str());
	
	return retval;
}

std::wstring FileSystemList::GetVolumeInfo()
{
	wxLongLong total;
	wxLongLong free;
	wxGetDiskSpace (directory_, &total, &free);
	wxString msg (L"Free: ");
	msg << free / (1000 * 1000 * 1000) << L" GB of total " << total / (1000 * 1000 * 1000) << L" GB";
	return msg.wc_str();
}

wxString FileSystemList::GetFileCountInfo (bool fromSelection, wxString *moddate)
{
	wxString retstr;
	if (fromSelection) {
		if (selName_.empty()) {
			return retstr;
		}
		wxFileName fname (directory_, selName_);
		if (fname.FileExists()) {
			//retstr = fname.GetHumanReadableSize (L"no info");
			retstr = getSizeString (fname.GetSize());
		}
		else {
			int dircnt = 0;
			int filecnt = 0;
			wxDir dir (fname.GetFullPath());
			if (dir.IsOpened()) {
				wxString tmp;
				if (dir.GetFirst (&tmp, wxEmptyString, wxDIR_DIRS | wxDIR_HIDDEN)) {
					++dircnt;
					while (dir.GetNext (&tmp)) {
						++dircnt;
					}
				}
				if (dir.GetFirst (&tmp, wxEmptyString, wxDIR_FILES | wxDIR_HIDDEN)) {
					++filecnt;
					while (dir.GetNext (&tmp)) {
						++filecnt;
					}
				}
			}
			else {
				return retstr;
			}
			retstr << dircnt << L" Subfolder(s), " << filecnt << L" File(s)";
		}
		if (moddate) {
			wxDateTime dt = fname.GetModificationTime();
			//*moddate = dt.FormatISOCombined(' ');
			wxString dtstr = dt.Format ("%a %b %d %Y  %X");
			//wxString::size_type ix = dtstr.find (L',');
			//if (ix != wxString::npos) {
			//	*moddate = dtstr.substr(ix + 2);
			//}
			//else {
				*moddate = dtstr;
			//}
		}
	}
	else {
		int count = curfiles_.size() + curdirs_.size();
		retstr << L" (" << count << L")";
	}
	return retstr;
}

//-----------------------------------------------------------------------------

void FileSystemList::OnListClick (wxListEvent& evt)
{
	if (updating_) {
		evt.Skip();
		return;
	}
	long ev_item = evt.GetIndex();
	
	//long item = listbox_->GetNextItem (-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
	if (ev_item > -1) {
		selName_ = GetItemText(ev_item);
	}
	if (selCallback_ != NULL) {
		selCallback_ (selName_, userdata_s_);
	}
	evt.Skip();
}

void FileSystemList::OnListDClick (wxListEvent& evt)
{
	if (updating_) {
		evt.Skip();
		return;
	}
	long ev_item = evt.GetIndex();
	if (ev_item < 0) {
		return;
	}
	selName_ = GetItemText(ev_item);
	if (selName_.IsSameAs (L"..") || curdirs_.end() != std::find (curdirs_.begin(), curdirs_.end(), selName_)) {
		if (changeDirectory (selName_)) {
			getFiles();
		}
		return;
	}
	else {
		if (execCallback_) {
			execCallback_ (selName_, userdata_e_);
		}
	}
}

void FileSystemList::OnKeyDown (wxKeyEvent& evt)
{
	if (onKeyDown (evt.GetKeyCode())) {
		return;
	}
	
	//if (code == 27 || (code == 46 && evt.MetaDown())) {
	//}
	//else if (code == 87 && evt.MetaDown()) {
		// do not let pass Cmd+W
	//}
	//if ((code == WXK_UP || code == WXK_DOWN) && evt.ControlDown() && g_Panel != NULL) {

	
	evt.Skip();
}

bool FileSystemList::onKeyDown (int key)
{
	long item = GetNextItem (-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
	if (item < 0) {
		return false;
	}
	
	if (key == WXK_UP) {
		SetListSelection (item - 1);
		return true;
	}
	else if (key == WXK_DOWN) {
		SetListSelection (item + 1);
		return true;
	}
	else if (key == WXK_LEFT) {
		if (!directory_.IsSameAs(L"/")) {
			selName_ = L"..";
			if (changeDirectory (selName_)) {
				selName_ = dirName_;
				getFiles();
			}
		}
		return true;
	}
	
	if (selName_.empty()) {
		return false;
	}
	
	if (key == WXK_RIGHT && selName_ != L"..") {
		if (changeDirectory (selName_)) {
			getFiles();
		}
		return true;
	}
	else if (key == 32) {
		if (execCallback_) {
			execCallback_ (selName_, userdata_e_);
		}
		return true;
	}
	return false;
}

void FileSystemList::OnKeyUp (wxKeyEvent& evt)
{
	evt.Skip();
}

void FileSystemList::OnSize (wxSizeEvent& evt)
{
	SetColumnWidth (0, GetRect().width);
	Refresh();
	evt.Skip();
}

bool FileSystemList::getFiles()
{
	wxDir dir (directory_);
	if (!dir.IsOpened()) {
		directory_ = lastDirectory_;
		// do nothing
		return false;
	}
	lastDirectory_ = directory_;
	dirs_.clear();
	hiddenDirs_.clear();
	files_.clear();
	hiddenFiles_.clear();
	wxString filename;
	if (dir.GetFirst (&filename, wxEmptyString, wxDIR_FILES)) {
		files_.push_back (filename);
		while (dir.GetNext (&filename)) {
			files_.push_back (filename);
		}
	}
	if (dir.GetFirst (&filename, wxEmptyString, wxDIR_DIRS)) {
		dirs_.push_back (filename);
		while (dir.GetNext (&filename)) {
			dirs_.push_back (filename);
		}
	}
	if (dir.GetFirst (&filename, wxEmptyString, wxDIR_FILES | wxDIR_HIDDEN)) {
		if (files_.end() == std::find(files_.begin(), files_.end(), filename)) {
			hiddenFiles_.push_back (filename);
		}
		while (dir.GetNext (&filename)) {
			if (files_.end() == std::find(files_.begin(), files_.end(), filename)) {
				hiddenFiles_.push_back (filename);
			}
		}
	}
	if (dir.GetFirst (&filename, wxEmptyString, wxDIR_DIRS | wxDIR_HIDDEN)) {
		if (dirs_.end() == std::find(dirs_.begin(), dirs_.end(), filename)) {
			hiddenDirs_.push_back (filename);
		}
		while (dir.GetNext (&filename)) {
			if (dirs_.end() == std::find(dirs_.begin(), dirs_.end(), filename)) {
				hiddenDirs_.push_back (filename);
			}
		}
	}
	DeleteAllItems();
	SetColumnWidth (0, GetRect().width);
	SetBackgroundColour (grey_l);
	
	curfiles_.clear();
	curdirs_.clear();
	addSorted (curfiles_, files_);
	addSorted (curfiles_, hiddenFiles_);
	addSorted (curdirs_, dirs_);
	addSorted (curdirs_, hiddenDirs_);
	long insert_ix = 0;
	if (directory_.size() > 1) {
		//Append (L"D ..");
		InsertItem (insert_ix, L"..", 1);
		SetItemBackgroundColour (insert_ix, green_m);
		++insert_ix;
	}
	for (unsigned int ixd = 0; ixd < curdirs_.size(); ++ixd) {
		//Append (curdirs[ixd]);
		InsertItem (insert_ix, curdirs_[ixd], 1);
		if (insert_ix % 2 == 0) {
			SetItemBackgroundColour (insert_ix, green_m);
		}
		else {
			SetItemBackgroundColour (insert_ix, green_l);
		}
		++insert_ix;
	}
	for (unsigned int ixf = 0; ixf < curfiles_.size(); ++ixf) {
		//Append (curfiles[ixf]);
		InsertItem (insert_ix, curfiles_[ixf], 0);
		if (insert_ix % 2 == 0) {
			SetItemBackgroundColour (insert_ix, yellow_m);
		}
		else {
			SetItemBackgroundColour (insert_ix, yellow_l);
		}
		++insert_ix;
	}
	long selection = 0;
	if (!dirName_.empty()) {
		selection = FindItem (0, dirName_);
		if (selection < 0) {
			selection = 0;
		}
	}
	SetListSelection (selection);
	
	if (changeCallback_ != NULL) {
		changeCallback_ (directory_, userdata_c_);
	}
	if (selCallback_ != NULL) {
		if (!dirName_.empty()) {
			selCallback_ (dirName_, userdata_s_);
		}
		else {
			selCallback_ (L"..", userdata_s_);
		}
	}
	
	return true;
}

// wxSize GetClientSize() // .GetHeight()
// wxSize GetVirtualSize()

bool FileSystemList::SetListSelection (int sel)
{
	int count = GetItemCount();
	if (sel < 0 || sel >= count) {
		return false;
	}
	//updating_ = true;
	
	//SetExtraStyle(previousExtraStyle | wxWS_EX_BLOCK_EVENTS); // event comes nevertheless
	//Freeze();  // the same
	
	SetItemState (sel, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);
	long next = -1;
	do {
		next = GetNextItem (next, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if ( next != -1 ) {
			SetItemState (next, 0, wxLIST_STATE_SELECTED);
		}
	} while (next >= 0);
	
	SetItemState (sel, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
	
	EnsureVisible (sel);

	//updating_ = false;
	return true;
}

bool FileSystemList::changeDirectory (const wxString &name)
{
	wxFileName dir (directory_, L"");
	if (name.empty()) {
		return false;
	}

	if (name == L"..") {
		const wxArrayString & dirs = dir.GetDirs();
		//dirName_ = dir.GetFullName(); // works not for directory
		dirName_ = dirs.Last();
		dir.RemoveLastDir();
	}
	else {
		dirName_.erase();
		dir.AppendDir (name);
	}

	if (!dir.DirExists()) {
		return false;
	}
	directory_ = dir.GetFullPath();
	return true;
}

bool FileSystemList::processSelectedFile()
{
	return true;
}

void FileSystemList::ProcessKeyEvent (int key)
{
	SetFocus();
	if (key == WXK_UP || key == WXK_DOWN || key == WXK_LEFT || key == WXK_RIGHT) {
		onKeyDown (key);
	}
}

TFileNames FileSystemList::GetImageFiles()
{
	TFileNames retval;
	for (unsigned int ix = 0; ix < files_.size(); ++ix) {
		wxString ext = getExtension (files_[ix]);
		if (ext == L"jpg" || ext == L"jpeg" || ext == L"png" || ext == L"gif" || ext == L"tif" || ext == L"tiff" || ext == L"bmp") {
			retval.push_back (files_[ix]);
		}
	}
	return retval;
}


//-----------------------------------------------------------------------------

/*
\history
 WGo-2016-05-25: created
 
*/
