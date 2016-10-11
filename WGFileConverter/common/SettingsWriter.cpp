//========================================================================================
//
//	\file	OskarBase/_Imp/OskarSettingsWriter.cpp
//	
//	\author	Wolfgang Goldbach
//	\author	(C) 2008 axaio software gmbh
//
//========================================================================================

//#include "VCPlugInHeaders.h"

// own header
#include "OskarSettingsWriter.h"

// Project includes
//#include "OskarBase/OskarPrefs.h"

// std includes
//#include <fstream>

// wxWidgets
#include "wx/wx.h"


using namespace wgfc;

//========================================================================================

namespace {

	const char* xmlHeader = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";

	const char* keyAxaio1 = "AxaioPrivate_1";

	const char* keyProfiles = "Profiles";
	const char* keyProfile = "Profile";

	const char* keyUuid = "UUID";
	const char* keyName = "Name";
	const char* keyComment = "Comment";

	const wchar_t  ch_lt = L'<';
	const wchar_t  ch_gt = L'>';
	const wchar_t  ch_amp = L'&';
	const wchar_t  ch_nl = L'\n';
	const wchar_t  ch_cr = L'\r';
	const wchar_t  ch_tab = L'\t';
	const wchar_t  ch_sm = L';';
	const wchar_t  ch_endtag = L'/';

	const std::wstring str_amp( L"&amp;");
	const std::wstring str_lt( L"&lt;");
	const std::wstring str_gt( L"&gt;");
	const std::wstring str_nl( L"&#10;");
	const std::wstring str_cr( L"&#13;");
	const std::wstring str_tab( L"&#09;");

	//=======================================================

	std::string toUTF8( const std::wstring& inStr)
	{
		wxString wxStr;
		for( std::wstring::size_type ix = 0; ix < inStr.size(); ++ix) {
			wxChar c = inStr[ix];
			if( c == ch_amp) {
				wxStr += str_amp;
			}
			else if( c == ch_lt) {
				wxStr += str_lt;
			}
			else if( c == ch_gt) {
				wxStr += str_gt;
			}
			else if( c == ch_nl) {
				wxStr += str_nl;
			}
			else if( c == ch_cr) {
				wxStr += str_cr;
			}
			else if( c == ch_tab) {
				wxStr += str_tab;
			}
			else {
				wxStr += c;
			}
		}
		return std::string( wxStr.utf8_str().data());
		//const wxCharBuffer utf8_str() 
	}

	std::string toSysStr( const std::wstring& inStr)
	{
		wxString wxStr( inStr);
		//const char* mb_str(wxMBConv& conv) wxConvLibc
		return std::string( wxStr.mb_str( wxConvLibc).data());
	}

	std::wstring fromXML( const std::wstring& inStr)
	{
		std::wstring retStr;
		for( std::wstring::size_type ix = 0; ix < inStr.size(); ++ix) {
			wchar_t c = inStr[ix];
			if( c == ch_amp) {
				std::wstring::size_type ix2 = inStr.find( ch_sm, ix);
				wxASSERT( ix2 != std::wstring::npos);
				if( ix2 == std::wstring::npos) {
					retStr.erase();
					return retStr;
				}
				std::wstring specialChar = inStr.substr( ix, ix2 - ix + 1);
				if( specialChar == str_amp) {
					retStr += ch_amp;
				}
				else if( specialChar == str_lt) {
					retStr += ch_lt;
				}
				else if( specialChar == str_gt) {
					retStr += ch_gt;
				}
				else if( specialChar == str_nl) {
					retStr += ch_nl;
				}
				else if( specialChar == str_cr) {
					retStr += ch_cr;
				}
				else if( specialChar == str_tab) {
					retStr += ch_tab;
				}
				else {
					// Error
					wxASSERT( false);
					retStr.erase();
					return retStr;
				}
				ix = ix2;
			}
			else {
				retStr += c;
			}
		}
		return retStr;
	}

	std::string getTabs( int tabs)
	{
		std::string retStr;
		while( tabs--) {
			retStr += "\t";
		}
		return retStr;
	}

