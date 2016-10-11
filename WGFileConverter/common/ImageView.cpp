//-----------------------------------------------------------------------------
/*!
**	\file	ImageView.cpp
**
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "ImageView.h"

// Project headers
#include "PreviewTextCtrl.h"
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

ImageView * ImageView::ivobj_ = NULL;

namespace {

	//wxBitmap            bitmap_;
	PreviewTextCtrl   * previewctrl_;

	//const float zoomstep_ = 1.3;
	
	int findPosition (const wxString &imgPath, const TFileNames &files)
	{
		wxFileName fs (imgPath);
		wxString name = fs.GetFullName();
		for (unsigned int ix = 0; ix < files.size(); ++ix) {
			if (files[ix] == name) {
				return ix;
			}
		}
		return -1;
	}
	
}

//------------------------------------------------------------------------------

class ImageCtrl : public wxControl {
public:
	
	ImageCtrl (ExclusiveImageView *parent);
	
private:
	ExclusiveImageView      * parentWin_;
	
	void OnPaintEvt (wxPaintEvent&);
	void OnKeyDown (wxKeyEvent&);
	
	wxDECLARE_EVENT_TABLE();
};

//------------------------------------------------------------------------------

ImageView::ImageView (wxImage &img, PreviewTextCtrl *ctrl)
: image_ (img)
, canZoomBigger_(false)
//, zoomEnd_(false)
, zoom_(1.0)
, panx_(0)
, pany_(0)
, defZoom_(true)
{
	previewctrl_ = ctrl;
	//bitmap_ = wxBitmap (img);
}

ImageView::~ImageView()
{
	image_.Destroy();
}

void ImageView::onPaint()
{
	wxWindowDC wxdc(previewctrl_);
	int pvw = previewctrl_->GetRect().width;
	int pvh = previewctrl_->GetRect().height;
	int imgw = image_.GetWidth();
	int imgh = image_.GetHeight();
	wxBitmap bitmap;
	int offsx = 0;
	int offsy = 0;
	if (imgw > pvw || imgh > pvh) {
		canZoomBigger_ = false;
		float zoomx = (float)pvw / (float)imgw;
		float zoomy = (float)pvh / (float)imgh;
		float zoommin = zoomx < zoomy ? zoomx : zoomy;

		if (defZoom_ || zoom_ < zoommin) {
			zoom_ = zoommin;
		}
		wxImage sc = image_.Scale (imgw * zoom_, imgh * zoom_, wxIMAGE_QUALITY_HIGH);
		bitmap = wxBitmap (sc);
		if (sc.GetWidth() < pvw) {
			offsx = (pvw - sc.GetWidth()) / 2;
		}
		if (sc.GetHeight() < pvh) {
			offsy = (pvh - sc.GetHeight()) / 2;
		}
		sc.Destroy();
	}
	else {
		if (defZoom_) {
			zoom_ = 1.0;
		}
		if (imgw < pvw && imgh < pvh) {
			canZoomBigger_ = true;
		}
		if (zoom_ == 1.0) {
			bitmap = wxBitmap (image_);
		}
		else {
			wxImage sc = image_.Scale (imgw * zoom_, imgh * zoom_, wxIMAGE_QUALITY_HIGH);
			bitmap = wxBitmap (sc);
			if (sc.GetWidth() < pvw) {
				offsx = (pvw - sc.GetWidth()) / 2;
			}
			if (sc.GetHeight() < pvh) {
				offsy = (pvh - sc.GetHeight()) / 2;
			}
			sc.Destroy();
		}
	}
	wxdc.DrawBitmap (bitmap, offsx, offsy, false); // bool transparent
}

bool ImageView::onZoom (int zoomstep)
{
	int pvw = previewctrl_->GetRect().width;
	int pvh = previewctrl_->GetRect().height;
	int imgw = image_.GetWidth();
	int imgh = image_.GetHeight();
	defZoom_ = false;

	if (zoomstep == 0) {
		defZoom_ = true;
	}
	else if (canZoomBigger_) {
		if (zoom_ > 1.0) {
			return false;
		}
		float zoomx = (float)pvw / (float)imgw;
		float zoomy = (float)pvh / (float)imgh;
		zoom_ = zoomx < zoomy ? zoomx : zoomy;
		return false;
	}
	else {
		if (zoom_ >= 1.0) {
			return false;
		}
		zoom_ *= std::pow (1.3, zoomstep);
		if (zoom_ > 1.0) {
			zoom_ = 1.0;
			return false;
		}
	}

	return true;
}

void ImageView::onPan (int panx, int pany)
{
}


void ImageView::PaintHandler()
{
	if (ImageView::ivobj_ == NULL) {
		return;
	}
	ImageView::ivobj_->onPaint();
}

bool ImageView::ZoomHandler (int zoomstep, int panx, int pany)
{
	if (ImageView::ivobj_ == NULL) {
		return false;
	}
	if (panx == 0 && pany == 0) {
		return ImageView::ivobj_->onZoom (zoomstep);
	}
	else {
		ImageView::ivobj_->onPan (panx, pany);
	}
	return true;
	//zoom_ *= zoomrel;
	//panx_ += panx;
	//pany_ += pany;
}

//------------------------------------------------------------------------------

std::wstring showImage (const wxString &imgPath, PreviewTextCtrl *ctrl)
{
	ctrl->setPaintHandler (ImageView::PaintHandler);
	ctrl->setZoomHandler (ImageView::ZoomHandler);
	
	wxImage image; // = bitmap.ConvertToImage();
    if ( image.LoadFile (imgPath) ) {
		ImageView::ivobj_ = new ImageView (image, ctrl);
	}
	int w = image.GetWidth();
	int h = image.GetHeight();
	wxString ws;
	ws << L"Image: " << w << L" x " << h;
	return ws.wc_str();

}


void destroyImageView()
{
	if (ImageView::ivobj_) {
		delete ImageView::ivobj_;
		ImageView::ivobj_ = NULL;
	}
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

wxBEGIN_EVENT_TABLE(ExclusiveImageView, wxFrame)
//EVT_PAINT(ExclusiveImageView::OnPaintEvt)   // not received
//EVT_KEY_DOWN(ExclusiveImageView::OnKeyDown) // not received
wxEND_EVENT_TABLE()

ExclusiveImageView::ExclusiveImageView (wxWindow *parent)
: wxFrame (parent, wxID_ANY, L"")
, image_(NULL)
, filepos_(-1)
, rotation_(0)
, defZoom_(true)
, canZoomBigger_(false)
, zoomEnd_(false)
, zoom_(0.0)
, zoommin_(0.0)
, panx_(0)
, pany_(0)
, zoomstep_(0)
, readyCB_(NULL)
{
	child_ = new ImageCtrl (this);
	SetSize (wxSize(500, 500));
}

ExclusiveImageView::~ExclusiveImageView()
{
}

void ExclusiveImageView::ShowImage (const wxString &imgPath, const TFileNames &files)
{
	rotation_ = 0;
	defZoom_ = true;
	canZoomBigger_ = false;
	zoomEnd_ = false;
	zoom_ = 0.0;
	zoommin_ = 0.1;
	panx_ = 0;
	pany_ = 0;
	zoomstep_ = 0;
	files_ = files;
	image_ = new wxImage;
	file_ = imgPath;
	wxFileName fs (imgPath);
	folder_ = fs.GetPath();
	name_ = fs.GetFullName();
	filepos_ = findPosition (imgPath, files_);

    if (image_->LoadFile (imgPath) ) {
		Show (true);
		ShowFullScreen (true);
	}
}

void ExclusiveImageView::draw()
{
	//if (!IsFullScreen()) {
	wxWindowDC wxdc(child_);
	int pvw = child_->GetRect().width;
	int pvh = child_->GetRect().height;
	int imgw = image_->GetWidth();
	int imgh = image_->GetHeight();
	wxBitmap bitmap;
	int offsx = panx_;
	int offsy = pany_;
	bool orientationfalse = rotation_ == 1 || rotation_ == 3;

	if (imgw > pvw || imgh > pvh) {
		canZoomBigger_ = false;
		float zoomx = (float)pvw / (float)imgw;
		float zoomy = (float)pvh / (float)imgh;
		if (orientationfalse) {
			zoomx = (float)pvw / (float)imgh;
			zoomy = (float)pvh / (float)imgw;
		}
		zoommin_ = zoomx < zoomy ? zoomx : zoomy;
		if (defZoom_ || zoom_ < zoommin_) {
			zoom_ = zoommin_;
		}
		
		wxImage sc = image_->Scale (imgw * zoom_, imgh * zoom_, wxIMAGE_QUALITY_HIGH);
		int imgwidth = orientationfalse ? sc.GetHeight() : sc.GetWidth();
		int imgheight = orientationfalse ? sc.GetWidth() : sc.GetHeight();
		if (rotation_  == 1) {
			bitmap = wxBitmap (sc.Rotate90(true));
		}
		else if (rotation_  == 2) {
			bitmap = wxBitmap (sc.Rotate180());
		}
		else if (rotation_  == 3) {
			bitmap = wxBitmap (sc.Rotate90(false));
		}
		else {
			bitmap = wxBitmap (sc);
		}
		
		if (imgwidth < pvw) {
			offsx = (pvw - imgwidth) / 2;
		}
		if (imgheight < pvh) {
			offsy = (pvh - imgheight) / 2;
		}
		sc.Destroy();
		panx_ = offsx;
		pany_ = offsy;
	}
	else {
		offsx = 0;
		offsy = 0;
		if (defZoom_) {
			zoom_ = 1.0;
		}
		if (imgw < pvw && imgh < pvh) {
			canZoomBigger_ = true;
		}
		if (zoom_ == 1.0) {
			if (rotation_  == 1) {
				bitmap = wxBitmap (image_->Rotate90(true));
			}
			else if (rotation_  == 2) {
				bitmap = wxBitmap (image_->Rotate180());
			}
			else if (rotation_  == 3) {
				bitmap = wxBitmap (image_->Rotate90(false));
			}
			else {
				bitmap = wxBitmap (*image_);
			}
		}
		else {
			wxImage sc = image_->Scale (imgw * zoom_, imgh * zoom_, wxIMAGE_QUALITY_HIGH);
			int imgwidth = orientationfalse ? sc.GetHeight() : sc.GetWidth();
			int imgheight = orientationfalse ? sc.GetWidth() : sc.GetHeight();
			if (rotation_  == 1) {
				bitmap = wxBitmap (sc.Rotate90(true));
			}
			else if (rotation_  == 2) {
				bitmap = wxBitmap (sc.Rotate180());
			}
			else if (rotation_  == 3) {
				bitmap = wxBitmap (sc.Rotate90(false));
			}
			else {
				bitmap = wxBitmap (sc);
			}

			if (imgwidth < pvw) {
				offsx = (pvw - imgwidth) / 2;
			}
			if (imgheight < pvh) {
				offsy = (pvh - imgheight) / 2;
			}
			sc.Destroy();
		}
	}
	
	wxdc.DrawBitmap (bitmap, offsx, offsy, false); // bool transparent

	if (pvw < 600) { // forget all if it was not full screen
		rotation_ = 0;
		defZoom_ = true;
		canZoomBigger_ = false;
		zoomEnd_ = false;
		zoom_ = 0.0;
		zoommin_ = 0.1;
		panx_ = 0;
		pany_ = 0;
		zoomstep_ = 0;
	}
}

void ExclusiveImageView::close()
{
	Show (false);
	image_->Destroy();
	delete image_;
	image_ = NULL;
	if (readyCB_) {
		(*readyCB_)(name_.wc_str());
	}
}

bool ExclusiveImageView::nextImage (bool up)
{
	if (up) {
		if (filepos_ + 1 >= files_.size()) {
			return false;
		}
		++filepos_;
	}
	else {
		if (filepos_ <= 0) {
			return false;
		}
		--filepos_;
	}
	rotation_ = 0;
	defZoom_ = true;
	canZoomBigger_ = false;
	zoomEnd_ = false;
	zoom_ = 0.0;
	panx_ = 0;
	pany_ = 0;
	zoomstep_ = 0;
	name_ = files_[filepos_];
	wxFileName fs (folder_, name_);
	file_ = fs.GetFullPath();
    if (image_->LoadFile (fs.GetFullPath()) ) {
		Refresh();
	}
	return true;
}

void ExclusiveImageView::rotate()
{
	if (++rotation_ > 3) {
		rotation_ = 0;
	}
	Refresh();
}

void ExclusiveImageView::zoom (int zoomrel)
{
	int pvw = child_->GetRect().width;
	int pvh = child_->GetRect().height;
	int imgw = image_->GetWidth();
	int imgh = image_->GetHeight();
	int oldw_z = imgw * zoom_;
	int oldh_z = imgh * zoom_;
	defZoom_ = false;
	//zoomEnd_ = false;
	
	if (zoomrel == 0) {
		panx_ = 0;
		pany_ = 0;
		defZoom_ = true;
		zoomEnd_ = false;
	}
	else if (canZoomBigger_) {
		if (zoom_ >= 1.0) {
			zoomEnd_ = true;
		}
		if (zoomrel == 1) {
			float zoomx = (float)pvw / (float)imgw;
			float zoomy = (float)pvh / (float)imgh;
			if (rotation_ == 1 || rotation_ == 3) {
				zoomx = (float)pvw / (float)imgh;
				zoomy = (float)pvh / (float)imgw;
			}
			zoom_ = zoomx < zoomy ? zoomx : zoomy;
		}
		else { // -1
			defZoom_ = true;
		}
	}
	else {
		if (zoomrel == 1) {
			if (!zoomEnd_) {
				++zoomstep_;
			}
		}
		else { // -1
			zoomEnd_ = false;
			if (zoomstep_ > 0) {
				--zoomstep_;
			}
		}
		if (zoomstep_ == 0) {
			panx_ = 0;
			pany_ = 0;
			defZoom_ = true;
		}
		else {
			float oldzoom = zoom_;
			zoom_ = zoommin_ * std::pow (1.3, zoomstep_);
			if (zoom_ >= 1.0) {
				zoom_ = 1.0;
				zoomEnd_ = true;
			}
			
			// handle pan
			float zoomdiv = zoom_ / oldzoom;
			panx_ = panx_ * zoomdiv - ((imgw * zoom_ - oldw_z) / 2);
			pany_ = pany_ * zoomdiv - ((imgh * zoom_ - oldh_z) / 2);
			int imgzw = image_->GetWidth() * zoom_;
			int imgzh = image_->GetHeight() * zoom_;
			int panmaxx = pvw - imgzw; // negative
			int panmaxy = pvh - imgzh;
			if (panx_ < panmaxx) {
				panx_ = panmaxx;
			}
			if (pany_ < panmaxy) {
				pany_ = panmaxy;
			}
			if (panx_ > 0) {
				panx_ = 0;
			}
			if (pany_ > 0) {
				pany_ = 0;
			}
		}
	}
	Refresh();
}

void ExclusiveImageView::pan (int panx, int pany)
{
	if (defZoom_ || canZoomBigger_) {
		return;
	}
	int pvw = child_->GetRect().width;
	int pvh = child_->GetRect().height;
	int imgzw = image_->GetWidth() * zoom_;
	int imgzh = image_->GetHeight() * zoom_;
	int panmaxx = pvw - imgzw; // negative
	int panmaxy = pvh - imgzh;
	int panstepx = pvw / 10;
	int panstepy = pvh / 10;
	if (panx > 0) {
		panx_ -= panstepx;
		if (panx_ < panmaxx) {
			panx_ = panmaxx;
		}
	}
	else if (panx < 0) {
		panx_ += panstepx;
		if (panx_ > 0) {
			panx_ = 0;
		}
	}
	if (pany > 0) {
		pany_ += panstepy;
		if (pany_ > 0) {
			pany_ = 0;
		}
	}
	else if (pany < 0) {
		pany_ -= panstepy;
		if (pany_ < panmaxy) {
			pany_ = panmaxy;
		}
	}
	Refresh();
}

wxString ExclusiveImageView::getImageInfo()
{
	wxString info;
	info << L"Image " << filepos_ + 1 << L" of " << files_.size() << L"\n\n";
	info << L"File: " << name_ << L"\n";
	info << L"Size: " << image_->GetWidth() << L" x " << image_->GetHeight() << L"\n\n";
	ExifInfo ei (file_.ToStdString());
	ei.readInfo();
	std::string s = ei.getInfoString();
	//wxString exstr = ei.getInfoString();
	info += s;
	return info;
}


//------------------------------------------------------------------------------

wxBEGIN_EVENT_TABLE(ImageCtrl, wxControl)
EVT_PAINT(ImageCtrl::OnPaintEvt)
EVT_KEY_DOWN(ImageCtrl::OnKeyDown)
wxEND_EVENT_TABLE()

ImageCtrl::ImageCtrl (ExclusiveImageView *parent)
: wxControl(parent, -1)
, parentWin_(parent)
{
}
	
void ImageCtrl::OnPaintEvt (wxPaintEvent&)
{
	parentWin_->draw();
}

void ImageCtrl::OnKeyDown (wxKeyEvent &evt)
{
	int code = evt.GetKeyCode();
	if (code == 27 || code == 32) {
		parentWin_->close();
	}
	else if (code == 'R') {
		parentWin_->rotate();
	}
	else if (code == 'Z' || code == '+') {
		parentWin_->zoom(1);
	}
	else if (code == 'B' || code == '-') {
		parentWin_->zoom(-1);
	}
	else if (code == '0') {
		parentWin_->zoom(0);
	}
	else if (code == WXK_LEFT) {
		if (parentWin_->isDefZoom()) {
			parentWin_->nextImage (false);
		}
		else {
			parentWin_->pan(-1, 0);
		}
	}
	else if (code == WXK_RIGHT) {
		if (parentWin_->isDefZoom()) {
			parentWin_->nextImage (true);
		}
		else {
			parentWin_->pan(1, 0);
		}
	}
	else if (code == WXK_UP) {
		parentWin_->pan(0, 1);
	}
	else if (code == WXK_DOWN) {
		parentWin_->pan(0, -1);
	}
	else if (code == 'I') {
		wxMessageDialog msgdlg (parentWin_, parentWin_->getImageInfo(), L"");
		msgdlg.ShowModal();
	}
	else {
		evt.Skip();
	}
}

//------------------------------------------------------------------------------

/*
 \history
 WGo-2016-06-07: created
 WGo-2016-08-24: full screen works
 WGo-2016-08-26: zoom in full screen works
 WGo-2016-08-29: pan in full screen works
 
 */
