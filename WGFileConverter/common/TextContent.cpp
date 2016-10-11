//-----------------------------------------------------------------------------
/*!
**	\file	common/TextContent.cpp
**
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "TextContent.h"

// project
#include "PreviewTextCtrl.h"

// wxWidgets
#include "wx/wx.h"
#include "wx/filesys.h"
#include "wx/textctrl.h"

// std headers
#include <fstream>
#include <string>
#include <sstream>
#include <stdlib.h>


namespace {

	const wchar_t * msg_no_content  = L"(C) axaio software gmbh";
	
	const int kMaxLength = 500 * 1000 * 1000;
	const int kMaxLengthPerRead = 10 * 1000 * 1000;
	const int kMaxLineCountPerRead = 20000;
	const int kMaxLineCountPerReadBinary = 5000;
	
	TextContent * curObject_ = NULL;

	
	wxString getHex (char b)
	{
		wxString s = wxString::Format (L"%x", (unsigned char)b);
		if (s.size() == 1) {
			s.Prepend (wxString(L"0"));
		}
		return s;
	}
	
	wxString getFixString (int b)
	{
		wxString s;
		s << b;
		if (s.size() == 1) {
			s.Prepend (wxString(L"00000"));
		}
		else if (s.size() == 2) {
			s.Prepend (wxString(L"0000"));
		}
		else if (s.size() == 3) {
			s.Prepend (wxString(L"000"));
		}
		else if (s.size() == 4) {
			s.Prepend (wxString(L"00"));
		}
		else if (s.size() == 5) {
			s.Prepend (wxString(L"0"));
		}
		return s;
	}
	
	bool loadMoreText()
	{
		if (curObject_ != NULL) {
			return curObject_->writeToEditCtrl();
		}
		return false;
	}

}

//------------------------------------------------------------------------------

TextContent::TextContent (const std::wstring &file, PreviewTextCtrl *ctrl, bool binary)
: filepath_(file), textctrl_(ctrl), binary_(binary), position_(0), endoffile_(false)
{
	curObject_ = this;
	if (textctrl_ != NULL) {
		textctrl_->Clear();
		textctrl_->setLoadTextHandler (loadMoreText);
	}
}

TextContent::~TextContent()
{
	if (textctrl_ != NULL) {
		textctrl_->setLoadTextHandler (NULL);
	}
}


bool TextContent::writeToEditCtrl()
{
	if (endoffile_) {
		return false;
	}
	if (textctrl_ == NULL) {
		return false;
	}
	if (position_ > kMaxLength) {
		endoffile_ = true;
		return false;
	}

	//textctrl_->Clear();
	wxFile fs (filepath_);
	if (!fs.IsOpened()) {
		if (position_ == 0) {
			textctrl_->WriteText (msg_no_content);
		}
		return false;
	}
	fs.Seek (position_);
	if (fs.Eof()) {
		endoffile_ = true;
		return false;
	}

	char bbuf[2] = {0,0};
	char buf[1000];
	ssize_t rcount = 0;
	wxString line;
	bool wasLF = false;
	bool wasCR = false;
	int numread = 0;
	int linecount = 0;
	
	int cl = 0;
	wxString tx;

	if (binary_) do {
		rcount = fs.Read (bbuf, 1);
		if (fs.Eof()) {
			endoffile_ = true;
		}

		if (rcount < 1) {
			endoffile_ = true;
		}
		else {
			if (cl == 0) {
				textctrl_->WriteText (getFixString (position_ + numread));
				textctrl_->WriteText (L"  ");
				textctrl_->WriteText (getHex (bbuf[0]));
				textctrl_->WriteText (L" ");
			}
			else if (cl == 7) {
				textctrl_->WriteText (getHex (bbuf[0]));
				textctrl_->WriteText (L"  ");
			}
			else {
				textctrl_->WriteText (getHex (bbuf[0]));
				textctrl_->WriteText (L" ");
			}
			if (bbuf[0] < 32 || bbuf[0] > 126) {
				tx += L".";
			}
			else {
				tx += (wchar_t)bbuf[0];
			}
			++cl;
			if (cl == 16 || endoffile_) {
				for (int i = 0; i < 16 - cl; ++i) {
					textctrl_->WriteText (L"   ");
					if (i == 7) {
						textctrl_->WriteText (L" ");
					}
				}
				cl = 0;
				textctrl_->WriteText (L"  ");
				textctrl_->WriteText (tx);
				textctrl_->WriteText (L"\n");
				++linecount;
				tx.erase();
			}
			++numread;
		}
		if (linecount > kMaxLineCountPerReadBinary || numread >= kMaxLengthPerRead || endoffile_) {
			position_ += numread;
			break;
		}
	} while (true);
	
	else do {
		rcount = fs.Read (buf, 1000);
		for (int ix = 0; ix < rcount; ++ix) {
			++numread;
			if (linecount <= kMaxLineCountPerRead && numread <= kMaxLengthPerRead) {
				if (buf[ix] == 10) {
					if (!wasCR) {
						line += L'\n';
						textctrl_->WriteText (line);
						line.erase();
						++linecount;
					}
					wasLF = true;
					wasCR = false;
				}
				else if (buf[ix] == 13) {
					line += L'\n';
					textctrl_->WriteText (line);
					line.erase();
					++linecount;
					wasLF = false;
					wasCR = true;
				}
				else if (buf[ix] == 9) {
					line += L"    ";
					wasLF = false;
					wasCR = false;
				}
				else if (buf[ix] < 32 || buf[ix] > 126) {
					line += L'.';
					wasLF = false;
					wasCR = false;
				}
				else {
					wchar_t wc = buf[ix];
					line += wc;
					wasLF = false;
					wasCR = false;
				}
				
				if (line.size() > 2000) {
					line += L'\n';
					textctrl_->WriteText (line);
					line.erase();
					++linecount;
				}
			}
			else {
				textctrl_->WriteText (line);
				break;
			}
		}
		if (fs.Eof()) {
			endoffile_ = true;
		}
		if (linecount > kMaxLineCountPerRead || numread <= kMaxLengthPerRead || endoffile_) {
			position_ += numread;
			break;
		}
	} while (true);
	
	// restore text cursor
	//textctrl_->SetInsertionPoint (oldInsPt);

	return true;
}

int TextContent::getCurLength()
{
	return position_;
}

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-06-07: created
 
 */

