//-----------------------------------------------------------------------------
/*!
 **	\file	common/fileview.cpp
 **
 **	\project WGFileConverter
 **	\author	Wolfgang Goldbach
 */
//-----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// headers
// ----------------------------------------------------------------------------

// For compilers that support precompilation, includes "wx/wx.h".
//#include "wx/wxprec.h"

// Project includes
#include "WvIniFile.h"
#include "WvAudio.h"

#include "FileSystemList.h"
#include "TextContent.h"
#include "PreviewTextCtrl.h"
#include "ImageView.h"
#include "Utilities.h"
#include "ChooseActionDialog.h"


//#ifndef WX_PRECOMP
#include "wx/wx.h"

#include "wx/artprov.h"
#include "wx/cmdline.h"
#include "wx/notifmsg.h"
#include "wx/settings.h"
#include "wx/infobar.h"
#include "wx/filesys.h"
#include "wx/fs_arc.h"
#include "wx/fs_mem.h"
#include "wx/stattext.h"
#include "wx/splitter.h"

#ifndef wxHAS_IMAGES_IN_RESOURCES
    #include "../../common/_Res/sample.xpm"
#endif

#if defined(__WXMSW__) || defined(__WXOSX__)
//#include "stop.xpm"
//#include "refresh.xpm"
#endif

#include "wx/dcgraph.h"
//#include "wx/osx/pnghand.h"
#include <wx/stdpaths.h>
#include <wx/kbdstate.h>

#include "wxlogo.xpm"

#include <Carbon/Carbon.h>


using namespace Wview;
using namespace wgfc;

//=========================================================================

namespace {
	
	//std::string recordingPath_ ("/Users/w.goldbach/temp/test/");
	//bool initialized_ = false;
	
	int minWindowWidth = 600;
	int minWindowHeight = 600;
	int initWindowWidth = 900;
	int initWindowHeight = 800;
	
	wxTimer       * timer_ = NULL;

	
	enum {
		
		LB_FILELIST = wxID_LAST + 1,
		SPLITTER_1,
		BT_HOME,
		BT_DIR1,
		BT_DIR2,
		BT_CONV,
		ET_PREVIEW,
		CK_CSTRING,
		CK_SPACES,
		CK_LINEBREAKS,
		CK_WRAP,
		CK_FULL,
		CK_FONT,
		CK_BINARY,
	};

	wxString startdir_; // = wxStandardPaths::Get().GetDocumentsDir();
	
	
	void setStartDirectory()
	{
		startdir_ = wxStandardPaths::Get().GetDocumentsDir();
		wxFileName desktopDir (startdir_, L"");
		desktopDir.RemoveLastDir();
		desktopDir.AppendDir (L"Desktop");
		if (desktopDir.DirExists()) {
			startdir_ = desktopDir.GetPath();
		}
	}
	
	bool isImageFile (const wxFileName &file)
	{
		wxString ext (file.GetExt().Upper());
		return ext == L"JPG" || ext == L"JPEG" || ext == L"PNG" || ext == L"GIF" || ext == L"TIF" || ext == L"TIFF" || ext == L"BMP";
	}

	bool checkModifier (const unsigned char * km, unsigned short scanCode)
	{
		// Magic formula to test a bit in the keymap
		return (( km[scanCode>>3] >> ( scanCode & 7 ) ) & 1 );
	}
	
	EventModifiers getModifiers()
	{
		KeyMap keyMap;
		GetKeys( keyMap );
		
		unsigned char * km = reinterpret_cast<unsigned char *>(keyMap);
		
		EventModifiers modifiers = 0
		| ( checkModifier( km, 0x37) ? cmdKey         : 0 )
		| ( checkModifier( km, 0x38) ? shiftKey       : 0 )
		| ( checkModifier( km, 0x39) ? alphaLock      : 0 )
		| ( checkModifier( km, 0x3a) ? optionKey      : 0 )
		| ( checkModifier( km, 0x3b) ? controlKey     : 0 )
		| ( checkModifier( km, 0x3c) ? rightShiftKey  : 0 )
		| ( checkModifier( km, 0x3d) ? rightOptionKey : 0 )
		| ( checkModifier( km, 0x3e) ? rightControlKey: 0 )
		;
		return modifiers;
	}