	std::wstring getHex( const PrefsUuid& id)
	{
		wxString str = wxString::Format( L"%08x", id.element0_);
		str += wxString::Format( L"%08x", id.element1_);
		str += wxString::Format( L"%08x", id.element2_);
		str += wxString::Format( L"%08x", id.element3_);
		return str.c_str();
		//static wxString Format(const wxChar *format, ...)
	}
/*
	unsigned long wcstoul(
   const wchar_t *nptr,
   wchar_t **endptr,
   int base 
);
*/
	unsigned int convertHexToUL( const std::wstring& str)
	{
		wchar_t *endPtr;
		return wcstoul( str.c_str(), &endPtr, 16);
	}

	PrefsUuid getUuidFromString( const std::wstring& str)
	{
		unsigned int v1 = 0, v2 = 0, v3 = 0, v4 = 0;
		if( str.size() == 32) do {
			//wxString s1 = str.substr( 0, 8);
			//success = s1.ToLong( (long*)&v1, 16);
			v1 = convertHexToUL( str.substr( 0, 8));
			v2 = convertHexToUL( str.substr( 8, 8));
			v3 = convertHexToUL( str.substr( 16, 8));
			v4 = convertHexToUL( str.substr( 24, 8));
		} while(false);

		return PrefsUuid( v1, v2, v3, v4);
	}

	std::wstring getNumString( int num)
	{
		wxString str = wxString::Format( L"%d", num);
		return str.c_str();
	}

	int getLongFromString( const std::wstring& str)
	{
		long retval = 0;
		wxString wxs = str;
		bool success = wxs.ToLong( &retval);
		wxASSERT( success);
		return retval;
	}

	void writeHeader( std::ofstream& fs)
	{
		fs << xmlHeader << "\n";
	}

	class GroupWriter {
	public:
		GroupWriter( std::ofstream& fs, const std::string& group, int& tabs)
			: fs_(fs),group_(group),tabs_(tabs)
		{
			fs << getTabs(tabs++) << "<" << group_ << ">\n";
		}
		~GroupWriter()
		{
			fs_ << getTabs(--tabs_) << "</" << group_ << ">\n";
		}
	private:
		std::ofstream      & fs_;
		std::string          group_; // must be a copy of the input string
		int                & tabs_;
	};

	void writeEntry( std::ofstream& fs, const std::string& key, const std::string& value, int& tabs)
	{
		fs << getTabs(tabs) << "<" << key << ">" <<  value << "</" << key << ">\n";
	}

	bool readHeader( std::string& content)
	{
		std::string header( xmlHeader);
		if( content.substr( 0, header.size()) == header) {
			content.erase( 0, header.size());
			return true;
		}
		else {
			content.erase();
			return false;
		}
	}


}

//========================================================================================

SettingsWriter::SettingsWriter ()
: tabs_(0)
{
}

void SettingsWriter::write( const std::wstring& file)
{
	std::ofstream ofs( file.c_str());
	writeHeader( ofs);
	GroupWriter gwax( ofs, keyAxaio1, tabs_);
	{
		GroupWriter gwps( ofs, keyProfiles, tabs_);
		for( unsigned int ix = 0; ix < settings_.profiles_.size(); ++ix) {
			GroupWriter gwp( ofs, keyProfile, tabs_);
			writeProfile( ofs, *(settings_.profiles_[ix].get()) );
		}
	}
	{
		GroupWriter gwrs( ofs, keyRules, tabs_);
		for( unsigned int ix = 0; ix < settings_.rules_.size(); ++ix) {
			GroupWriter gwr( ofs, keyRule, tabs_);
			writeRule( ofs, *(settings_.rules_[ix].get()) );
		}
	}
	{
		GroupWriter gwcs( ofs, keyConditions, tabs_);
		for( unsigned int ix = 0; ix < settings_.conditions_.size(); ++ix) {
			GroupWriter gwc( ofs, keyCondition, tabs_);
			writeCondition( ofs, *(settings_.conditions_[ix].get()) );
		}
	}
}

