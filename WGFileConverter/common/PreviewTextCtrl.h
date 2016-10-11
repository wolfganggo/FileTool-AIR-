//-----------------------------------------------------------------------------
/*!
 **	\file	Common/PreviewTextCtrl.h
 **
 **	\author	Wolfgang Goldbach
 */
//-----------------------------------------------------------------------------

#ifndef PREVIEWTEXTCONTROL_H_
#define PREVIEWTEXTCONTROL_H_

#include "wx/wx.h"
//#include "wx/control.h"
#include "wx/scrolbar.h"


#include <vector>

//-----------------------------------------------------------------------------

class FileSystemList;


typedef std::vector<int>  TPositions;



typedef void (*PaintHandlerFn) ();
typedef bool (*ZoomHandlerFn) (int, int, int);
typedef bool (*LoadTextCbFn) ();


class PreviewTextCtrl : public wxControl
{
public:
    PreviewTextCtrl (wxWindow *parent,
					 wxWindowID id,
					 FileSystemList *fsl
					 );
	
	void WriteText (const wxString &text);
	
	bool isWrapLines() { return wrap_; }
	
	void setWrapLines (bool wrap);
	
	void Clear();
	
	void setFixedFont() { fixedFont_ = true; }
	void setPropFont() { fixedFont_ = false; }
	
	void setPaintHandler (PaintHandlerFn cb);
	void setZoomHandler (ZoomHandlerFn cb);
	void setLoadTextHandler (LoadTextCbFn cb) { loadTextCB_ = cb; }
	
	void showScrollbars (bool show);

private:
	
	wxString       text_;
	bool           wrap_;
	bool           fixedFont_;
	bool           textEnd_;
	wxScrollBar  * horScrlbr_;
	wxScrollBar  * verScrlbr_;
	bool           enableHorScr_;
	bool           enableVerScr_;
	int            curTextPosRight_;
	int            curTextPosLeft_;
	int            curLineTop_;
	int            curLineBottom_;
	int            curLineCount_;
	int            totalLineCount_;
	bool           hasTotalLineCount_;
	int            curCharPerLineCount_;
	TPositions     lastChars_;
	bool           dimensionValid_;
	int            hpagestep_;
	int            vpagestep_;
	int            hthumbsize_;
	int            vthumbsize_;
	int            maxlinelen_;
	bool           newHorValue_;
	bool           newVerValue_;
	
	int            imageZoom_;
	bool           maxZoom_;
	
	PaintHandlerFn paintHandlerCB_;
	ZoomHandlerFn  zoomHandlerCB_;
	LoadTextCbFn   loadTextCB_;
	FileSystemList * fileList_;

	void OnPaintEvt (wxPaintEvent&);
	void OnSizeEvt (wxSizeEvent&);
	void OnKeyDown (wxKeyEvent&);

	void OnScrollHorEvt (wxScrollEvent&);
	void OnScrollVerEvt (wxScrollEvent&);
	
	//void OnScrollHorTop (wxScrollEvent&);
	//void OnScrollHorBottom (wxScrollEvent&);
	void OnScrollHorPageUp (wxScrollEvent&);
	void OnScrollHorPageDown (wxScrollEvent&);
	void OnScrollHorThumb (wxScrollEvent&);
	void OnScrollHorRelease (wxScrollEvent&);

	//void OnScrollVerTop (wxScrollEvent&);
	//void OnScrollVerBottom (wxScrollEvent&);
	void OnScrollVerPageUp (wxScrollEvent&);
	void OnScrollVerPageDown (wxScrollEvent&);
	void OnScrollVerThumb (wxScrollEvent&);
	void OnScrollVerRelease (wxScrollEvent&);
	
	void setScrolbarValues (int linecount, wxString::size_type textindex, int maxlen);
	void doVerticalPageUp (bool fromKey = false);
	void doVerticalPageDown (bool fromKey = false);

	
    wxDECLARE_EVENT_TABLE();
};


#endif // PREVIEWTEXTCONTROL_H_

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-06-17: created
 
 */
