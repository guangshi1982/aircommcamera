/**
 *  FAItem.h
 *
 *  Copyright (c) 2013 Toshiba Corporation. All rights reserved.
 *  Created by kitano, Fixstars Corporation on 2013/11/28.
 */

#import <Foundation/Foundation.h>
//#import "FADownloadHistoryManager.h"

@interface FAItem : NSObject
{
    NSString*      _directory;
    NSString*      _filename;
    NSString*      _pathOfRawImage;
    unsigned int   _size;
    unsigned short _date;
    unsigned short _time;
    unsigned char  _attribute;
    BOOL           _isDownloaded;
    BOOL           _isSelected;
}

@property (nonatomic, copy) NSString *_directory;
@property (nonatomic, copy) NSString *_filename;
@property (nonatomic, copy) NSString *_pathOfRawImage;
@property (nonatomic) unsigned int _size;
@property (nonatomic) unsigned char _attribute;
@property (nonatomic) unsigned short _date;
@property (nonatomic) unsigned short _time;
@property (nonatomic) BOOL _isDownloaded;
@property (nonatomic) BOOL _isSelected;

// Creating and Initializing
- (id) init;
- (id) initWithString:(NSString*)aDirectory row:(NSString*)aRow;
+ (id) itemWithString:(NSString*)aDirectory row:(NSString*)aRow;

// Destroying
- (void)dealloc;

// Working with Path
- (NSString*) directory;
- (NSString*) extension;
- (NSString*) filename;
- (NSString*) path;
- (NSString*) pathOfRawImage;
- (BOOL) hasExtension:(NSString*)extension; // returns YES if filename has 'extention' as its suffix. ex.) @".jpg"

// Getting Attributes
- (BOOL) isArchive;
- (BOOL) isDirectory;
- (BOOL) isVolumeLabel;
- (BOOL) isSystemFile;
- (BOOL) isHidden;
- (BOOL) isReadOnly;
- (BOOL) isDownloaded;
- (BOOL) isSelected;

// Getting Date and Time
- (NSDate*) dateAsDate;

// Getting Size
- (unsigned int) size;



@end

