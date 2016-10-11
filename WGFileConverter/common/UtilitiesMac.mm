//-----------------------------------------------------------------------------
/*!
**	\file	Auto/_Imp/AutoMacHelper.mm
**
**	\author	Wolfgang Goldbach
*/
//-----------------------------------------------------------------------------

// own header
#include "Utilities.h"

// project includes

// std headers
//#include <iostream>

//#import "LoadOperation.h"
#import <Cocoa/Cocoa.h>

//========================================================================
// globals + statics



//========================================================================

namespace {
	
	//inline wxString wxStringWithNSString(NSString *nsstring)
	//{
	//	return wxString([nsstring UTF8String], wxConvUTF8);
	//}
	
	NSString* getNSStringFromString(const std::string &u8str)
	{
		return [NSString stringWithUTF8String: u8str.c_str()];
	}
	
	

}

//========================================================================

//OSXFileAttributes::OSXFileAttributes (const std::string &u8path)
//{
//	NSString *urlstr = getNSStringFromString(u8path);
//	NSURL *nsurl = [[NSURL alloc] initFileURLWithPath:urlstr];
//	LoadOperation *op = [[LoadOperation alloc] initWithURL:nsurl];
//}
	
std::string OSXFileAttributes::getFileCreationDate (const std::string &u8path)
{
	NSString *urlstr = getNSStringFromString(u8path);
	NSURL *nsurl = [[NSURL alloc] initFileURLWithPath:urlstr];

	
	NSDate *fileCreationDate;
	[nsurl getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
	
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:kCFDateFormatterMediumStyle];
	[formatter setDateStyle:kCFDateFormatterMediumStyle];
	NSString *crDateStr = [formatter stringFromDate:fileCreationDate];

	
	return [crDateStr UTF8String];
}


//NSDateFormatterNoStyle = kCFDateFormatterNoStyle,
//NSDateFormatterShortStyle = kCFDateFormatterShortStyle,
//NSDateFormatterMediumStyle = kCFDateFormatterMediumStyle,
//NSDateFormatterLongStyle = kCFDateFormatterLongStyle,
//NSDateFormatterFullStyle = kCFDateFormatterFullStyle


//========================================================================

#if 0
bool MacHelper::isFileOrFolderBusy (const std::wstring &path)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *fileMan = [NSFileManager defaultManager];
	if (fileMan != nil) {
		NSError *error = [NSError new];
		//NSLog(@"%d tests", [suite testCaseCount]);
		//NSLog(@"DICT: %@", dict);
		NSDictionary * dict = [fileMan attributesOfItemAtPath: getNSStringFromWString(path) error: &error];
		//BOOL isBusy = [[dict objectForKey: NSFileBusy] boolValue];
		id boolObj = [dict objectForKey: NSFileBusy];
		BOOL isBusy = NO;

		if (boolObj) {          // Object is always nil, makes no sense on UNIX-like systems
			isBusy = [boolObj boolValue];
		}

		[pool release];
		return isBusy == YES;
	}
	[pool release];
	return true;
}

double MacHelper::getModificationDate (const std::wstring &path)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *fileMan = [NSFileManager defaultManager];
	if (fileMan != nil) {
		NSError *error = [NSError new];
		//NSLog(@"%d tests", [suite testCaseCount]);
		//NSLog(@"DICT: %@", dict);
		NSDictionary * dict = [fileMan attributesOfItemAtPath: getNSStringFromWString(path) error: &error];
		NSTimeInterval time = [[dict fileModificationDate] timeIntervalSinceReferenceDate];
		
		[pool release];
		return time;
	}
	[pool release];
	return 0.0;
}
#endif // 0

//+ (NSFileManager *)defaultManager
//- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error
//NSString * const NSFileBusy;
//The corresponding value is an NSNumber object containing a Boolean value.
//NSString * const NSFileModificationDate;
//The corresponding value is an NSDate object.

//- (NSTimeInterval)timeIntervalSinceReferenceDate // 1 January 2001, GMT.
//typedef double NSTimeInterval;

//- (id)objectForKey:(id)aKey
//- (BOOL)boolValue             // YES NO

//NSAutoreleasePool     *pool;
//pool = [[NSAutoreleasePool alloc] init];
//path = [NSString stringWithUTF8String:argv[1]];
//dict = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO];

//========================================================================

/*! \history
WGo-2016-09-14: Created

*/

// eof
