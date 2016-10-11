//-----------------------------------------------------------------------------
/*!
**	\file	Utilities.h
**
*/
//-----------------------------------------------------------------------------

#ifndef WG_UTILITIES_H_
#define WG_UTILITIES_H_

//-----------------------------------------------------------------------------

// Project headers


// std headers
#include <string>

//-----------------------------------------------------------------------------

class wxFileName;

namespace wgfc
{

	class ExifInfo {
	public:
		
		ExifInfo (const std::string &imgfile);

		void readInfo();

		std::string  getInfoString() const;
		
		//std::wstring  getFile() const { return file_; }
		std::string  getCModel() const;
		std::string  getCMake() const;
		std::string  getVersion() const;
		std::string  getLensModel() const;
		std::string  getDate() const;
		std::string  getModDate() const;
		std::string  getOrientation() const;
		std::string  getExposure() const;
		std::string  getFNumber() const;
		std::string  getSensitivity() const;
		std::string  getFocal() const;
		std::string  getFocal35() const;
		std::string  getProgram() const;
		std::string  getFlashUsed() const;
		std::string  getMetering() const;
		std::string  getWhiteBalance() const;
		std::string  getBias() const;
		std::string  getCSpace() const;
		std::string  getExpomode() const;
		std::string  getLightsource() const;

	private:
		
		std::string          file_;
		std::string          cmodel_;
		std::string          cmake_;
		std::string          creator_version_;
		std::string          lensmodel_;
		std::string          date_;
		std::string          moddate_;
		std::string          orientation_;
		std::string          exposure_;
		std::string          fnumber_;
		std::string          sensitivity_;
		std::string          focal_;
		std::string          focal35_;
		std::string          program_;
		std::string          flashused_;
		std::string          metering_;
		std::string          whitebalance_;
		std::string          bias_;
		std::string          cspace_;
		std::string          expomode_;
		std::string          lightsource_;
		
	};
	
	void ConvertToAscii (bool isCString, bool isBreak, bool isSpace, const std::string path);
	void ConvertFromAscii (const std::string &path, const std::string &newpath);
	
	std::string GetDirectoryInfo (const wxFileName &dir);

} // namespace wgfc


namespace OSXFileAttributes {
	
	std::string getFileCreationDate (const std::string &u8str);
	
};


//-----------------------------------------------------------------------------

#endif // WG_UTILITIES_H_

