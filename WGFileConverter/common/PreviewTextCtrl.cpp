//-----------------------------------------------------------------------------
/*!
 **	\file	Common/PreviewTextCtrl.cpp
 **
 **	\author	Wolfgang Goldbach
 */
//-----------------------------------------------------------------------------


#include "PreviewTextCtrl.h"
#include "FileSystemList.h"

// wxWidgets

namespace {
	
	int charwidth10 = 73; // 73
	//int charheight10 = 140;
	
	enum {
		
		SB_HORIZONTAL = wxID_LAST + 1,
		SB_VERTICAL,
		
	};

}


wxBEGIN_EVENT_TABLE(PreviewTextCtrl, wxControl)
	EVT_PAINT(PreviewTextCtrl::OnPaintEvt)
	EVT_SIZE(PreviewTextCtrl::OnSizeEvt)
	EVT_KEY_DOWN(PreviewTextCtrl::OnKeyDown)
	EVT_COMMAND_SCROLL(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorEvt)
	EVT_COMMAND_SCROLL(SB_VERTICAL, PreviewTextCtrl::OnScrollVerEvt)
	//EVT_COMMAND_SCROLL_TOP(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorTop)
	//EVT_COMMAND_SCROLL_BOTTOM(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorBottom)
	EVT_COMMAND_SCROLL_PAGEUP(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorPageUp)
	EVT_COMMAND_SCROLL_PAGEDOWN(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorPageDown)
	EVT_COMMAND_SCROLL_THUMBTRACK(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorThumb)
	EVT_COMMAND_SCROLL_THUMBRELEASE(SB_HORIZONTAL, PreviewTextCtrl::OnScrollHorRelease)
	//EVT_COMMAND_SCROLL_TOP(SB_VERTICAL, PreviewTextCtrl::OnScrollVerTop)
	//EVT_COMMAND_SCROLL_BOTTOM(SB_VERTICAL, PreviewTextCtrl::OnScrollVerBottom)
	EVT_COMMAND_SCROLL_PAGEUP(SB_VERTICAL, PreviewTextCtrl::OnScrollVerPageUp)
	EVT_COMMAND_SCROLL_PAGEDOWN(SB_VERTICAL, PreviewTextCtrl::OnScrollVerPageDown)	
	EVT_COMMAND_SCROLL_THUMBTRACK(SB_VERTICAL, PreviewTextCtrl::OnScrollVerThumb)
	EVT_COMMAND_SCROLL_THUMBRELEASE(SB_VERTICAL, PreviewTextCtrl::OnScrollVerRelease)
wxEND_EVENT_TABLE()


	
PreviewTextCtrl::PreviewTextCtrl (wxWindow *parent,
								  wxWindowID id,
								  FileSystemList *fsl)
: wxControl(parent, id)
, fileList_(fsl)
, wrap_(false)
, fixedFont_(true)
, enableHorScr_(false)
, enableVerScr_(false)
, curTextPosRight_(0)
, curTextPosLeft_(0)
, curLineTop_(0)
, curLineBottom_(0)
, curLineCount_(0)
, totalLineCount_(0)
, hasTotalLineCount_(false)
, curCharPerLineCount_(0)
, dimensionValid_(false)
, hpagestep_(0)
, vpagestep_(0)
, hthumbsize_(0)
, vthumbsize_(0)
, maxlinelen_(0)
, newHorValue_(false)
, newVerValue_(false)
, paintHandlerCB_(NULL)
, zoomHandlerCB_(NULL)
, loadTextCB_(NULL)
, imageZoom_(0)
, maxZoom_(false)
, textEnd_(false)
{
	SetBackgroundColour (wxColour(255,255,240));
	horScrlbr_ = new wxScrollBar (this, SB_HORIZONTAL);
	verScrlbr_ = new wxScrollBar (this, SB_VERTICAL, wxDefaultPosition, wxDefaultSize, wxSB_VERTICAL);
}

