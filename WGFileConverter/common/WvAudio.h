//-----------------------------------------------------------------------------
/*!
**	\file	WvAudio.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WV_AUDIO_H_
#define WV_AUDIO_H_

//-----------------------------------------------------------------------------

// Project headers

#include <CoreServices/CoreServices.h>

// std headers
//#include <string>

//-----------------------------------------------------------------------------

namespace Wview
{

	bool        AudioConnect();
	
	bool        AudioRecord();
	
	OSStatus InitAndStartAUHAL();

	void MyInputCallbackSetup();

} // namespace Wview

//-----------------------------------------------------------------------------

#endif // WV_AUDIO_H_