#if 0
void SettingsWriter::writeProfile( std::ofstream& fs, const Profile& prof )
{
	writeEntry( fs, keyUuid, toUTF8( getHex( prof.getId())), tabs_);
	writeEntry( fs, keyName, toUTF8( prof.getName()), tabs_);
	writeEntry( fs, keyComment, toUTF8( prof.getComment()), tabs_);
	for( unsigned int i = 0; i < prof.getRuleCount(); ++i) {
		writeEntry( fs, keyRuleId, toUTF8( getHex( prof.getRule(i))), tabs_);
	}
}

void SettingsWriter::exportProfile( const Profile& prof, const std::wstring& file)
{
	std::ofstream ofs( file.c_str());
	writeHeader( ofs);
	GroupWriter gwax( ofs, keyAxaio1, tabs_);
	{
		GroupWriter gwps( ofs, keyProfiles, tabs_);
		{
			GroupWriter gwp( ofs, keyProfile, tabs_);
			writeProfile( ofs, prof);
		}
	}
	{
		GroupWriter gwrs( ofs, keyRules, tabs_);
		for( unsigned int i = 0; i < prof.getRuleCount(); ++i) {
			GroupWriter gwr( ofs, keyRule, tabs_);
			const Rule* rl = settings_.getRule(prof.getRule(i));
			if( rl) {
				writeRule( ofs, *rl );
			}
		}
	}
	{
		GroupWriter gwcs( ofs, keyConditions, tabs_);
		for( unsigned int i = 0; i < prof.getRuleCount(); ++i) {
			const Rule* rl = settings_.getRule(prof.getRule(i));
			if( rl) {
				for( unsigned int c = 0; c < rl->getConditionCount(); ++c) {
					GroupWriter gwc( ofs, keyCondition, tabs_);
					const Condition* cd = settings_.getCondition( rl->getCondition(c));
					if( cd) {
						writeCondition( ofs, *cd );
					}
				}
			}
		}
	}
}

bool SettingsWriter::importProfile( const std::wstring& file)
{
	std::ifstream ifs( file.c_str());
	std::string content;
	while( ifs.good()) {
		std::string str;
		std::getline( ifs, str);
		content += str;
	}
	readHeader( content);
	std::wstring wcontent( (wxString::FromUTF8( content.c_str(), content.size())).c_str());
	TParentPath parentPath;
	OskarParser parser( wcontent, settings_, parentPath);
	parser.parse();
	return parser.good() && parser.hasModified();
}

void SettingsWriter::writeRule( std::ofstream& fs, const Rule& rule )
{
	writeEntry( fs, keyUuid, toUTF8( getHex( rule.getId())), tabs_);
	writeEntry( fs, keyName, toUTF8( rule.getName()), tabs_);
	writeEntry( fs, keyComment, toUTF8( rule.getComment()), tabs_);
	writeEntry( fs, keyViewType, toUTF8( getNumString( rule.getViewType())), tabs_);
	for( unsigned int i = 0; i < rule.getConditionCount(); ++i) {
		writeEntry( fs, keyConditionId, toUTF8( getHex( rule.getCondition(i))), tabs_);
	}
}

void SettingsWriter::writeCondition( std::ofstream& fs, const Condition& cond )
{
	writeEntry( fs, keyUuid, toUTF8( getHex( cond.getId())), tabs_);
	writeEntry( fs, keyViewType, toUTF8( getNumString( cond.getViewType())), tabs_);
	writeEntry( fs, keyPropertyType, toUTF8( getNumString( cond.getPropertyType())), tabs_);
	writeEntry( fs, keyPropertyName, cond.getPropertyName(), tabs_);
	writeEntry( fs, keyPropertyOpType, toUTF8( getNumString( cond.getOperatorType())), tabs_);
	writeEntry( fs, keyPropertyOperator, toUTF8( getNumString( cond.getOperator())), tabs_);
	writeEntry( fs, keyPropertyValue, toUTF8( cond.getValue()), tabs_);
}
#endif // 0

bool SettingsWriter::read( const std::wstring& file)
{
	std::ifstream ifs( file.c_str());
	std::string content;
	while( ifs.good()) {
		std::string str;
		std::getline( ifs, str);
		content += str;
	}
	readHeader( content);
	std::wstring wcontent( (wxString::FromUTF8( content.c_str(), content.size())).c_str());
	TParentPath parentPath;
	OskarParser parser( wcontent, settings_, parentPath);
	parser.parse();
	return parser.good();
}