void PreviewTextCtrl::OnPaintEvt (wxPaintEvent& evt)
{
	if (paintHandlerCB_) {
		paintHandlerCB_();
		return;
	}
	// tested: start pos = 5, 5  fontsize = 12 (fixed), 11 (prop.)  line distance = 14
	wxPaintDC dc (this);
	wxFontFamily fix = fixedFont_ ? wxFONTFAMILY_TELETYPE : wxFONTFAMILY_DEFAULT;
	int fontSize = fixedFont_ ? 12 : 11;
	dc.SetFont (wxFont(fontSize, fix, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL));
	//dc.DrawText (L"This is a text in fixed font and size 12 on y = 92.", wxPoint(5,92));
	//dc.SetFont (wxFont(11, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL));
	
	std::cout << "\n*** OnPaintEvt ***\n\n";

	int w = GetRect().width;
	int h = GetRect().height;
	int client_w = w - 15;
	int client_h = h - 15;
	int x = 5;
	int y = 5;
	wxString line;
	wxString::size_type ix = 0;
	wxString::size_type ix_last = 0;
	int maxlinelen = 0;
	int lineix = 0;
	
	dc.SetClippingRegion (0, 0, w, client_h);
	
	int newTextPosRight = curTextPosLeft_ + (client_w * 10) / charwidth10 + 2;
	bool rightEnd = true;
	wxString::size_type ixload = text_.size() * 0.8;
	if (text_.size() > 1000000) {
		ixload = text_.size() - 100000;
	}
	do {
		if (y > client_h) {
			break;
		}
		
		ix_last = ix;
		ix = text_.find (L'\n', ix_last);
		line = text_.substr (ix_last, ix - ix_last);
		if (ix != wxString::npos) {
			++ix;
		}
		int linelen = line.size();
		if (linelen > maxlinelen) {
			maxlinelen = linelen;
		}
		if (linelen > newTextPosRight) {
			rightEnd = false;
			//line.resize (newTextPosRight);
		}
		++lineix;
		if (lineix < curLineTop_) {
			continue;
		}
		
		if (y == 5) {
			std::cout << "First line is: " << line.c_str() << "\n";
		}
		
		int len = ((client_w * 10) / charwidth10) + 2;
		curCharPerLineCount_ = len - 1;
		if (curTextPosLeft_ + len > line.size()) {
			len = line.size() - curTextPosLeft_;
		}
		if (len > 0) {
			dc.DrawText (line.substr(curTextPosLeft_, len), wxPoint(x,y));
		}
		y += 14;

	} while (ix < text_.size());

	std::cout << "text size is: " << text_.size() << "\n";
	
	if (!textEnd_ && ix > ixload && loadTextCB_ != NULL) {
		textEnd_ = !loadTextCB_();
		hasTotalLineCount_ = false;
	}
	
	if (rightEnd) {
		curTextPosRight_ = maxlinelen;
	}
	else {
		curTextPosRight_ = newTextPosRight;
	}
	curLineBottom_ = lineix;
	curLineCount_ = lineix - curLineTop_;
	if (curLineCount_ < 0) {
		curLineCount_ = 0;
	}
	
	if (!dimensionValid_) {
		setScrolbarValues (lineix, ix, maxlinelen);
	}
	else if (newHorValue_) {
		horScrlbr_->SetThumbPosition (95);
		newHorValue_ = false;
	}
	else if (newVerValue_) {
		std::cout << "vertical Scrolbar reset to 95\n";
		verScrlbr_->SetThumbPosition (95);
		newVerValue_ = false;
	}
	enableHorScr_ = !wrap_ && client_w < (charwidth10 * maxlinelen) / 10;
	enableVerScr_ = (curLineTop_ != 0) || (y + 14 > client_h);
	horScrlbr_->Enable (enableHorScr_);
	verScrlbr_->Enable (enableVerScr_);
}

void PreviewTextCtrl::setScrolbarValues (int linecount, wxString::size_type textindex, int maxlen)
{
	if (curCharPerLineCount_ < 1 || curLineCount_ < 1) {
		return;
	}
	std::cout << "*** setScrolbarValues ***\n";
	std::cout << "linecount, textindex: " << linecount << ", " << textindex <<  "\n";
	wxString line;
	wxString::size_type ix = textindex;
	wxString::size_type ix_last = 0;
	maxlinelen_ = maxlen;
	int lineix = linecount;
	//if (!hasTotalLineCount_) {
		do {
			ix_last = ix;
			++ix;
			ix = text_.find (L'\n', ix);
			int linelen = 0;
			if (ix == wxString::npos) {
				linelen = text_.size() - ix_last;
			}
			else {
				linelen = ix - ix_last;
			}
			if (linelen > maxlinelen_) {
				maxlinelen_ = linelen;
			}
			++lineix;
		} while (ix < text_.size());
		
		totalLineCount_ = lineix;
		hasTotalLineCount_ = true;
	//}
	int hpagecount = maxlinelen_ / curCharPerLineCount_ + 1;
	int vpagecount = totalLineCount_ / curLineCount_ + 1;
	std::cout << "totalLineCount_, curLineCount_ : " << totalLineCount_ << ", " << curLineCount_ <<  "\n";
	hpagestep_ = 100 / hpagecount;
	vpagestep_ = 100 / vpagecount;
	if (hpagestep_ < 5) {
		hpagestep_ = 5;
	}
	if (vpagestep_ < 5) {
		vpagestep_ = 5;
	}
	hthumbsize_ = hpagestep_;
	vthumbsize_ = vpagestep_;
	int topline = linecount - curLineCount_;
	int hpos = (curTextPosLeft_ * 100) / maxlinelen_;
	int vpos = (topline * 100) / totalLineCount_;
	if (curTextPosLeft_ > maxlinelen_) {
		hpos = 100;
	}
	if (topline > totalLineCount_) {
		vpos = 100;
	}
	std::cout << "hpos, vpos : " << hpos << ", " << vpos <<  "\n";
	horScrlbr_->SetScrollbar (hpos, hthumbsize_, 105, hpagestep_);
	verScrlbr_->SetScrollbar (vpos, vthumbsize_, 105, vpagestep_);
	
	dimensionValid_ = true;
}