	// from HIToolbox/Events.h
	//enum {
	//	activeFlag                    = 1 << activeFlagBit,
	//	btnState                      = 1 << btnStateBit,
	//	cmdKey                        = 1 << cmdKeyBit,
	//	shiftKey                      = 1 << shiftKeyBit,
	//	alphaLock                     = 1 << alphaLockBit,
	//	optionKey                     = 1 << optionKeyBit,
	//	controlKey                    = 1 << controlKeyBit,
	//	rightShiftKey                 = 1 << rightShiftKeyBit, /* Not supported on Mac OS X.*/
	//	rightOptionKey                = 1 << rightOptionKeyBit, /* Not supported on Mac OS X.*/
	//	rightControlKey               = 1 << rightControlKeyBit /* Not supported on Mac OS X.*/
	//};

}

//=========================================================================

enum
{
    // menu items
    Minimal_Quit = wxID_EXIT,
	
    // it is important for the id corresponding to the "About" command to have
    // this standard value as otherwise it won't be handled properly under Mac
    // (where it is special and put into the "Apple" menu)
    Minimal_About = wxID_ABOUT
};

class MyApp : public wxApp
{
public:
    MyApp()
    {
    }

    virtual bool OnInit();

private:
    wxString m_url;
};

IMPLEMENT_APP(MyApp)


class SourceViewDialog : public wxDialog
{
public:
    SourceViewDialog(wxWindow* parent, wxString source);
};

class MyFrame;

//class PreviewEditCtrl : public wxTextCtrl
//{
//public:
//	PreviewEditCtrl (wxWindow* parent, wxWindowID id, MyFrame *frame, bool wrap)
	//: wxTextCtrl (parent, id, L"", wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE | wxTE_READONLY | (wrap ? 0 : wxHSCROLL))
//	: wxTextCtrl (parent, id, L"", wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE | wxTE_READONLY)
//	, frame_(frame), wrap_(wrap)
//	{
//	}
//	bool isWrapLines() { return wrap_; }
//private:
//	MyFrame * frame_;
//	bool wrap_;
//	void OnMouseDown (wxMouseEvent &evt);
//	void eventMouseFn (wxMouseEvent& evt);
	
  //  wxDECLARE_EVENT_TABLE();
//};

//wxBEGIN_EVENT_TABLE(PreviewEditCtrl, wxTextCtrl)
//EVT_LEFT_DOWN(PreviewEditCtrl::OnMouseDown)
//EVT_MOUSE_EVENTS(PreviewEditCtrl::eventMouseFn)
//wxEND_EVENT_TABLE()


class MyFrame : public wxFrame
{
public:
    MyFrame();
    ~MyFrame();
    void OnQuit(wxCommandEvent& event);
    void OnAbout(wxCommandEvent& event);
	
	void onFileListChange (const wxString &name);
	void onSelectionChange (const wxString &name);
	void onExecute (const wxString &name);
	
	void onPreviewEditMouseDown (wxMouseEvent &evt);
	
	void onImageClosing (const std::wstring &name);
	
private:
	
	FileSystemList       * fslist_;
	wxButton             * btHome_;
	wxButton             * btDir1_;
	wxButton             * btDir2_;
	wxButton             * btConvert_;
	wxCheckBox           * ckCString_;
	wxCheckBox           * ckSpaces_;
	wxCheckBox           * ckLineBreaks_;
	wxCheckBox           * ckWrap_;
	wxCheckBox           * ckFont_;
	wxCheckBox           * ckBinary_;
	wxStaticText         * stPath_;
	wxStaticText         * stFileInfo1_;
	wxStaticText         * stFileInfo2_;
	wxStaticText         * stFileInfo3_;
	wxStaticText         * stExifInfo1_;
	wxStaticText         * stExifInfo2_;
	wxStaticText         * stExifInfo3_;
	wxStaticText         * stExifInfo4_;
	wxStaticText         * stExifInfo5_;
	wxStaticText         * stExifInfo6_;
	wxStaticText         * stExifInfo7_;
	wxStaticText         * stExifInfo8_;
	wxStaticText         * stExifInfo9_;
	wxStaticText         * stExifInfo10_;
	wxStaticText         * stExifInfo11_;
	wxStaticText         * stExifInfo12_;
	wxSplitterWindow     * splitter1_;
	wxPanel              * topPanel_;
	wxPanel              * bottomPanel_;
	PreviewTextCtrl      * etPreview_;
	ExclusiveImageView   * imgView_;
	
