//-----------------------------------------------------------------------------
/*!
**	\file	common/TextContent.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WG_TEXTCONTENT_H_
#define WG_TEXTCONTENT_H_

//-----------------------------------------------------------------------------

// Project headers


// std headers
#include <string>

//-----------------------------------------------------------------------------


class PreviewTextCtrl;


class TextContent
{
public:
	
	TextContent (const std::wstring &file, PreviewTextCtrl *ctrl, bool binary);
	~TextContent();
	
	bool writeToEditCtrl();
	
	int getCurLength();
	
	
private:
	
	std::wstring        filepath_;
	PreviewTextCtrl   * textctrl_;
	bool                binary_;
	int                 position_;
	bool                endoffile_;
	
};
	

//-----------------------------------------------------------------------------

#endif // WG_TEXTCONTENT_H_

//-----------------------------------------------------------------------------

/*
 \history
 WGo-2016-06-07: created
 
 */
