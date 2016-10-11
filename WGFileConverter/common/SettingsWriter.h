//========================================================================================
//
//	\file	SettingsWriter.h
//	
//	\author	Wolfgang Goldbach
//	\author	(C) 2007 axaio software gmbh
//
//========================================================================================

#ifndef WGFC_SETTINGSWRITER_H_
#define WGFC_SETTINGSWRITER_H_

// Project includes
//#include "OskarBase/OskarTypes.h"

// std headers
#include <string>
#include <fstream>
#include <vector>

//==============================================

typedef std::vector<std::string>   TParentPath;

class WGFCSettings {
public:
	
	WGFCSettings();
	~WGFCSettings();
	
private:
	
	std::wstring          defFolder_;
	std::wstring          firstFolder_;
	std::wstring          secondFolder_;

	struct Dialog {
		std::string  dlgid;
		int          width;
		int          height;
		int          xpos;
		int          ypos;
	};
	
	std::vector<Dialog>    dialogs_;
	int                    sash_;
};


namespace wgfc {

	//------------------------------------------

	class XMLNode {
	public:
		typedef std::vector<std::string> TPath;
		typedef std::vector<XMLNode> TContent;
		
		XMLNode (const std::string & parent, const std::string & key);
		XMLNode (const TPath & path);
		~XMLNode() {}
		
		void setValue (const std::string & value);
		void setContent (const TContent & children);
		
		std::string getPath();
		TPath       getPath();
		bool hasValue();
		//bool hasChildren();
		bool isEmpty();
		
	private:
		TPath                  path_;
		std::wstring           value_;
		TContent               children_;
	};
	
	//------------------------------------------
	
	class SettingsWriter
	{
	public:
		
		SettingsWriter();
		
		void write( const std::wstring& file);
		bool read( const std::wstring& file);
		
	private:
		
		int                    tabs_;
		
		const SettingsWriter & operator=(const SettingsWriter&); // prevent warning
		
	};
	
	//------------------------------------------

	class OskarParser
	{
	public:
		OskarParser (std::wstring & content, TParentPath& path);
		
		void parse();
		
		bool good();
		
		bool hasModified() { return modified_; }
		
	private:
		
		TParentPath          & path_;
		std::wstring         & content_;
		std::wstring           tag_;
		bool                   error_;
		bool                   modified_;
		
		void saveValue( const TParentPath& path, const std::wstring& value);
		void handleTag( const std::string& tag, bool open);
		
		const OskarParser & operator=(const OskarParser&); // prevent warning
		
	};

}


//-----------------------------------------------------------------------------

#endif // WGFC_SETTINGSWRITER_H_

//------------------------------------------------------------------------------
/*! \history

WGo-2016-08-29: created

*/