//========================================================================================

OskarParser::OskarParser( std::wstring& content,
						  TParentPath& path )
: path_(path),content_(content),error_(false),modified_(false)
{
}

void OskarParser::parse()
{
	modified_ = false;
	std::wstring::size_type lt = content_.find( ch_lt);
	if( lt == std::string::npos || lt > content_.size() - 2) {
		error_ = true;
		content_.erase();
		return;
	}
	if( content_[lt + 1] == ch_endtag) {
		// here comes a value
		saveValue( path_, content_.substr( 0, lt));
		content_.erase( 0, lt);
	}
	else {
		std::wstring::size_type gt = content_.find( ch_gt, lt);
		wxASSERT( gt != std::wstring::npos);
		if( gt == std::wstring::npos) {
			error_ = true;
			content_.erase();
			return;
		}
		tag_ = content_.substr( lt + 1, gt - lt - 1);
		std::string tag8( wxString( tag_).mb_str( wxConvLocal));
		//const char* mb_str(wxMBConv& conv) // wxConvLocal
		path_.push_back( tag8);
		handleTag( tag8, true);
		content_.erase( 0, gt + 1);

		std::wstring endTag;
		int loopCount = 1000;
		std::wstring::size_type gt2 = std::wstring::npos;

		do {
			OskarParser parser( content_, settings_, path_);
			parser.parse();
			if( parser.modified_) {
				modified_ = true;
			}

			std::wstring::size_type lt2 = content_.find( ch_lt);
			wxASSERT( lt2 != std::wstring::npos);
			gt2 = content_.find( ch_gt, lt2);
			wxASSERT( gt2 != std::wstring::npos);
			if( lt2 == std::wstring::npos || gt2 == std::wstring::npos) {
				error_ = true;
				content_.erase();
				return;
			}

			if( content_[lt2 + 1] == ch_endtag) {
				endTag = content_.substr( lt2 + 2, gt2 - lt2 - 2);
				break;
			}

		} while( --loopCount);

		path_.pop_back();
		handleTag( tag8, false);
		wxASSERT( endTag == tag_);
		if( endTag != tag_) {
			error_ = true;
			content_.erase();
			return;
		}
		content_.erase( 0, gt2 + 1);
	}
}