void PreviewTextCtrl::OnSizeEvt (wxSizeEvent& evt)
{
	int w = GetRect().width;
	int h = GetRect().height;
	int client_w = w - 15;
	int client_h = h - 15;

	horScrlbr_->SetSize (client_w, 15);
	horScrlbr_->Move (0, client_h);
	horScrlbr_->SetScrollbar (0, 20, 105, 10);
	verScrlbr_->SetSize (15, client_h);
	verScrlbr_->Move (client_w, 0);
	verScrlbr_->SetScrollbar (0, 20, 105, 10);
	dimensionValid_ = false;

	evt.Skip();
}

void PreviewTextCtrl::OnScrollHorEvt (wxScrollEvent& evt)
{
	evt.Skip();
}
	
void PreviewTextCtrl::OnScrollVerEvt (wxScrollEvent& evt)
{
	evt.Skip();
}


void PreviewTextCtrl::OnScrollHorPageUp (wxScrollEvent& evt)
{
	if (evt.GetPosition() == 0) {
		curTextPosLeft_ = 0;
		curTextPosRight_ = 0;
	}
	else if (curTextPosLeft_ - (curCharPerLineCount_ - 1) > 0) {
		curTextPosLeft_ -= (curCharPerLineCount_ - 1);
	}
	else {
		curTextPosLeft_ = 0;
	}
	dimensionValid_ = false;
	Refresh();
}

void PreviewTextCtrl::OnScrollHorPageDown (wxScrollEvent& evt)
{
	if (curTextPosRight_ > 0) {
		curTextPosLeft_ = curTextPosRight_ - 1;
	}
	if (evt.GetPosition() > 95 && curTextPosLeft_ + curCharPerLineCount_ < maxlinelen_) {
		newHorValue_ = true;
	}
	dimensionValid_ = false;
	Refresh();
}

void PreviewTextCtrl::OnScrollHorThumb (wxScrollEvent& evt)
{
	evt.Skip();
}

void PreviewTextCtrl::OnScrollHorRelease (wxScrollEvent& evt)
{
	std::cout << "*** OnScrollHorRelease ***\n";
	int tpos = horScrlbr_->GetThumbPosition();
	int curpos = maxlinelen_ * tpos / 100;
	if (curpos > maxlinelen_ - 10) {
		curpos = maxlinelen_ - 10;
	}
	curTextPosLeft_ = curpos;
	dimensionValid_ = false;
	Refresh();
	//evt.Skip();
}


void PreviewTextCtrl::OnScrollVerPageUp (wxScrollEvent& evt)
{
	dimensionValid_ = false;
	doVerticalPageUp();
}

void PreviewTextCtrl::OnScrollVerPageDown (wxScrollEvent& evt)
{
	dimensionValid_ = false;
	doVerticalPageDown();
}

void PreviewTextCtrl::doVerticalPageUp (bool fromKey)
{
	int tpos = verScrlbr_->GetThumbPosition();
	//if (evt.GetPosition() == 0) {
	if (curLineTop_ - curLineCount_ > 0) {
		curLineTop_ -= curLineCount_;
	}
	else {
		curLineTop_ = 0;
	}
	
	if (fromKey) {
		int newpos = tpos - vpagestep_;
		if (newpos >= 0) {
			verScrlbr_->SetThumbPosition (newpos);
		}
	}
	Refresh();
}

void PreviewTextCtrl::doVerticalPageDown (bool fromKey)
{
	int tpos = verScrlbr_->GetThumbPosition();
	if (curLineBottom_ > 0) {
		curLineTop_ = curLineBottom_;
		if (curLineTop_ > totalLineCount_ - 10 && totalLineCount_ > 10) {
			curLineTop_ = totalLineCount_ - 10;
		}
	}
	if (tpos > 95 && curLineTop_ + curLineCount_ < totalLineCount_) {
		newVerValue_ = true;
	}
	else if (fromKey) {
		verScrlbr_->SetThumbPosition (tpos + vpagestep_);
	}
	Refresh();
}

void PreviewTextCtrl::OnScrollVerThumb (wxScrollEvent& evt)
{
	evt.Skip();
}

