//-----------------------------------------------------------------------------
/*!
 **	\file	Common/FileSystemList.h
 **
 **	\author	Wolfgang Goldbach
 */
//-----------------------------------------------------------------------------

#ifndef FILESYSTEMLIST_H_
#define FILESYSTEMLIST_H_

#include "wx/wx.h"
//#include "wx/listbox.h"
#include "wx/listctrl.h"


#include <vector>


typedef std::vector<std::wstring> TFilePaths;
typedef std::vector<wxString> TFileNames;

typedef bool (*FSListCallback)(const wxString&, void*);


class FileSystemList : public wxListCtrl
{
public:
    FileSystemList (wxWindow *parent,
					wxWindowID id
					);
	
	bool SetDirectory (const std::wstring &path);

	bool ChangeDirectory (const std::wstring &name);
	
	bool ChangeToParent();
	
	void SetSelectedFile (const std::wstring &name);
	
	std::wstring GetDirectory();
	
	TFilePaths GetSelection();
	
	wxString GetFileCountInfo (bool fromSelection, wxString *moddate = NULL);
	
	std::wstring GetVolumeInfo();
	
	TFileNames GetImageFiles();

	
	bool SetListSelection (int sel);
	
	void setChangeCallback (FSListCallback cb, void *data) { changeCallback_ = cb; userdata_c_ = data; }
	void setSelectionCallback (FSListCallback cb, void *data) { selCallback_ = cb; userdata_s_ = data; }
	void setExecuteCallback (FSListCallback cb, void *data) { execCallback_ = cb; userdata_e_ = data; }

	void ProcessKeyEvent (int key);
	
    //void OnButton(wxCommandEvent& event);

private:
    //wxButton *m_btnModal,
	
	wxString      directory_;
	wxString      lastDirectory_;
	wxString      selName_;
	wxString      dirName_;
	TFileNames    files_;
	TFileNames    hiddenFiles_;
	TFileNames    dirs_;
	TFileNames    hiddenDirs_;
	TFileNames    curfiles_;
	TFileNames    curdirs_;
	bool          updating_;
	FSListCallback changeCallback_;
	void        *  userdata_c_;
	FSListCallback selCallback_;
	void        *  userdata_s_;
	FSListCallback execCallback_;
	void        *  userdata_e_;
	
	void OnListClick (wxListEvent&);
	void OnListDClick (wxListEvent&);
	void OnKeyDown (wxKeyEvent&);
	void OnKeyUp (wxKeyEvent&);
	void OnSize (wxSizeEvent&);
	bool onKeyDown (int key);
	
	bool getFiles();
	bool changeDirectory (const wxString &name);
	bool processSelectedFile();

    wxDECLARE_EVENT_TABLE();
};


#endif // FILESYSTEMLIST_H_

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-05-25: created
 
 */