void OskarParser::saveValue( const TParentPath& path, const std::wstring& value)
{
	if( path.size() == 4) {
		if( path[0] == std::string( keyAxaio1)) {
			if( path[1] == std::string( keyProfiles)) {
				if( path[2] == std::string( keyProfile)) {
					if( path[3] == std::string( keyUuid)) {
						PrefsUuid id = getUuidFromString( value);
						wxASSERT( id.valid());
						if( !id.valid()) {
							error_ = true;
							return;
						}
						//if( settings_.getProfile( id) != NULL) return;
						profile_ = new Profile( static_cast<const ProfileUuid&>(id));
						return;
					}
					else if( path[3] == std::string( keyName)) {
						wxASSERT( profile_);
						if( profile_ == NULL) {
							error_ = true;
							return;
						}
						profile_->setName( fromXML(value) );
						return;
					}
					else if( path[3] == std::string( keyComment)) {
						wxASSERT( profile_);
						if( profile_ == NULL) {
							error_ = true;
							return;
						}
						profile_->setComment( fromXML(value) );
						return;
					}
					else if( path[3] == std::string( keyRuleId)) {
						wxASSERT( profile_);
						if( profile_ == NULL) {
							error_ = true;
							return;
						}
						PrefsUuid id = getUuidFromString( value);
						wxASSERT( id.valid());
						if( !id.valid()) {
							error_ = true;
							return;
						}
						profile_->addRule( static_cast<const RuleUuid&>(id));
						return;
					}
				}
			}
			else if( path[1] == std::string( keyRules)) {
				if( path[2] == std::string( keyRule)) {
					if( path[3] == std::string( keyUuid)) {
						PrefsUuid id = getUuidFromString( value);
						wxASSERT( id.valid());
						if( !id.valid()) {
							error_ = true;
							return;
						}
						rule_ = new Rule( static_cast<const RuleUuid&>(id));
						return;
					}
					else if( path[3] == std::string( keyName)) {
						wxASSERT( rule_);
						if( rule_ == NULL) {
							error_ = true;
							return;
						}
						rule_->setName( fromXML(value));
						return;
					}
					else if( path[3] == std::string( keyComment)) {
						wxASSERT( rule_);
						if( rule_ == NULL) {
							error_ = true;
							return;
						}
						rule_->setComment( fromXML(value));
						return;
					}
					else if( path[3] == std::string( keyViewType)) {
						wxASSERT( rule_);
						if( rule_ == NULL) {
							error_ = true;
							return;
						}
						rule_->setViewType( (EViewTypeEntries)getLongFromString( value), true);
						return;
					}
					else if( path[3] == std::string( keyConditionId)) {
						wxASSERT( rule_);
						if( rule_ == NULL) {
							error_ = true;
							return;
						}
						PrefsUuid id = getUuidFromString( value);
						wxASSERT( id.valid());
						if( !id.valid()) {
							error_ = true;
							return;
						}
						rule_->addCondition( static_cast<const ConditionUuid&>(id));
						return;
					}
				}
			}
			else if( path[1] == std::string( keyConditions)) {
				if( path[2] == std::string( keyCondition)) {
					if( path[3] == std::string( keyUuid)) {
						PrefsUuid id = getUuidFromString( value);
						wxASSERT( id.valid());
						if( !id.valid()) {
							error_ = true;
							return;
						}
						condition_ = new Condition( static_cast<const ConditionUuid&>(id));
						return;
					}
					else if( path[3] == std::string( keyViewType)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						condition_->setViewType( (EViewTypeEntries)getLongFromString( value));
						return;
					}
					else if( path[3] == std::string( keyPropertyType)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						condition_->setPropertyType( (EPropertyType)getLongFromString( value));
						return;
					}
					else if( path[3] == std::string( keyPropertyName)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						std::string v8( wxString( value).mb_str( wxConvLocal));
						condition_->setPropertyName( CheckWithOpType( v8, eOpTypeUnknown));
						return;
					}
					else if( path[3] == std::string( keyPropertyValue)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						condition_->setValue( value);
						return;
					}
					else if( path[3] == std::string( keyPropertyOpType)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						condition_->setOperatorType( (EOpType)getLongFromString( value));
						return;
					}
					else if( path[3] == std::string( keyPropertyOperator)) {
						wxASSERT( condition_);
						if( condition_ == NULL) {
							error_ = true;
							return;
						}
						condition_->setOperatorValue( getLongFromString( value));
						return;
					}
				}
			}
		}
	}
	wxASSERT( false);
	error_ = true;
	content_.erase();
}

void OskarParser::handleTag( const std::string& tag, bool open)
{
	if( tag == keyAxaio1) {
		profile_ = NULL;
		rule_ = NULL;
		condition_ = NULL;
	}
	if( open) {
		if( tag == keyProfile) {
			//delete profile_; // no deletion, smart ptr
			profile_ = NULL;
		}
		else if( tag == keyRule) {
			//delete rule_;
			rule_ = NULL;
		}
		else if( tag == keyCondition) {
			//delete condition_;
			condition_ = NULL;
		}
	}
	else { // closing tag
		if( tag == keyProfile 
			&& profile_ != NULL 
			&& settings_.getProfile( profile_->getId()) == NULL)
		{
			settings_.addProfile( TProfilePtr( profile_));
			modified_ = true;
		}
		else if( tag == keyRule 
			&& rule_ != NULL 
			&& settings_.getRule( rule_->getId()) == NULL)
		{
			settings_.addRule( TRulePtr( rule_));
			modified_ = true;
		}
		else if( tag == keyCondition 
			&& condition_ != NULL 
			&& settings_.getCondition( condition_->getId()) == NULL)
		{
			settings_.addCondition( TConditionPtr( condition_));
			modified_ = true;
		}
	}
}


bool OskarParser::good()
{
	return !error_;
}

//========================================================================================
/*! \history

WGo-2008-02-07: created

*/
