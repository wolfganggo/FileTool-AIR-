//-----------------------------------------------------------------------------
/*!
**	\file	Pascal/_Imp/PascalIniFile.cpp
**
**	\author	(C) 2005 callas software gmbh
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "WvIniFile.h"


#include "wx/wx.h"
#include "wx/filesys.h"
#include "wx/stdpaths.h"

// std headers
#include <fstream>
#include <string>
#include <sstream>
#include <stdlib.h>


//------------------------------------------------------------------------------

using namespace wgfc;

//------------------------------------------------------------------------------

const std::string     wgfc::kSettingsSection("GLOBAL SETTINGS VALUES");
const std::string     wgfc::kTrueValue("true");
const std::string     wgfc::kFalseValue("false");

const char* const     wgfc::sDefFolderKey = "DefFolderValue";
const char* const     wgfc::sFirstFolderKey = "FirstFolderValue";
const char* const     wgfc::sSecondFolderKey = "SecondFolderValue";
const char* const     wgfc::sMainWindowWidthKey = "MainWindowWidth";
const char* const     wgfc::sMainWindowHeightKey = "MainWindowHeight";
const char* const     wgfc::sMainWindowXPosKey = "MainWindowXPos";
const char* const     wgfc::sMainWindowYPosKey = "MainWindowYPos";
const char* const     wgfc::sMainWindowSashPosKey = "MainWindowSashPos";



namespace {

	const wchar_t* s_inifile  = L"WGFileConvIniFile.txt";
	const wchar_t* s_privateFolder  = L"WGFileConverter";
	
	wxString getIniFileLocation()
	{
		wxFileName fs;
		fs.AssignDir (wxStandardPaths::Get().GetUserConfigDir());
		fs.AppendDir (wxString(s_privateFolder));
		if (!fs.DirExists()) {
			wxMkdir (fs.GetFullPath());
		}
		fs.SetFullName (s_inifile);
		return fs.GetFullPath();
	}
	

}

//------------------------------------------------------------------------------
bool wgfc::GetUserIniFileValue (const std::string& section,
								const std::string& key,
								std::string& value)
{
	std::string str;
	bool sectionFound = false;

	//std::ifstream ifs (iniFile.GetFullPath().ToStdString().c_str());
	std::ifstream ifs (getIniFileLocation().c_str());
	
	while( ifs.good()) {
		std::getline( ifs, str);
		if (str.empty()) {
			continue;
		}
		if( sectionFound) {
			if( 0 == str.find(key)) {
				if( str[key.size()] == '=') {
					//return str.substr( key.size() + 1);
					value = str.substr (key.size() + 1);
					return true;
				}
			}
		}
		if( str[0] == '[' && str[str.size()-1] == ']') {
			if( sectionFound) {
				sectionFound = false;
			}
			else if( std::string::npos != str.find(section)) {
				sectionFound = true;
			}
		}
	}
	return false;
}

//------------------------------------------------------------------------------
bool wgfc::SetUserIniFileValue (const std::string& section,
						          const std::string& key,
						          const std::string& value )
{
	wxString inifile (getIniFileLocation());
	std::string str, lastStr;
	std::ostringstream oss;
	bool sectionFound = false;
	bool inserted = false;
	//bool valueFound = false;

	{
		//std::ifstream ifs (iniFile.GetFullPath().ToStdString().c_str());
		std::ifstream ifs (inifile.c_str());
		while( ifs.good()) {
			std::getline( ifs, str);
			if( str.empty()) {
				break;
			}
			if( sectionFound) {
				if( 0 == str.find(key)) {
					if( str[key.size()] == '=') {
						std::string oldval = str.substr( key.size() + 1);
						if (oldval != value) {
							// replace value
							str = key + "=" + value;
							inserted = true;
						}
						else {
							//valueFound = true;
							return true;
						}
					}
				}
			}
			if( str[0] == '[' && str[str.size()-1] == ']') {
				if( sectionFound) {
					sectionFound = false;
					if( !inserted) {
						// insert new line
						oss << key << '=' << value << std::endl;
						inserted = true;
					}
				}
				else if( std::string::npos != str.find(section)) {
					sectionFound = true;
				}
			}
			oss << str << std::endl;
			lastStr = str;
		}
		if( !inserted) {
			if( !sectionFound) {
			// Add section
				oss << "[" << section << "]" << std::endl;
			}
			oss << key << '=' << value << std::endl;
		}
	}
	{
		std::ofstream ofs (inifile.c_str());
		if( ofs.good()) {
			ofs.write(oss.str().c_str(), oss.str().size());
			return true;
		}
	}
	return false;
}

//------------------------------------------------------------------------------
bool wgfc::GetUserIniFileIntValue (const std::string& section,
								   const std::string& key,
								   int &value)
{
	std::string sval;
	if (GetUserIniFileValue (section, key, sval)) {
		value = std::atoi (sval.c_str());
		return true;
	}
	//std::string sval = GetUserIniFileValue (section, key);
	//return std::atoi (sval.c_str());
	return false;
}

bool wgfc::SetUserIniFileIntValue (const std::string& section,
								   const std::string& key,
								   int value )
{
	std::ostringstream oss;
	oss << value;
	return SetUserIniFileValue (section, key, oss.str());
}

//------------------------------------------------------------------------------

