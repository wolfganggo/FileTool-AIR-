//-----------------------------------------------------------------------------
/*!
**	\file	ChooseActionDialog.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WG_CHOOSEACTIONDIALOG_H_
#define WG_CHOOSEACTIONDIALOG_H_

//-----------------------------------------------------------------------------

// Project headers
//#include "FileSystemList.h"

#include "wx/wx.h"

// std headers
//#include <string>


//-----------------------------------------------------------------------------

class ChooseActionDlg : public wxDialog {
	
public:
	ChooseActionDlg (wxWindow *parent);
	~ChooseActionDlg();
	
	int getAction() const { return action_; }
	
	void setAction (int a) { action_ = a; }
	
private:
	
	int action_;
	wxTextCtrl    * etEdit;
	
	void OnKeyDown (wxKeyEvent&);
	void OnInitDialog (wxInitDialogEvent & evt);

	DECLARE_EVENT_TABLE();
};

class ActionHelpDlg : public wxDialog {
	
public:
	ActionHelpDlg (wxWindow *parent);
	//~ActionHelpDlg();
	
private:
	
	//void OnInitDialog (wxInitDialogEvent & evt);
	
	//DECLARE_EVENT_TABLE();
};

//-----------------------------------------------------------------------------

#endif // WG_CHOOSEACTIONDIALOG_H_

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-09-08: created
 
 */
