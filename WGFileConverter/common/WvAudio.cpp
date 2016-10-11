//-----------------------------------------------------------------------------
/*!
**	\file	Pascal/_Imp/PascalIniFile.cpp
**
**	\author	(C) 2005 callas software gmbh
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "WvAudio.h"


#include "wx/wx.h"
#include "wx/filesys.h"

// Project includes
#include "AudioDevice.h"
#include "PublicUtility/CARingBuffer.h"
#include "PublicUtility/CAStreamBasicDescription.h"


// std headers
#include <fstream>
#include <string>
#include <sstream>
#include <stdlib.h>
#include <vector>


#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>

#include <AudioUnit/AudioComponent.h>
#include <AudioUnit/AUComponent.h>
#include <AudioUnit/AudioOutputUnit.h>
#include <AudioUnit/AudioUnitProperties.h>
//#include <AudioUnit/AudioUnit.h>  // contains the obove
#include <CoreAudio/AudioHardware.h>

//#include <AudioToolbox/AudioToolbox.h>
//#include <AudioToolbox/ExtendedAudioFile.h>


//------------------------------------------------------------------------------

using namespace Wview;

//------------------------------------------------------------------------------

//const std::string     Wview::kSettingsSection("GLOBAL SETTINGS VALUES");
//const char* const     Wview::sStartDelayKey = "StartDelayValue";


namespace {

	//const wchar_t* inifile_  = L"WebViewIniFile.txt";
	
	AudioDeviceID					mID;
	bool							mIsInput;
	UInt32							mSafetyOffset;
	UInt32							mBufferSizeFrames;
	AudioStreamBasicDescription		mFormat;
	
	AudioUnit                       InputUnit;
	AudioUnit                       OutputUnit;

	
	
	class AudioDeviceList {
	public:
		struct Device {
			char			mName[64];
			AudioDeviceID	mID;
		};
		typedef std::vector<Device> DeviceList;
		
		AudioDeviceList(bool inputs);
		
		DeviceList &GetList() { return mDevices; }
		
	protected:
		void		BuildList();
		//void		EraseList();
		
		bool				mInputs;
		DeviceList			mDevices;
		
	};


}

//------------------------------------------------------------------------------

bool Wview::AudioConnect()
{
	AudioComponent comp;
	AudioComponentDescription desc;
	AudioComponentInstance auHAL;
	
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_HALOutput;
	
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
	
    comp = AudioComponentFindNext(NULL, &desc);
    if (comp == NULL) {
		return false;
	}
    //AudioComponentInstanceNew(comp, &auHAL);
	//AudioComponentInstanceDispose
	
	AudioDeviceList inputlist (true);
	AudioDeviceList outputlist (false);
	
	//AudioConvertHostTimeToNanos // CoreAudio/HostTime.h
	//ExtAudioFileCreateNew // AudioToolbox/ExtendedAudioFile.h
	
	//---
	
#if 0
	
	UInt32 enableIO;
	UInt32 size=0;
	
	enableIO = 1;
	AudioUnitSetProperty(InputUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // input element
						 &enableIO,
						 sizeof(enableIO));
	
	enableIO = 0;
	AudioUnitSetProperty(InputUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Output,
						 0,   //output element
						 &enableIO,
						 sizeof(enableIO));
	
	//---
	//OSStatus SetDefaultInputDeviceAsCurrent()
	
    OSStatus err = noErr;
    size = sizeof(AudioDeviceID);
    AudioDeviceID inputDevice;
    AudioDeviceID outputDevice;

    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
								   &size,
								   &inputDevice);

    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
								   &size,
								   &outputDevice);
	
	// see => AudioObjectGetPropertyData()
	
    if (err)
        return false;
	
    err =AudioUnitSetProperty(InputUnit,
							  kAudioOutputUnitProperty_CurrentDevice,
							  kAudioUnitScope_Global,
							  0,
							  &inputDevice,
							  sizeof(inputDevice));
	
    if (err)
        return false;

	//---
	// Setting up the desired 'input' format
	
	CAStreamBasicDescription DeviceFormat;
    CAStreamBasicDescription DesiredFormat;
	
    size = sizeof(CAStreamBasicDescription);
	
    AudioUnitGetProperty (InputUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Input,
						  1,
						  &DeviceFormat,
						  &size);
	
    DesiredFormat.mSampleRate =  DeviceFormat.mSampleRate;
	
    AudioUnitSetProperty(InputUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,
						 1,
						 &DesiredFormat,
						 sizeof(CAStreamBasicDescription));
	
	//---
#endif // 0
	
	return true;
}

//---------------------------------

bool Wview::AudioRecord()
{
	return true;
}

//---------------------------------

OSStatus Wview::InitAndStartAUHAL()
{
	OSStatus err= noErr;
	
	err = AudioUnitInitialize(InputUnit);
	if(err)
		return err;
	
	//AudioUnitUninitialize (AudioUnit inUnit) // i.e. needed to change parameter
	
	err = AudioOutputUnitStart(InputUnit);
	
	return err;
}

//The AUHAL is an Audio Unit that can receive and send audio data to an audio device. To receive audio from the AUHAL, you must get it from the output scope of the Audio Unit. In practice, this is done by a client calling AudioUnitRender. To give audio to the AUHAL, you must give it data on the input scope. This is done by providing an input callback to the Audio Unit.

//In our example, we will call AudioUnitRender from within the input proc. The input proc's render action flags, time stamp, bus number and number of frames requested should be propagated down to the AudioUnitRender call. The AudioBufferList, ioData will be NULL, therefore you must provide your own allocated AudioBufferList

namespace {
	
	AudioBufferList * theBufferList;
	
	OSStatus InputProc(void *inRefCon,
					   AudioUnitRenderActionFlags *ioActionFlags,
					   const AudioTimeStamp *inTimeStamp,
					   UInt32 inBusNumber,
					   UInt32 inNumberFrames,
					   AudioBufferList * ioData)
	{
		OSStatus err =noErr;
		
		err= AudioUnitRender(InputUnit,
							 ioActionFlags,
							 inTimeStamp,
							 inBusNumber,     //will be '1' for input data
							 inNumberFrames, //# of frames requested
							 theBufferList);
		
		return err;
	}
	
}

void MyInputCallbackSetup()
{
    AURenderCallbackStruct input;
    input.inputProc = InputProc;
    input.inputProcRefCon = 0;
	
    AudioUnitSetProperty(InputUnit,
						 kAudioOutputUnitProperty_SetInputCallback,
						 kAudioUnitScope_Global,
						 0,
						 &input,
						 sizeof(input));
}


//===============================================

#if 0

extern OSStatus
AudioUnitGetProperty(				AudioUnit				inUnit,
					 AudioUnitPropertyID		inID,
					 AudioUnitScope			inScope,
					 AudioUnitElement		inElement,
					 void *					outData,
					 UInt32 *				ioDataSize)


extern OSStatus
AudioUnitSetProperty(				AudioUnit				inUnit,
					 AudioUnitPropertyID		inID,
					 AudioUnitScope			inScope,
					 AudioUnitElement		inElement,
					 const void *			inData,
					 UInt32					inDataSize)

extern OSStatus
AudioObjectGetPropertyData( AudioObjectID                       inObjectID,
						   const AudioObjectPropertyAddress*   inAddress,
						   UInt32                              inQualifierDataSize,
						   const void*                         inQualifierData,
						   UInt32*                             ioDataSize,
						   void*                               outData)

struct  AudioObjectPropertyAddress
{
    AudioObjectPropertySelector mSelector;
    AudioObjectPropertyScope    mScope;
    AudioObjectPropertyElement  mElement;
};

// AudioUnit/AudioComponent.h
extern OSStatus
AudioComponentInstanceNew(      AudioComponent                  inComponent,
						  AudioComponentInstance *        outInstance)

extern AudioComponent
AudioComponentRegister(     const AudioComponentDescription *   inDesc,
					   CFStringRef                         inName,
					   UInt32                              inVersion,
					   AudioComponentFactoryFunction       inFactory)
#endif

//===============================================

AudioDeviceList::AudioDeviceList(bool inputs) :
mInputs(inputs)
{
	BuildList();
}

void AudioDeviceList::BuildList()
{
	mDevices.clear();
	
	UInt32 propsize;
    
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };
	
	verify_noerr(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &theAddress, 0, NULL, &propsize));
	int nDevices = propsize / sizeof(AudioDeviceID);
	AudioDeviceID *devids = new AudioDeviceID[nDevices];
    verify_noerr(AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &propsize, devids));
	
	for (int i = 0; i < nDevices; ++i) {
		AudioDevice dev(devids[i], mInputs);
		if (dev.CountChannels() > 0) {
			Device d;
			
			d.mID = devids[i];
			dev.GetName(d.mName, sizeof(d.mName));
			mDevices.push_back(d);
		}
	}
	delete[] devids;
}

//------------------------------------------------------------------------------

