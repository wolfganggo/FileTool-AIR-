//-----------------------------------------------------------------------------
/*!
**	\file	ImageView.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WV_IMAGEVIEW_H_
#define WV_IMAGEVIEW_H_

//-----------------------------------------------------------------------------

// Project headers
#include "FileSystemList.h"

#include "wx/wx.h"

// std headers
//#include <string>

class PreviewTextCtrl;
class wxImage;
class ImageCtrl;

//-----------------------------------------------------------------------------

class ImageCallback
{
public:
	virtual ~ImageCallback() {}
	virtual void operator()(const std::wstring &s) = 0;
};

//-----------------------------------------------------------------------------

class ImageView {
	
public:
	
	ImageView (wxImage &img, PreviewTextCtrl *ctrl);
	~ImageView();
	
	void onPaint();
	bool onZoom (int zoom);
	void onPan (int panx, int pany);

private:
	
	wxImage        image_;
	bool           canZoomBigger_;
	//bool           zoomEnd_;
	float          zoom_;
	int            panx_;
	int            pany_;
	bool           defZoom_;
	
	//wxBitmap                 bitmap_;
	//PreviewTextCtrl        & previewctrl_;

public:
	
	static ImageView * ivobj_;
	
	static void PaintHandler();
	
	static bool ZoomHandler (int zoom, int panx, int pany);
	
};

std::wstring showImage (const wxString &imgPath, PreviewTextCtrl *ctrl);

void destroyImageView();

//-----------------------------------------------------------------------------

class ExclusiveImageView : public wxFrame {
	
public:
	ExclusiveImageView (wxWindow *parent);
	~ExclusiveImageView();
	
	void ShowImage (const wxString &imgPath, const TFileNames &files);
	
	void draw();
	void close();
	bool nextImage (bool up);
	void rotate();
	void zoom (int step);
	void pan (int panx, int pany);
	
	bool isDefZoom() { return defZoom_ || canZoomBigger_; }
	
	wxString getImageInfo();
	
	void setReadyCallback (ImageCallback *cb) { readyCB_ = cb; }

private:
	wxImage      * image_;
	ImageCtrl    * child_;
	TFileNames     files_;
	wxString       file_;
	wxString       folder_;
	wxString       name_;
	int            filepos_;
	int            rotation_;
	bool           defZoom_;
	bool           canZoomBigger_; // image is smaller than control, 1 zoom step allowed, no pan
	bool           zoomEnd_;
	float          zoom_;
	float          zoommin_;
	int            panx_;
	int            pany_;
	int            zoomstep_;
	ImageCallback * readyCB_;
	
	//void OnPaintEvt (wxPaintEvent&);
	//void OnKeyDown (wxKeyEvent&);

	wxDECLARE_EVENT_TABLE();
};

//-----------------------------------------------------------------------------

#endif // WV_IMAGEVIEW_H_

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-06-07: created
 
 */