	wxBoxSizer           * p2sizer_;
	wxBoxSizer           * p2HorSizer1_;
	wxBoxSizer           * p2VerSizer1_;
	
	int                    sash1_;
	TextContent          * textCt_;
	wxString               lastName_;
	
	void OnBTHome (wxCommandEvent &evt);
	void OnBtDir1 (wxCommandEvent &evt);
	void OnBtDir2 (wxCommandEvent &evt);
	void OnBtConvert (wxCommandEvent &evt);
	void OnCkCString (wxCommandEvent &evt);
	void OnCkSpaces (wxCommandEvent &evt);
	void OnCkLineBreaks (wxCommandEvent &evt);
	void OnCkWrap (wxCommandEvent &evt);
	void OnCkFont (wxCommandEvent &evt);
	void OnCkBinary (wxCommandEvent &evt);
	void OnKeyDown (wxKeyEvent& evt);
	void OnKeyUp (wxKeyEvent& evt);
	void OnTimer (wxTimerEvent&);
	void Initialize();
	void SaveGeo();

    wxDECLARE_EVENT_TABLE();
};


namespace {

	bool OnFileListChange (const wxString &name, void *data)
	{
		MyFrame *frame = static_cast<MyFrame*>(data);
		frame->onFileListChange (name);
		return true;
	}
	
	bool OnSelectionChange (const wxString &name, void *data)
	{
		MyFrame *frame = static_cast<MyFrame*>(data);
		frame->onSelectionChange (name);
		return true;
	}

	bool OnExecute (const wxString &name, void *data)
	{
		MyFrame *frame = static_cast<MyFrame*>(data);
		frame->onExecute (name);
		return true;
	}
	
	class ImageCloseCB : public ImageCallback
	{
	public:
		ImageCloseCB (MyFrame *f) : pThis(f) {}
		virtual ~ImageCloseCB() {}
		virtual void operator()(const std::wstring &s) { pThis->onImageClosing(s); }
	private:
		MyFrame * pThis;
	};
	
}

// ============================================================================
// implementation
// ============================================================================

bool MyApp::OnInit()
{

    if ( !wxApp::OnInit() )
        return false;

    //Required for virtual file system archive and memory support
    wxFileSystem::AddHandler(new wxArchiveFSHandler);
    wxFileSystem::AddHandler(new wxMemoryFSHandler);
	
	wxInitAllImageHandlers();

    // Create the memory files
    wxImage::AddHandler(new wxPNGHandler);
    wxMemoryFSHandler::AddFile("logo.png", 
        wxBitmap(wxlogo_xpm), wxBITMAP_TYPE_PNG);
    wxMemoryFSHandler::AddFile("page1.htm",
        "<html><head><title>File System Example</title>"
        "<link rel='stylesheet' type='text/css' href='memory:test.css'>"
        "</head><body><h1>Page 1</h1>"
        "<p><img src='memory:logo.png'></p>"
        "<p>Some text about <a href='memory:page2.htm'>Page 2</a>.</p></body>");
    wxMemoryFSHandler::AddFile("page2.htm",
        "<html><head><title>File System Example</title>"
        "<link rel='stylesheet' type='text/css' href='memory:test.css'>"
        "</head><body><h1>Page 2</h1>"
        "<p><a href='memory:page1.htm'>Page 1</a> was better.</p></body>");
    wxMemoryFSHandler::AddFile("test.css", "h1 {color: red;}");

    MyFrame *frame = new MyFrame;
    frame->Show();


	return true;
}

wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
EVT_MENU(Minimal_Quit,  MyFrame::OnQuit)
EVT_MENU(Minimal_About, MyFrame::OnAbout)
EVT_BUTTON(BT_HOME, MyFrame::OnBTHome)
EVT_BUTTON(BT_DIR1, MyFrame::OnBtDir1)
EVT_BUTTON(BT_DIR2, MyFrame::OnBtDir2)
EVT_BUTTON(BT_CONV, MyFrame::OnBtConvert)
EVT_CHECKBOX(CK_CSTRING, MyFrame::OnCkCString)
EVT_CHECKBOX(CK_SPACES, MyFrame::OnCkSpaces)
EVT_CHECKBOX(CK_LINEBREAKS, MyFrame::OnCkLineBreaks)
EVT_CHECKBOX(CK_WRAP, MyFrame::OnCkWrap)
EVT_CHECKBOX(CK_FONT, MyFrame::OnCkFont)
EVT_CHECKBOX(CK_BINARY, MyFrame::OnCkBinary)
EVT_KEY_DOWN(MyFrame::OnKeyDown)
EVT_KEY_UP(MyFrame::OnKeyUp)
EVT_TIMER(-1, MyFrame::OnTimer)
wxEND_EVENT_TABLE()


