//-----------------------------------------------------------------------------
/*!
**	\file	Utilities.cpp
**
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "Utilities.h"


#include "wx/wx.h"
#include "wx/filesys.h"
#include "wx/stdpaths.h"
#include "wx/dir.h"
#include "wx/filefn.h"
#include "wx/filename.h"

// std headers
#include <fstream>
#include <string>
#include <sstream>
#include <stdlib.h>


//------------------------------------------------------------------------------

using namespace wgfc;

//------------------------------------------------------------------------------


namespace {
	
	typedef std::vector<unsigned int>  TRecord;
	typedef std::vector<std::string>   TStringVec;

	const unsigned int make_id = 0x010f;
	const unsigned int model_id = 0x0110;
	const unsigned int orient_id = 0x0112;
	const unsigned int version_id = 0x0131;
	const unsigned int moddate_id = 0x0132;  // used by PhotoShop
	const unsigned int date_id = 0x9003;   // original
	//const unsigned int date_id = 0x9004; // digitized
	const unsigned int exposure_id = 0x829a;
	const unsigned int fnum_id = 0x829d;
	const unsigned int sens_id = 0x8827;
	const unsigned int iso_id = 0x8833;
	const unsigned int flash_id = 0x9209;
	const unsigned int focal_id = 0x920a;
	const unsigned int focal35_id = 0xa405;
	const unsigned int program_id = 0x8822;
	//const unsigned int lensmake_id = 0xa433;
	const unsigned int lensmodel_id = 0xa434;
	const unsigned int metering_id = 0x9207;
	const unsigned int whitebal_id = 0xA403;
	const unsigned int bias_id = 0x9204;
	const unsigned int cspace_id = 0xA001;
	const unsigned int expomode_id = 0xA402;
	const unsigned int lightsource_id = 0x9208;
	
	const unsigned int lensmodel2_id = 0x0051;
	//51 00 02 00 22 00   ..........Q...". // found in image from GH1, length is really 29 incl. closing '\0'
	//001840  00 00 b0 20 00 00 

	wxULongLong infoFileSize_ = 0;
	int infoFileCount_ = 0;
	int infoDirCount_ = 0;

	
	
	int findIndex (const TRecord &record, unsigned int value, int startpos)
	{
		for (int ix = startpos; ix < record.size(); ++ix) {
			if (record[ix] == value) {
				return ix;
			}
		}
		return -1;
	}
	
	std::string getFixed (float f, int count)
	{
		wxString ws = wxString::FromDouble (f, count);
		return ws.ToStdString();
	}
	
	std::string getIntString (int i)
	{
		wxString ws;
		ws << i;
		return ws.ToStdString();
	}
	
	bool getExifValueFromString (const TRecord &record, unsigned int id, bool littleEnd, std::string &value)
	{
		value.erase();
		int pos = -1;
		do {
			pos = findIndex (record, id, pos + 1);
			if (pos >= 0) {
				if (record[pos + 1] == 2) {
					int valuesize = 0;
					if (littleEnd) {
						valuesize = record[pos + 2] + record[pos + 3] * 65536;
					}
					else {
						valuesize = record[pos + 2] * 65536 + record[pos + 3];
					}
					if (valuesize > 0) {
						valuesize -= 1;
					}
					if (valuesize < 1000) {
						int offs = 0;
						if (littleEnd) {
							offs = record[pos + 4] + record[pos + 5] * 65536;
						}
						else {
							offs = record[pos + 4] * 65536 + record[pos + 5];
						}
						char c;
						int savedcount = 0;
						for (int ix = offs / 2; ix < record.size(); ++ix) {
							if (littleEnd) {
								c = (char)(record[ix] % 256); // second byte at first
								if (c == 0) break;
								value += c;
								if (++savedcount >= valuesize) break;
								c = (char)(record[ix] / 256);
								if (c == 0) break;
								value += c;
								if (++savedcount >= valuesize) break;
							}
							else {
								c = (char)(record[ix] / 256);
								if (c == 0) break;
								value += c;
								if (++savedcount >= valuesize) break;
								c = (char)(record[ix] % 256);
								if (c == 0) break;
								value += c;
								if (++savedcount >= valuesize) break;
							}
						}
						return true;
					}
				}
			}
		} while(pos >= 0);
		return false;
	}
	
	bool getExifValueFromShort (const TRecord &record, unsigned int id, bool littleEnd, int &value)
	{
		int pos = -1;
		do {
			pos = findIndex (record, id, pos + 1);
			if (pos >= 0) {
				if (record[pos + 1] == 3) {
					int valuesize = 0;
					if (littleEnd) {
						valuesize = record[pos + 2] + record[pos + 3] * 65536;
					}
					else {
						valuesize = record[pos + 2] * 65536 + record[pos + 3];
					}
					if (valuesize == 1) {
						value = record[pos + 4];
						return true;
					}
				}
			}
		} while(pos >= 0);
		return false;
	}
	
	bool getExifValueFromLong (const TRecord &record, unsigned int id, bool littleEnd, int &value)
	{
		int pos = -1;
		do {
			pos = findIndex (record, id, pos + 1);
			if (pos >= 0) {
				if (record[pos + 1] == 4 || record[pos + 1] == 9) {
					int valuesize = 0;
					if (littleEnd) {
						valuesize = record[pos + 2] + record[pos + 3] * 65536;
					}
					else {
						valuesize = record[pos + 2] * 65536 + record[pos + 3];
					}
					if (valuesize == 1) {
						if (littleEnd) {
							value = record[pos + 4] + record[pos + 5] * 65536;
						}
						else {
							value = record[pos + 4] * 65536 + record[pos + 5];
						}
						return true;
					}
				}
			}
		} while(pos >= 0);
		return false;
	}
	
	bool getExifValueFromRational (const TRecord &record, unsigned int id, bool littleEnd, TStringVec &value)
	{
		int pos = -1;
		std::string entry;
		value.clear();
		do {
			pos = findIndex (record, id, pos + 1);
			if (pos >= 0) {
				int is_signed = -1;
				if (record[pos + 1] == 5) {
					is_signed = 0;
				}
				else if (record[pos + 1] == 10) {
					is_signed = 1;
				}
				if (is_signed >= 0) {
					int valuesize = 0;
					if (littleEnd) {
						valuesize = record[pos + 2] + record[pos + 3] * 65536;
					}
					else {
						valuesize = record[pos + 2] * 65536 + record[pos + 3];
					}
					if (valuesize == 1) {
						int offs = 0;
						if (littleEnd) {
							offs = record[pos + 4] + record[pos + 5] * 65536;
						}
						else {
							offs = record[pos + 4] * 65536 + record[pos + 5];
						}
						
						int ix = offs / 2;
						float n1 = 0.0;
						float n2 = 0.0;
						if (is_signed) {
							int ras1 = 0; 
							int ras2 = 0; 
							if (littleEnd) {
								ras1 = (int)record[ix] + ((int)record[ix + 1] << 16);
								ras2 = (int)record[ix + 2] + ((int)record[ix + 3] << 16);
							}
							else {
								ras1 = ((int)record[ix] << 16) + (int)record[ix + 1];
								ras2 = ((int)record[ix + 2] << 16) + (int)record[ix + 3];
							}
							if (ras2 != 0) {
								n1 = (float)ras1/(float)ras2;
								entry = getFixed (n1, 2);
							}
							value.push_back (entry);
							//value.kStr4 = (ras1/ras2).toFixed(2); // exp. bias
							if (ras1 < ras2 && ras1 != 0) { // else use existing value for 2nd entry
								n2 = (float)ras2/(float)ras1;
								if (n2 < 3) {
									entry = std::string("1/") + getFixed(n2, 2);
								}
								else {
									entry = std::string("1/") + getFixed(n2, 0);
								}
							}
							value.push_back (entry);
							entry = getFixed (n1, 0);
							value.push_back (entry);
							entry = getFixed (n1, 1);
							value.push_back (entry);
						}
						else {
							unsigned int ra1 = 0; 
							unsigned int ra2 = 0; 
							if (littleEnd) {
								ra1 = record[ix] + (record[ix + 1] << 16);
								ra2 = record[ix + 2] + (record[ix + 3] << 16);
							}
							else {
								ra1 = (record[ix] << 16) + record[ix + 1];
								ra2 = (record[ix + 2] << 16) + record[ix + 3];
							}
							if (ra2 != 0) {
								n1 = (float)ra1/(float)ra2;
								entry = getFixed (n1, 2);
							}
							value.push_back (entry);
							if (ra1 < ra2 && ra1 != 0) { // else use existing value for 2nd entry (exp. time)
								n2 = (float)ra2/(float)ra1;
								if (n2 < 3) {
									entry = std::string("1/") + getFixed(n2, 2);
								}
								else {
									entry = std::string("1/") + getFixed(n2, 0); // exp. time
								}
							}
							value.push_back (entry);
							entry = getFixed (n1, 0); // focal length
							value.push_back (entry);
							entry = getFixed (n1, 1); // F number
							value.push_back (entry);
						}
						return true;
					}
				}
			}
		} while(pos >= 0);
		return false;
	}
	
	std::string ByteToString (int byte)
	{
		unsigned int ub = (unsigned int)byte;
		if (ub > 255) {
			return "";
		}
		std::string retstr;
		int l = ub % 16;
		int h = ub / 16;
		if (h < 10) {
			retstr += '0' + h;
		}
		else {
			retstr += 'a' + (h - 10);
		}
		if (l < 10) {
			retstr += '0' + l;
		}
		else {
			retstr += 'a' + (l - 10);
		}
		return retstr;
	}

	unsigned int getByteFromHex (unsigned int b1, unsigned int b2)
	{
		unsigned int bt = 0;
		if (b2 > 47 && b2 < 58) {
			bt = b2 - 48;
		}
		else if (b2 > 64 && b2 < 71) {
			bt = b2 - 55;
		}
		else if (b2 > 96 && b2 < 103) {
			bt = b2 - 87;
		}
		
		if (b1 > 47 && b1 < 58) {
			bt += (b1 - 48) * 16;
		}
		else if (b1 > 64 && b1 < 71) {
			bt += (b1 - 55) * 16;
		}
		else if (b1 > 96 && b1 < 103) {
			bt += (b1 - 87) * 16;
		}
		return bt;
	}
	
	void getInfo (const wxFileName &fname)
	{
		wxDir dir (fname.GetFullPath());
		if (dir.IsOpened()) {
			wxString tmp;
			if (dir.GetFirst (&tmp, wxEmptyString, wxDIR_DIRS | wxDIR_HIDDEN)) {
				do {
					++infoDirCount_;
					wxFileName dname (fname.GetFullPath(), tmp);
					getInfo (dname);
				} while (dir.GetNext (&tmp));
			}
			if (dir.GetFirst (&tmp, wxEmptyString, wxDIR_FILES | wxDIR_HIDDEN)) {
				do {
					++infoFileCount_;
					wxFileName filename (fname.GetFullPath(), tmp);
					wxULongLong fsize = filename.GetSize();
					if (fsize != wxInvalidSize) {
						infoFileSize_ += fsize;
					}
				} while (dir.GetNext (&tmp));
			}
		}
	}

	wxString getSizeString (wxULongLong sz)
	{
		wxString retstr;
		wxULongLong szg = sz / 1000000000;
		if (szg > 0) {
			retstr << szg << L".";
		}
		
		sz = sz % 1000000000;
		wxULongLong szm = sz / 1000000;
		if (szm > 0 || szg > 0) {
			wxString sm;
			sm << szm;
			if (!retstr.empty()) {
				if (sm.size() == 1) {
					sm.Prepend (L"00");
				}
				else if (sm.size() == 2) {
					sm.Prepend (L"0");
				}
			}
			retstr << sm << L".";
		}
		
		sz = sz % 1000000;
		wxULongLong szt = sz / 1000;
		if (szt > 0 || szm > 0 || szg > 0) {
			wxString st;
			st << szt;
			if (!retstr.empty()) {
				if (st.size() == 1) {
					st.Prepend (L"00");
				}
				else if (st.size() == 2) {
					st.Prepend (L"0");
				}
			}
			retstr << st << L".";
		}
		
		sz = sz % 1000;
		wxString se;
		se << sz;
		if (!retstr.empty()) {
			if (se.size() == 1) {
				se.Prepend (L"00");
			}
			else if (se.size() == 2) {
				se.Prepend (L"0");
			}
		}
		retstr << se << L" Bytes";
		
		return retstr;
	}
	
}

//------------------------------------------------------------------------------

ExifInfo::ExifInfo (const std::string &imgfile)
: file_(imgfile)
{
}

void ExifInfo::readInfo()
{
	std::ifstream ifs (file_.c_str(), std::ios_base::binary);
	
	int filepos = 0;
	int datapos = -1;
	int c = 0;
	int bt14 = 0;
	int bt1 = 0;
	std::string prestr;
	TRecord datarecord;
	bool littleEnd = false;
	bool firstbyte = true;
	
	while (ifs.good()) {
		//std::getline( ifs, str);
		//ifs >> c;
		c = ifs.get();
		if (filepos < 65 && datapos < 0) {
			if (c < 32 || c > 126) {
				c = 63;
			}
			prestr += c;
			std::string::size_type ixex = prestr.find("Exif");
			if (ixex != std::string::npos && ixex > 5) {
				datapos = filepos - (ixex + 3) + 9;
				//datapos = 9;
			}
		}
		if (filepos > 64 && datapos < 0) {
			break;
		}
		
		if (datapos > 11) { // byte 12 is the base for offset
			if (datapos == 14) {
				bt14 = c;
			}
			else if (datapos == 15) {
				if (bt14 == 0 && c > 0) {
					littleEnd = false;
				}
				else if (bt14 > 0 && c == 0) {
					littleEnd = true;
				}
				else {
					break;
				}
			}

			if (firstbyte) {
				bt1 = c;
				firstbyte = false;
			}
			else {
				if (littleEnd) {
					datarecord.push_back ((c << 8) + bt1);
				}
				else {
					datarecord.push_back ((bt1 << 8) + c);
				}
				firstbyte = true;
			}
		}
		if (filepos > 50000) {
			break;
		}
		++filepos;
		if (datapos >= 0) {
			++datapos;
		}
	}

	std::string sentry;
	int intvalue;
	TStringVec sentries;
	cmake_ = "Make:   ";
	if (getExifValueFromString (datarecord, make_id, littleEnd, sentry)) {
		cmake_ += sentry;
	}
	cmodel_ = "Model:   ";
	if (getExifValueFromString (datarecord, model_id, littleEnd, sentry)) {
		cmodel_ += sentry;
	}
	lensmodel_ = "Lens Model:   ";
	if (getExifValueFromString (datarecord, lensmodel_id, littleEnd, sentry)) {
		lensmodel_ += sentry;
	}
	else if (getExifValueFromString (datarecord, lensmodel2_id, littleEnd, sentry)) {
		lensmodel_ += sentry;
	}
	creator_version_ = "Creator:   ";
	if (getExifValueFromString (datarecord, version_id, littleEnd, sentry)) {
		creator_version_ += sentry;
	}
	date_ = "Date:   ";
	if (getExifValueFromString (datarecord, date_id, littleEnd, sentry)) {
		date_ += sentry;
	}
	moddate_ = "Modified Date:   ";
	if (getExifValueFromString (datarecord, moddate_id, littleEnd, sentry)) {
		moddate_ += sentry;
	}
	orientation_ = "Orientation:   ";
	if (getExifValueFromShort (datarecord, orient_id, littleEnd, intvalue)) {
		if (intvalue > 0 && intvalue < 5) {
			orientation_ += " landscape";
		}
		else if (intvalue > 4 && intvalue < 9) {
			orientation_ += " portrait";
		}
	}
	sensitivity_ = "Sensitivity:   ";
	if (getExifValueFromLong (datarecord, iso_id, littleEnd, intvalue)) {
		sensitivity_ += getIntString(intvalue);
	}
	else if (getExifValueFromShort (datarecord, sens_id, littleEnd, intvalue)) {
		sensitivity_ += getIntString(intvalue);
	}
	exposure_ = "Exposure time:   ";
	if (getExifValueFromRational (datarecord, exposure_id, littleEnd, sentries)) {
		if (sentries.size() > 1) {
			exposure_ += sentries[1];
		}
	}
	fnumber_ = "F Number:   ";
	if (getExifValueFromRational (datarecord, fnum_id, littleEnd, sentries)) {
		if (sentries.size() > 3) {
			fnumber_ += sentries[3];
		}
	}
	focal_ = "Focal length:   ";
	if (getExifValueFromRational (datarecord, focal_id, littleEnd, sentries)) {
		if (sentries.size() > 2) {
			focal_ += sentries[2];
		}
	}
	if (getExifValueFromShort (datarecord, focal35_id, littleEnd, intvalue)) {
		focal_ += " (equ " + getIntString(intvalue) + ")";
	}
	program_ = "Program:   ";
	if (getExifValueFromShort (datarecord, program_id, littleEnd, intvalue)) {
		//programstr += entry.kStr;
		if (intvalue == 0) {
			program_ += "undefined";
		}
		else if (intvalue == 1) {
			program_ += "manual";
		}
		else if (intvalue == 2) {
			program_ += "normal";
		}
		else if (intvalue == 3) {
			program_ += "aperture priority";
		}
		else if (intvalue == 4) {
			program_ += "shutter priority";
		}
		else if (intvalue == 5) {
			program_ += "creative";
		}
		else if (intvalue == 6) {
			program_ += "action";
		}
		else if (intvalue == 7) {
			program_ += "portrait";
		}
		else if (intvalue == 8) {
			program_ += "landscape";
		}
		else if (intvalue > 0) {
			program_ += "other (" + getIntString(intvalue)  + ")";
		}
	}
	if (getExifValueFromShort (datarecord, flash_id, littleEnd, intvalue)) {
		flashused_ = "Flash used:   ";
		if (intvalue % 2 > 0) { // bit 0 is set
			flashused_ += "Yes";
		}
		else {
			flashused_ += "No";
		}
	}
	metering_ = "Metering mode:   ";
	if (getExifValueFromShort (datarecord, metering_id, littleEnd, intvalue)) {
		if (intvalue == 1) {
			metering_ += "average";
		}
		else if (intvalue == 2) {
			metering_ += "center weighted average";
		}
		else if (intvalue == 3) {
			metering_ += "spot";
		}
		else if (intvalue == 4) {
			metering_ += "multi-spot";
		}
		else if (intvalue == 5) {
			metering_ += "pattern";
		}
		else if (intvalue == 6) {
			metering_ += "partial";
		}
		else {
			metering_ += "unknown";
		}
	}
	whitebalance_ = "White balance:   ";
	if (getExifValueFromShort (datarecord, whitebal_id, littleEnd, intvalue)) {
		if (intvalue == 0) {
			whitebalance_ += "auto";
		}
		else if (intvalue == 1) {
			whitebalance_ += "manual";
		}
	}
	bias_ = "Exposure bias:   ";
	if (getExifValueFromRational (datarecord, bias_id, littleEnd, sentries)) {
		if (sentries.size() > 0) {
			bias_ += sentries[0];
		}
	}
	cspace_ = "Color space:   ";
	if (getExifValueFromShort (datarecord, cspace_id, littleEnd, intvalue)) {
		if (intvalue == 1) {
			cspace_ += "sRGB";
		}
		else {
			cspace_ += "uncalibrated";
		}
	}
	expomode_ = "Exposure mode:   ";
	if (getExifValueFromShort (datarecord, expomode_id, littleEnd, intvalue)) {
		if (intvalue == 0) {
			expomode_ += "auto exposure";
		}
		else if (intvalue == 1) {
			expomode_ += "manual exposure";
		}
		else if (intvalue == 2) {
			expomode_ += "auto bracket";
		}
	}
	lightsource_ = "Light source:   ";
	if (getExifValueFromShort (datarecord, lightsource_id, littleEnd, intvalue)) {
		if (intvalue == 0) {
			lightsource_ += "auto";
		}
		else if (intvalue == 1) {
			lightsource_ += "daylight";
		}
		else if (intvalue == 2) {
			lightsource_ += "fluorescent";
		}
		else if (intvalue == 3) {
			lightsource_ += "tungsten";
		}
		else if (intvalue == 4) {
			lightsource_ += "flash";
		}
		else if (intvalue == 9) {
			lightsource_ += "fine weather";
		}
		else if (intvalue == 10) {
			lightsource_ += "cloudy weather";
		}
		else if (intvalue == 11) {
			lightsource_ += "shade";
		}
		else if (intvalue == 24) {
			lightsource_ += "ISO studio tungsten";
		}
		else {
			lightsource_ += "unknown light source";
		}
	}
}


std::string ExifInfo::getInfoString() const
{
	std::ostringstream oss;
	oss << cmodel_ << "\n" << cmake_ << "\n" << lensmodel_ << "\n" << creator_version_<< "\n"
		<< date_ << "\n" << moddate_ << "\n" << exposure_ << "\n" << fnumber_ << "\n"
		<< sensitivity_ << "\n" << focal_ << "\n" << orientation_ << "\n" << program_ << "\n" << flashused_ << "\n"
		<< metering_ << "\n" << whitebalance_ << "\n" << bias_ << "\n" << cspace_ << "\n"
		<< expomode_ << "\n" << lightsource_ << "\n";
	return oss.str();
}

std::string ExifInfo::getCModel() const
{
	return cmodel_;
}

std::string ExifInfo::getCMake() const
{
	return cmake_;
}

std::string ExifInfo::getVersion() const
{
	return creator_version_;
}

std::string ExifInfo::getLensModel() const
{
	return lensmodel_;
}

std::string ExifInfo::getDate() const
{
	return date_;
}

std::string ExifInfo::getModDate() const
{
	return moddate_;
}

std::string ExifInfo::getOrientation() const
{
	return orientation_;
}

std::string ExifInfo::getExposure() const
{
	return exposure_;
}

std::string ExifInfo::getFNumber() const
{
	return fnumber_;
}

std::string ExifInfo::getSensitivity() const
{
	return sensitivity_;
}

std::string ExifInfo::getFocal() const
{
	return focal_;
}

std::string ExifInfo::getFocal35() const
{
	return focal35_;
}

std::string ExifInfo::getProgram() const
{
	return program_;
}

std::string ExifInfo::getFlashUsed() const
{
	return flashused_;
}

std::string ExifInfo::getMetering() const
{
	return metering_;
}

std::string ExifInfo::getWhiteBalance() const
{
	return whitebalance_;
}

std::string ExifInfo::getBias() const
{
	return bias_;
}

std::string ExifInfo::getCSpace() const
{
	return cspace_;
}

std::string ExifInfo::getExpomode() const
{
	return expomode_;
}

std::string ExifInfo::getLightsource() const
{
	return lightsource_;
}



void wgfc::ConvertToAscii (bool isCString, bool isBreak, bool isSpace, const std::string path)
{
	int filepos = 0;
	const int maxpos = 100000000; // 100 MB
	int c = 0;
	std::string curLine;
	std::string newpath = path + ".binhex";
	std::ifstream ifs (path.c_str(), std::ios_base::binary);
	std::ofstream ofs (newpath.c_str());
	if (!ofs.good()) {
		return;
	}
	if (isCString) {
		ofs << "{\n";
	}
	
	while (ifs.good()) {
		c = ifs.get();
		std::string sbt = ByteToString (c);

		if (isSpace) {
			curLine += " ";
		}
		curLine += sbt;

		if (++filepos > maxpos) {
			break;
		}

		if (filepos % 8 == 0 && isSpace) {
			curLine += " ";
		}
		if (filepos % 48 == 0) {
			if (isCString) {
				curLine = std::string("\"") + curLine + "\",\n";
			}
			else if (isBreak) {
				curLine += "\n";
			}
			ofs << curLine.c_str();
			curLine.erase();
		}
	}
	if (curLine.size() > 0) {
		if (isCString) {
			curLine = std::string("\"") + curLine + "\",\n";
		}
		ofs << curLine.c_str();
	}
	if (isCString) {
		ofs << "}";
	}
}

void wgfc::ConvertFromAscii (const std::string &path, const std::string &newpath)
{
	int filepos = 0;
	const int maxpos = 330000000; // 300 MB
	std::string chars;
	unsigned int char1 = 0;
	bool hasChar1 = false;
	
	std::string outpath = newpath;
	if (outpath.empty()) {
		// file must end with ".binhex"
		if (path.size() < 10) {
			return;
		}
		outpath = path.substr (0, path.size() - 7);
	}
	std::ifstream ifs (path.c_str());
	std::ofstream ofs (outpath.c_str(), std::ios_base::binary);
	if (!ofs.good()) {
		return;
	}
	
	while (ifs.good()) {
		unsigned int b = (unsigned int)ifs.get();
		if (++filepos > maxpos) {
			break;
		}
		
		if (b < 48 || b > 102) {
			continue;
		}
		if (!hasChar1) {
			char1 = b;
			hasChar1 = true;
		}
		else {
			char newbyte = getByteFromHex (char1, b);
			ofs.put (newbyte);
			hasChar1 = false;
		}
	}
}

std::string wgfc::GetDirectoryInfo (const wxFileName &fname)
{
	infoFileSize_ = 0;
	infoFileCount_ = 0;
	infoDirCount_ = 0;
	std::string str("Directory is: ");
	wxDateTime crtm, mdtm, actm;

	wxDir dir (fname.GetFullPath());
	if (!dir.IsOpened()) {
		wxFileName fn (fname.GetFullPath());

		str = "File is: ";
		str += fname.GetFullPath().c_str() + "\n\n";
		wxDateTime crtm, mdtm, actm;
		std::string u8s = fname.GetFullPath().utf8_str().data();
		wxString crstr (OSXFileAttributes::getFileCreationDate(u8s).c_str(), wxConvUTF8);
		str += std::string("Created on: ") + crstr + "\n";
		
		if (fname.GetTimes (&actm, &mdtm, &crtm)) {
			wxString mdstr = mdtm.Format ("%a %b %d %Y  %X");
			str += std::string("Modified on: ") + mdstr + "\n";
		}
		//return "";
	}
	else {
		getInfo (fname);
		str += fname.GetFullPath().c_str() + "\n\n";
		
		// sys/time.h
		//int	utimes(const char *, const struct timeval *);
		
		//#include <sys/time.h>	
		//int	futimes(int fildes, const struct timeval times[2]);
		//int	utimes(const char *path, const struct timeval times[2]);
		
		std::string u8s = fname.GetFullPath().utf8_str().data();
		wxString crstr (OSXFileAttributes::getFileCreationDate(u8s).c_str(), wxConvUTF8);
		str += std::string("Created on: ") + crstr + "\n";
		
		if (fname.GetTimes (&actm, &mdtm, &crtm)) {
			wxString mdstr = mdtm.Format ("%a %b %d %Y  %X");
			str += std::string("Modified on: ") + mdstr + "\n";
		}
		wxString sizestr;
		sizestr << "Total number of subdirectories: " << infoDirCount_ << "\n"
		<< "Total number of files: " << infoFileCount_ << "\n"
		<< "Total size: " << getSizeString(infoFileSize_) << "\n";
		str += sizestr.c_str();
	}
	

	return str;
}


//------------------------------------------------------------------------------

