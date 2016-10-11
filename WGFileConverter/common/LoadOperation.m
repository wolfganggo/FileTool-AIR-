/*
     File: LoadOperation.m 
 Abstract: NSOperation code for examining image files.
  
  Version: 1.3 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "LoadOperation.h"

// key for obtaining the current scan count
NSString *kScanCountKey = @"scanCount";

// key for obtaining the path of an image fiel
NSString *kPathKey = @"path";

// key for obtaining the size of an image file
NSString *kSizeKey = @"size";

// key for obtaining the name of an image file
NSString *kNameKey = @"name";

// key for obtaining the mod date of an image file
NSString *kModifiedKey = @"modified";

// NSNotification name to tell the Window controller an image file as found
NSString *kLoadImageDidFinish = @"LoadImageDidFinish";

@interface LoadOperation ()
{
    NSURL *loadURL;
    NSInteger ourScanCount;
	NSString cdate;
}

@property (retain) NSURL *loadURL;

@end


@implementation LoadOperation

@synthesize loadURL;

// -------------------------------------------------------------------------------
//	initWithPath:path
// -------------------------------------------------------------------------------
- (id)initWithURL:(NSURL *)url
{
	self = [super init];
    if (self)
    {
        self.loadURL = url;
        ourScanCount = scanCount;

		// in this example, we just get the file's info (mod date, file size) and report it to the table view
		//
		NSNumber *fileSize;
		[self.loadURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
		
		NSDate *fileCreationDate;
		[self.loadURL getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
		
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		NSString *modDateStr = [formatter stringFromDate:fileCreationDate];
		cdate = *modDateStr;
    }
    return self;
}

- (NSString)getCreationDate
{
	return cdate;
}


@end
