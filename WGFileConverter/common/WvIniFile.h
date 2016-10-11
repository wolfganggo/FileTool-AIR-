//-----------------------------------------------------------------------------
/*!
**	\file	WvIniFile.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WV_INIFILE_H_
#define WV_INIFILE_H_

//-----------------------------------------------------------------------------

// Project headers


// std headers
#include <string>

//-----------------------------------------------------------------------------

namespace wgfc
{

	extern const std::string     kSettingsSection;
	extern const std::string     kTrueValue;
	extern const std::string     kFalseValue;

	extern const char* const     sDefFolderKey;
	extern const char* const     sFirstFolderKey;
	extern const char* const     sSecondFolderKey;
	extern const char* const     sMainWindowWidthKey;
	extern const char* const     sMainWindowHeightKey;
	extern const char* const     sMainWindowXPosKey;
	extern const char* const     sMainWindowYPosKey;
	extern const char* const     sMainWindowSashPosKey;


	bool        GetUserIniFileValue (const std::string& section,
									 const std::string& key,
									 std::string& value);
	
	bool        SetUserIniFileValue (const std::string& section,
									 const std::string& key,
									 const std::string& value );
	
	bool        GetUserIniFileIntValue (const std::string& section,
										const std::string& key,
										int &value);
	
	bool        SetUserIniFileIntValue (const std::string& section,
										const std::string& key,
										int value );
	

} // namespace wgfc

//-----------------------------------------------------------------------------

#endif // WV_INIFILE_H_

