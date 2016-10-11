//-----------------------------------------------------------------------------
/*!
**	\file	ChooseActionDlg.cpp
**
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "ChooseActionDialog.h"

// Project headers
#include "Utilities.h"


#include "wx/wx.h"
#include "wx/filesys.h"

// std headers
#include <fstream>
#include <string>
#include <sstream>
#include <stdlib.h>

//------------------------------------------------------------------------------

using namespace wgfc;

namespace {

	class TextControlWithKey : public wxTextCtrl
	{
	public:
		TextControlWithKey (ChooseActionDlg *parent, wxWindowID id, const wxString& value,
							const wxPoint& pos, const wxSize& size, long style = 0);
		
	private:
		ChooseActionDlg * parentDlg_;
		void              OnKeyDown (wxKeyEvent& evt);
		
		DECLARE_EVENT_TABLE()
	};
	
	
	BEGIN_EVENT_TABLE(TextControlWithKey, wxTextCtrl)
	EVT_KEY_DOWN(TextControlWithKey::OnKeyDown)
	END_EVENT_TABLE()
	
	TextControlWithKey::TextControlWithKey (ChooseActionDlg *parent, wxWindowID id, const wxString& value,
											const wxPoint& pos, const wxSize& size, long style)
	: wxTextCtrl(parent,id,value,pos,size,style), parentDlg_(parent)
	{
	}
	
	void TextControlWithKey::OnKeyDown (wxKeyEvent& evt)
	{
		int code = evt.GetKeyCode();
		if (code == 87 && evt.MetaDown()) {
			// do not let pass Cmd+W
			return;
		}
		parentDlg_->setAction (code);
		parentDlg_->EndModal (wxID_OK);
	}
	
	const char * helpCaption_ = "WGFileConverter Help";
	
	const char * helpText_ =
	"- The button Convert creates a text file where every byte is converted to a two-digit hex value.\n\
   When the file has the extension '.binhex' then a binary file is created from hex values.";
	
}

//------------------------------------------------------------------------------


BEGIN_EVENT_TABLE(ChooseActionDlg, wxDialog)
EVT_INIT_DIALOG (ChooseActionDlg::OnInitDialog)
//EVT_PAINT(ExclusiveImageView::OnPaintEvt)
//EVT_KEY_DOWN(ChooseActionDlg::OnKeyDown)
//EVT_CLOSE(ChooseActionDlg::OnClose)
END_EVENT_TABLE()

ChooseActionDlg::ChooseActionDlg (wxWindow *parent)
: wxDialog (parent, wxID_ANY, L"Choose Action", wxDefaultPosition, wxDefaultSize, wxCAPTION), action_(0)
{
	wxStaticText *text1 = new wxStaticText(this, wxID_ANY,
										   L"Press one of these keys for action or any other key to close");
	etEdit = new TextControlWithKey(this, wxID_ANY, L"Available Actions:", wxDefaultPosition, wxSize(280, -1));
	wxStaticText *stAction1 = new wxStaticText(this, wxID_ANY, L"B        Edit file binary");
	wxStaticText *stAction2 = new wxStaticText(this, wxID_ANY, L"W       Edit wave file");
	wxStaticText *stAction3 = new wxStaticText(this, wxID_ANY, L"R        Rename file");
	wxStaticText *stAction4 = new wxStaticText(this, wxID_ANY, L"E        Edit file extension");
	wxStaticText *stAction5 = new wxStaticText(this, wxID_ANY, L"D        Duplicate file");
	wxStaticText *stAction6 = new wxStaticText(this, wxID_ANY, L"X        Delete file");
	wxStaticText *stAction7 = new wxStaticText(this, wxID_ANY, L"F        New folder");
	wxStaticText *stAction8 = new wxStaticText(this, wxID_ANY, L"N        New text file");
	wxStaticText *stAction9 = new wxStaticText(this, wxID_ANY, L"I         Get info for file or directory");
	wxStaticText *stAction10 = new wxStaticText(this, wxID_ANY, L"Z        Remove files \".DS_Store\" recursive");
	wxStaticText *stAction11 = new wxStaticText(this, wxID_ANY, L"H        Show help");

	wxBoxSizer *sizerTop = new wxBoxSizer(wxVERTICAL);
	//wxBoxSizer* horSizer = new wxBoxSizer(wxHORIZONTAL );
	//horSizer->Add (background, 1, 0);
	//sizerTop->Add( horSizer, 0, wxEXPAND);
	sizerTop->Add (0, 10);
	sizerTop->Add (text1, 0, wxLEFT | wxRIGHT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (etEdit, 0, wxLEFT, 20);
	sizerTop->Add (0, 10);
	sizerTop->Add (stAction1, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction2, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction3, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction4, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction5, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction6, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction7, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction8, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction9, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction10, 0, wxLEFT, 20);
	sizerTop->Add (0, 3);
	sizerTop->Add (stAction11, 0, wxLEFT, 20);
	sizerTop->Add( 0, 40);
	//wxSizer* butSizer = CreateButtonSizer (wxOK);
	
	wxSizer* butSizer = CreateButtonSizer (wxCANCEL);
	wxASSERT(butSizer);
	sizerTop->Add(butSizer, 0, wxALIGN_RIGHT);
	sizerTop->Add( 0, 10);
	
	//wxWindow *okBtn = FindWindow (wxID_OK);
	wxWindow *cancelBtn = FindWindow (wxID_CANCEL);
	if (cancelBtn != NULL) {
		cancelBtn->SetLabel (L"Close");
	}
	SetSizer(sizerTop);
	//sizerTop->SetSizeHints(this); // calls Fit()
	//sizerTop->SetMinSize (wxSize(250, 150));
	//SetSize( 250, 250);
	sizerTop->Fit (this);
	CenterOnScreen();
	etEdit->SetFocus();
}

ChooseActionDlg::~ChooseActionDlg()
{
}

void ChooseActionDlg::OnInitDialog (wxInitDialogEvent & evt)
{
	//SetDefaultItem (etEdit);
	evt.Skip();
}

void ChooseActionDlg::OnKeyDown (wxKeyEvent &evt)
{
	action_ = evt.GetKeyCode();
	//if (code == 27 || code == 32) {
	//	parentWin_->close();
	//}
	//EndModal(wxID_OK);
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

ActionHelpDlg::ActionHelpDlg (wxWindow *parent)
: wxDialog (parent, wxID_ANY, "")
{
	wxStaticText *st1 = new wxStaticText(this, wxID_ANY, helpCaption_);
	wxStaticText *st2 = new wxStaticText(this, wxID_ANY, helpText_);
	st2->SetWindowVariant (wxWINDOW_VARIANT_SMALL);
	wxBoxSizer *sizerTop = new wxBoxSizer(wxVERTICAL);
	sizerTop->Add (0, 10);
	sizerTop->Add (st1, 0, wxLEFT | wxRIGHT, 20);
	sizerTop->Add (0, 10);
	sizerTop->Add (st2, 0, wxLEFT | wxRIGHT, 20);
	sizerTop->Add (0, 40);
	wxSizer* butSizer = CreateButtonSizer (wxOK);
	wxASSERT(butSizer);
	sizerTop->Add(butSizer, 0, wxALIGN_RIGHT);
	sizerTop->Add (0, 10);
	
	SetSizer(sizerTop);
	sizerTop->Fit (this);
	//SetSize (500, 400);
	CenterOnScreen();
}

//------------------------------------------------------------------------------

/*
 \history
 WGo-2016-09-08: created
 
 */