MyFrame::MyFrame() :
wxFrame (NULL, wxID_ANY, "My Frame Sample"), sash1_(300), textCt_(NULL)
{
    // set the frame icon
    SetIcon(wxICON(sample));
    SetTitle("My Frame Sample");
	
	wxMenu *fileMenu = new wxMenu;
    wxMenu *helpMenu = new wxMenu;
    helpMenu->Append(Minimal_About, "&About\tF1", "Show about dialog");
	
    fileMenu->Append(Minimal_Quit, "E&xit\tAlt-X", "Quit this program");
	
    // now append the freshly created menu to the menu bar...
    wxMenuBar *menuBar = new wxMenuBar();
    menuBar->Append(fileMenu, "&File");
    menuBar->Append(helpMenu, "&Help");
	
    SetMenuBar(menuBar);
	
    CreateStatusBar(2);
    SetStatusText("Welcome to wxWidgets!", 0);
    SetStatusText("(C) axaio software", 1);

    wxBoxSizer* topsizer = new wxBoxSizer(wxVERTICAL);
    wxBoxSizer* p1sizer = new wxBoxSizer(wxVERTICAL);
    wxBoxSizer* p1HorSizer1 = new wxBoxSizer(wxHORIZONTAL);
    wxBoxSizer* p1HorSizer2 = new wxBoxSizer(wxHORIZONTAL);
    wxBoxSizer* p1VerSizer1 = new wxBoxSizer(wxVERTICAL);
    p2sizer_ = new wxBoxSizer(wxVERTICAL);
    p2HorSizer1_ = new wxBoxSizer(wxHORIZONTAL);
    p2VerSizer1_ = new wxBoxSizer(wxVERTICAL);
	
	splitter1_ = new wxSplitterWindow (this, SPLITTER_1, wxDefaultPosition, wxDefaultSize, wxSP_LIVE_UPDATE | wxSP_3DSASH);
	splitter1_->SetMinimumPaneSize (250);
	topPanel_ = new wxPanel (splitter1_, -1);
	bottomPanel_ = new wxPanel (splitter1_, -1);
	
	stPath_ = new wxStaticText (topPanel_, wxID_ANY, L"*");
	stFileInfo1_ = new wxStaticText (bottomPanel_, wxID_ANY, L"info", wxDefaultPosition, wxSize(243, -1));
	stFileInfo2_ = new wxStaticText (bottomPanel_, wxID_ANY, L"info", wxDefaultPosition, wxSize(243, -1));
	stFileInfo3_ = new wxStaticText (bottomPanel_, wxID_ANY, L"Image:", wxDefaultPosition, wxSize(243, -1));
	stExifInfo1_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo2_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo3_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo4_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo5_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo6_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo7_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo8_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo9_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo10_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo11_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	stExifInfo12_ = new wxStaticText (bottomPanel_, wxID_ANY, L"", wxDefaultPosition, wxSize(243, -1));
	btHome_ = new wxButton (topPanel_, BT_HOME, L"Home", wxDefaultPosition, wxSize(70, -1));
	btDir1_ = new wxButton (topPanel_, BT_DIR1, L"Dir1", wxDefaultPosition, wxSize(70, -1));
	btDir2_ = new wxButton (topPanel_, BT_DIR2, L"Dir2", wxDefaultPosition, wxSize(70, -1));
	btConvert_ = new wxButton (topPanel_, BT_CONV, L"Convert");
	ckCString_ = new wxCheckBox (topPanel_, CK_CSTRING, L"Make C-String Array");
	ckSpaces_ = new wxCheckBox (topPanel_, CK_SPACES, L"Add Spaces");
	ckLineBreaks_ = new wxCheckBox (topPanel_, CK_LINEBREAKS, L"Add Line Breaks");
	ckWrap_ = new wxCheckBox (bottomPanel_, CK_WRAP, L"Wrap Lines");
	ckFont_ = new wxCheckBox (bottomPanel_, -1, L"Proportional Font");
	ckBinary_ = new wxCheckBox (bottomPanel_, CK_BINARY, L"Binary Display");
	stFileInfo1_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stFileInfo2_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stFileInfo3_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo1_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo2_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo3_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo4_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo5_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo6_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo7_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo8_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo9_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo10_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo11_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stExifInfo12_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);

	fslist_ = new FileSystemList (topPanel_, LB_FILELIST);
	etPreview_ = new PreviewTextCtrl (bottomPanel_, ET_PREVIEW, fslist_);
	fslist_->setChangeCallback (OnFileListChange, this);
	fslist_->setSelectionCallback (OnSelectionChange, this);
	fslist_->setExecuteCallback (OnExecute, this);
	wxString startdir = wxStandardPaths::Get().GetDocumentsDir();
	fslist_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	stPath_->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	setStartDirectory();
	fslist_->SetDirectory (startdir_.wc_str());
	imgView_ = new ExclusiveImageView (this);
	imgView_->setReadyCallback (new ImageCloseCB(this));

	p1HorSizer2->Add(btHome_, 0, wxALL, 3);
	p1HorSizer2->Add(btDir1_, 0, wxALL, 3);
	p1HorSizer2->Add(btDir2_, 0, wxALL, 3);

	p1VerSizer1->Add(p1HorSizer2, 0);
	p1VerSizer1->Add(0, 20);
	p1VerSizer1->Add(ckCString_, 0, wxALL, 3);
	p1VerSizer1->Add(ckLineBreaks_, 0, wxALL, 3);
	p1VerSizer1->Add(ckSpaces_, 0, wxALL, 3);
	p1VerSizer1->Add(0, 15);
	p1VerSizer1->Add(btConvert_, 0, wxALL, 3);
	
	p1HorSizer1->Add(fslist_, 1, wxTOP | wxLEFT | wxRIGHT | wxEXPAND, 10);
	p1HorSizer1->Add(p1VerSizer1, 0, wxALL, 10);
	
	p1sizer->Add(p1HorSizer1, 1, wxEXPAND);
	p1sizer->Add(stPath_, 0, wxLEFT, 10);
	topPanel_->SetSizer(p1sizer);
	p1sizer->Fit(topPanel_);
	
	p2VerSizer1_->Add(0, 10);
	p2VerSizer1_->Add(ckWrap_, 0, wxALL, 3);
	p2VerSizer1_->Add(ckFont_, 0, wxALL, 3);
	p2VerSizer1_->Add(ckBinary_, 0, wxALL, 3);
	p2VerSizer1_->Add(0, 10);
	p2VerSizer1_->Add(stFileInfo1_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stFileInfo2_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(0, 5);
	p2VerSizer1_->Add(stFileInfo3_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(0, 15);
	p2VerSizer1_->Add(stExifInfo2_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo1_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo12_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo3_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo4_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo5_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo6_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo7_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo8_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo9_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo10_, 0, wxTOP | wxLEFT, 3);
	p2VerSizer1_->Add(stExifInfo11_, 0, wxTOP | wxLEFT, 3);

	p2HorSizer1_->Add(etPreview_, 1, wxALL | wxEXPAND, 10);
	p2HorSizer1_->Add(p2VerSizer1_, 0);
	p2sizer_->Add(p2HorSizer1_, 1, wxEXPAND);
	bottomPanel_->SetSizer(p2sizer_);
	p2sizer_->Fit(bottomPanel_);
	//SetAutoLayout(TRUE);
	
	splitter1_->SplitHorizontally (topPanel_, bottomPanel_);
	splitter1_->SetSashInvisible (false);
	splitter1_->SetSashGravity (0.0);
	splitter1_->SetSashPosition (sash1_);
	topsizer->Add(splitter1_, 1, wxEXPAND);
	
	SetSizer(topsizer);
	topsizer->Fit(this);
	SetMinSize (wxSize(minWindowWidth, minWindowHeight));
	SetSize (wxSize(initWindowWidth, initWindowHeight));
	CenterOnScreen();

    SetStatusText (fslist_->GetVolumeInfo(), 0);
	onFileListChange (fslist_->GetDirectory());
	onSelectionChange (L"");
	
	timer_ = new wxTimer(this);
	timer_->Start (200, false);
	
	Initialize();
}

MyFrame::~MyFrame()
{
	if (timer_) {
		timer_->Stop();
		delete timer_;
	}
	timer_ = NULL;
}


void MyFrame::onFileListChange (const wxString &name)
{
    SetStatusText (fslist_->GetVolumeInfo(), 0);
	wxString dirinfo = fslist_->GetFileCountInfo (false);
	stPath_->SetLabel (name + dirinfo);
	//wxString FileSystemList::GetFileCountInfo (bool fromSelection, wxString *moddate);
}

void MyFrame::onSelectionChange (const wxString &name)
{
	delete textCt_;
	textCt_ = NULL;
	stFileInfo1_->SetLabel (L"");
	stFileInfo2_->SetLabel (L"");
	stFileInfo3_->SetLabel (L"Image:");
	stExifInfo1_->SetLabel (L"");
	stExifInfo2_->SetLabel (L"");
	stExifInfo3_->SetLabel (L"");
	stExifInfo4_->SetLabel (L"");
	stExifInfo5_->SetLabel (L"");
	stExifInfo6_->SetLabel (L"");
	stExifInfo7_->SetLabel (L"");
	stExifInfo8_->SetLabel (L"");
	stExifInfo9_->SetLabel (L"");
	stExifInfo10_->SetLabel (L"");
	stExifInfo11_->SetLabel (L"");
	stExifInfo12_->SetLabel (L"");
	etPreview_->Clear();
	destroyImageView();
	
	if (name == L"..") {
		stFileInfo1_->SetLabel (L"no info");
		return;
	}
	wxString dtinfo;
	wxString info = fslist_->GetFileCountInfo (true, &dtinfo);
	stFileInfo1_->SetLabel (info);
	stFileInfo2_->SetLabel (dtinfo);
	wxString curName (name);
	if (curName.empty()) {
		curName = lastName_;
	}
	wxFileName file (fslist_->GetDirectory(), curName);
	bool binary = ckBinary_->GetValue();
	if (file.FileExists()) {
		lastName_ = curName;
		if (!binary && isImageFile (file)) {
			etPreview_->showScrollbars (false);
			std::wstring info = showImage (file.GetFullPath(), etPreview_);
			stFileInfo3_->SetLabel (info);
			ExifInfo ei (file.GetFullPath().ToStdString());
			ei.readInfo();
			stExifInfo1_->SetLabel (ei.getCModel());
			stExifInfo2_->SetLabel (ei.getDate());
			stExifInfo3_->SetLabel (ei.getExposure());
			stExifInfo4_->SetLabel (ei.getFNumber());
			stExifInfo5_->SetLabel (ei.getSensitivity());
			stExifInfo6_->SetLabel (ei.getFocal());
			stExifInfo7_->SetLabel (ei.getProgram());
			stExifInfo8_->SetLabel (ei.getFlashUsed());
			stExifInfo9_->SetLabel (ei.getMetering());
			stExifInfo10_->SetLabel (ei.getWhiteBalance());
			stExifInfo11_->SetLabel (ei.getBias());
			stExifInfo12_->SetLabel (ei.getLensModel());
		}
		else {
			etPreview_->showScrollbars (true);
			etPreview_->setPaintHandler (NULL);
			etPreview_->setZoomHandler (NULL);
			textCt_ = new TextContent (file.GetFullPath().wc_str(), etPreview_, binary);
			textCt_->writeToEditCtrl();
		}
	}
	else {
		//etPreview_->WriteText (L"[no content]");
	}
}

void MyFrame::onExecute (const wxString &name)
{
	wxFileName file (fslist_->GetDirectory(), name);
	if (file.FileExists()) {
		if (isImageFile (file)) {
			imgView_->ShowImage (file.GetFullPath(), fslist_->GetImageFiles());
		}
		else {
		}
	}
	else {
		//etPreview_->WriteText (L"[no content]");
	}
}

void MyFrame::onPreviewEditMouseDown (wxMouseEvent &evt)
{
	if (!textCt_) {
		return;
	}
	//wxPoint xypos = evt.GetPosition();
	//long contentix;
	//wxTextCtrlHitTestResult res = 
	//etPreview_->HitTest (xypos, &contentix);
	
	//if (contentix > (textCt_->getCurLength() * 2) / 3) {
	//	textCt_->writeToEditCtrl();
	//}
}

void MyFrame::OnBTHome (wxCommandEvent &evt)
{
	fslist_->SetDirectory (startdir_.wc_str());
}

void MyFrame::OnBtDir1 (wxCommandEvent &evt)
{
	EventModifiers ev = getModifiers();
	//bool isCmnd = ev & cmdKey;
	bool isAlt = ev & optionKey;
	if (isAlt) {
		std::wstring dir = fslist_->GetDirectory();
		wxString wdir(dir);
		wxMessageDialog msgdlg (this, wxString("Store ") + wdir + wxString(" ?"), L"", wxOK | wxCANCEL | wxCENTRE);
		if (wxOK == msgdlg.ShowModal()) {
			SetUserIniFileValue (kSettingsSection, sFirstFolderKey, wdir.ToStdString().c_str());
		}
	}
	else {
		std::string initdir;
		if (GetUserIniFileValue (kSettingsSection, sFirstFolderKey, initdir)) {
			wxString wdir(initdir);
			const wchar_t * dir = wdir.wc_str();
			fslist_->SetDirectory (dir);
		}
	}
}

void MyFrame::OnBtDir2 (wxCommandEvent &evt)
{
	EventModifiers ev = getModifiers();
	//bool isCmnd = ev & cmdKey;
	bool isAlt = ev & optionKey;
	if (isAlt) {
		std::wstring dir = fslist_->GetDirectory();
		wxString wdir(dir);
		wxMessageDialog msgdlg (this, wxString("Store ") + wdir + wxString(" ?"), L"", wxOK | wxCANCEL | wxCENTRE);
		if (wxID_OK == msgdlg.ShowModal()) {
			SetUserIniFileValue (kSettingsSection, sSecondFolderKey, wdir.ToStdString().c_str());
		}
	}
	else {
		std::string initdir;
		if (GetUserIniFileValue (kSettingsSection, sSecondFolderKey, initdir)) {
			wxString wdir(initdir);
			const wchar_t * dir = wdir.wc_str();
			fslist_->SetDirectory (dir);
		}
	}
}

void MyFrame::OnBtConvert (wxCommandEvent &evt)
{
	TFilePaths selected = fslist_->GetSelection();
	if (selected.size() < 1) {
		return;
	}
	wxFileName file (selected[0]);
	if (file.FileExists()) {
		if (file.GetExt().Upper() == L"BINHEX") {
			wxString target = file.GetFullPath().substr(0, file.GetFullPath().size() - 7);
			wxFileName targetfs (target);
			if (targetfs.FileExists()) {
				target += L"_1";
			}
			ConvertFromAscii (file.GetFullPath().ToStdString(), target.ToStdString());
		}
		else {
			ConvertToAscii (ckCString_->GetValue(), ckLineBreaks_->GetValue(), ckSpaces_->GetValue(),
							file.GetFullPath().ToStdString());
		}
	}
}

void MyFrame::OnCkCString (wxCommandEvent &evt)
{
}

void MyFrame::OnCkSpaces (wxCommandEvent &evt)
{
}

void MyFrame::OnCkLineBreaks (wxCommandEvent &evt)
{
}

void MyFrame::OnCkWrap (wxCommandEvent &evt)
{
	bool doWrap = ckWrap_->GetValue();
	if (etPreview_->isWrapLines() == doWrap) {
		return;
	}
	etPreview_->setWrapLines (doWrap);
	onSelectionChange (L"");
}

void MyFrame::OnCkBinary (wxCommandEvent &evt)
{
	onSelectionChange (L"");
}

void MyFrame::OnCkFont (wxCommandEvent &evt)
{
	onSelectionChange (L"");
}

void MyFrame::OnKeyDown (wxKeyEvent& evt)
{
	//int code = evt.GetKeyCode();
	//if (code == 27 || (code == 46 && evt.MetaDown())) {
	evt.Skip();
}

void MyFrame::OnKeyUp (wxKeyEvent& evt)
{
	evt.Skip();
}

void MyFrame::OnQuit(wxCommandEvent& WXUNUSED(event))
{
	SaveGeo();
    // true is to force the frame to close
    Close(true);
}

void MyFrame::OnTimer (wxTimerEvent&)
{
	EventModifiers em = getModifiers();
	bool isCmnd = em & cmdKey;
	bool isAlt = em & optionKey;

	if (isAlt && isCmnd) {
		TFilePaths selected = fslist_->GetSelection();
		if (selected.size() < 1) {
			return;
		}
		wxFileName file (selected[0]);
		ChooseActionDlg dlg(this);
		dlg.ShowModal();
		int action = dlg.getAction();
		if (action == 'W') {
			wxMessageBox ("Action is Edit wave","",wxOK|wxCENTRE,this);
		}
		else if (action == 'B') {
			wxMessageBox ("Action is B","",wxOK|wxCENTRE,this);
		}
		else if (action == 'D') {
			wxMessageBox ("Action is D","",wxOK|wxCENTRE,this);
		}
		else if (action == 'E') {
			wxMessageBox ("Action is E","",wxOK|wxCENTRE,this);
		}
		else if (action == 'F') {
			wxMessageBox ("Action is F","",wxOK|wxCENTRE,this);
		}
		else if (action == 'I') {
			wxMessageBox (GetDirectoryInfo (file).c_str(),"",wxOK|wxCENTRE,this);
		}
		else if (action == 'N') {
			wxMessageBox ("Action is N","",wxOK|wxCENTRE,this);
		}
		else if (action == 'R') {
			wxMessageBox ("Action is R","",wxOK|wxCENTRE,this);
		}
		else if (action == 'X') {
			wxMessageBox ("Action is X","",wxOK|wxCENTRE,this);
		}
		else if (action == 'Z') {
			wxMessageBox ("Action is Z","",wxOK|wxCENTRE,this);
		}
		else if (action == 'H') {
			ActionHelpDlg dlg (this);
			dlg.ShowModal();
		}
	}
}

void MyFrame::onImageClosing (const std::wstring &name)
{
	fslist_->SetSelectedFile (name);
}

void MyFrame::OnAbout(wxCommandEvent& WXUNUSED(event))
{
    wxMessageBox(wxString::Format
                 (
				  "Welcome to %s!\n"
				  "\n"
				  "This is the my wxWidgets sample\n"
				  "running under %s.",
				  wxVERSION_STRING,
				  wxGetOsDescription()
				  ),
                 "About wxWidgets sample",
                 wxOK | wxICON_INFORMATION,
                 this);
}

void MyFrame::Initialize()
{
	int w, h, x, y, s;
	bool success = GetUserIniFileIntValue (kSettingsSection, sMainWindowWidthKey, w);
	success &= GetUserIniFileIntValue (kSettingsSection, sMainWindowHeightKey, h);
	success &= GetUserIniFileIntValue (kSettingsSection, sMainWindowXPosKey, x);
	success &= GetUserIniFileIntValue (kSettingsSection, sMainWindowYPosKey, y);
	success &= GetUserIniFileIntValue (kSettingsSection, sMainWindowSashPosKey, s);
	if (success) {
		SetSize (x, y, w, h, wxSIZE_USE_EXISTING);
		splitter1_->SetSashPosition (s);
	}
	std::string initdir;
	if (GetUserIniFileValue (kSettingsSection, sDefFolderKey, initdir)) {
		wxString wdir(initdir);
		const wchar_t * dir = wdir.wc_str();
		fslist_->SetDirectory (dir);
	}
}

void MyFrame::SaveGeo()
{
	wxRect rect = GetRect();
	SetUserIniFileIntValue (kSettingsSection, sMainWindowWidthKey, rect.width);
	SetUserIniFileIntValue (kSettingsSection, sMainWindowHeightKey, rect.height);
	SetUserIniFileIntValue (kSettingsSection, sMainWindowXPosKey, rect.x);
	SetUserIniFileIntValue (kSettingsSection, sMainWindowYPosKey, rect.y);
	SetUserIniFileIntValue (kSettingsSection, sMainWindowSashPosKey, splitter1_->GetSashPosition());
	wxString dir (fslist_->GetDirectory());
	SetUserIniFileValue (kSettingsSection, sDefFolderKey, dir.ToStdString().c_str());
	
}


//========================================================================
/*
 \history
 
 WGo-2016-05-17: Created
 WGo-2016-09-02: convert binhex and back feature works
 
 */