void PreviewTextCtrl::OnScrollVerRelease (wxScrollEvent& evt)
{
	std::cout << "*** OnScrollVerRelease ***\n";
	int tpos = verScrlbr_->GetThumbPosition();
	int curLine = totalLineCount_ * tpos / 100;
	if (curLine > totalLineCount_ - 3) {
		curLine = totalLineCount_ - 3;
	}
	curLineTop_ = curLine;
	dimensionValid_ = false;
	Refresh();
	//evt.Skip();
}

void PreviewTextCtrl::OnKeyDown (wxKeyEvent& evt)
{
	int code = evt.GetKeyCode();

	if (!evt.ControlDown()) {
		if (code == WXK_UP || code == WXK_DOWN || code == WXK_LEFT || code == WXK_RIGHT) {
			fileList_->ProcessKeyEvent (code);
			return;
		}
	}

	if (zoomHandlerCB_ != NULL) {
		int zoom = -1;
		int panx = 0;
		int pany = 0;
		//imageZoom_ = 0 // default view
		// WXK_SHIFT WXK_CONTROL WXK_ALT
		// ControlDown() ShiftDown() AltDown()
		
		if (code == WXK_UP) {
			pany = 1;
		}
		else if (code == WXK_DOWN) {
			pany = -1;
		}
		else if (code == WXK_LEFT) {
			panx = -1;
		}
		else if (code == WXK_RIGHT) {
			panx = 1;
		}
		else if (code == 'Z' || code == '+') {
			if (!maxZoom_) {
				++imageZoom_;
				zoom = imageZoom_;
			}
		}
		else if (code == 'B' || code == '-') {
			if (imageZoom_ > 0) {
				--imageZoom_;
				zoom = imageZoom_;
			}
		}
		else if (code == '0') {
			if (imageZoom_ > 0) {
				imageZoom_ = 0;
				zoom = imageZoom_;
				maxZoom_ = false;
			}
		}

		if (zoom >= 0) {
			maxZoom_ = !zoomHandlerCB_ (zoom, panx, pany);
			Refresh();
		}
		else if (panx != 0 || pany != 0) {
			zoomHandlerCB_ (zoom, panx, pany);
			Refresh();
		}
	}
	else {
		dimensionValid_ = false;
		if (code == WXK_PAGEUP) {
			doVerticalPageUp();
		}
		else if (code == WXK_PAGEDOWN) {
			doVerticalPageDown();
		}
		else if (code == WXK_UP) {
			if (curLineTop_ > 0) {
				--curLineTop_;
				Refresh();
			}
		}
		else if (code == WXK_DOWN) {
			if (curLineTop_ < totalLineCount_ - 3) {
				++curLineTop_;
				Refresh();
			}
		}
		else if (code == WXK_LEFT) {
			if (curTextPosLeft_ > 0) {
				--curTextPosLeft_;
				Refresh();
			}
		}
		else if (code == WXK_RIGHT) {
			if (curTextPosLeft_ < maxlinelen_ - 10) {
				++curTextPosLeft_;
				Refresh();
			}
		}
	}
	
	evt.Skip();
}

void PreviewTextCtrl::WriteText (const wxString &text)
{
	wxString::size_type ix = 0;
	wxString::size_type ix_last = 0;
	do {
		ix_last = ix;
		if (ix > 0) {
			++ix;
		}
		ix = text.find (L'\r', ix);
		if (ix != wxString::npos) {
			text_ += text.substr(ix_last, ix - ix_last);
			bool iswin = (text.size() > ix + 1 && text[ix + 1] == L'\n');
			if (!iswin) {
				text_ += L'\n';
			}
			++ix;
		}
		else {
			text_ += text.substr(ix_last);
		}
	} while (ix < text.size());

	dimensionValid_ = false;
	Refresh();
}

void PreviewTextCtrl::setWrapLines (bool wrap)
{
	if (wrap_ == wrap) {
		return;
	}
	wrap_ = wrap;
}

void PreviewTextCtrl::Clear()
{
	text_.erase();
	curTextPosLeft_ = 0;
	curTextPosRight_ = 0;
	curLineTop_ = 0;
	curLineBottom_ = 0;
	dimensionValid_ = false;
	textEnd_ = false;
	Refresh();
}

void PreviewTextCtrl::showScrollbars (bool show)
{
	horScrlbr_->Show (show);
	verScrlbr_->Show (show);
}

void PreviewTextCtrl::setPaintHandler (PaintHandlerFn cb)
{
	paintHandlerCB_ = cb;
	SetFocus();
}

void PreviewTextCtrl::setZoomHandler (ZoomHandlerFn cb)
{
	zoomHandlerCB_ = cb;
	imageZoom_ = 0;
	maxZoom_ = false;
}



//-----------------------------------------------------------------------------

/*
\history
 WGo-2016-06-17: created
 WGo-2016-09-07: scrolling of long text works
 
*/
