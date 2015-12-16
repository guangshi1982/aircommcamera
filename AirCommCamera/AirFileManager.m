//
//  AirFileManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/28.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirFileManager.h"
#import "FAFlashAir.h"
#import "FAItem.h"

#define CONNECTION_INTERVAL 3

#define QUEUE_SERIAL_FLASHAIR_CONNECTION "com.threees.aircomm.aircam.flashair.connection"

// todo: check connection
@interface AirFileManager() <FAFlashAirDelegate>

@property (nonatomic) FAFlashAir *flashAir;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic) NSTimer *connTimer;
@property (nonatomic) int retryCount;
@property (nonatomic) BOOL connectInfinity;
@property (nonatomic) BOOL state;
@property (nonatomic) dispatch_queue_t airConnQueue;

//- (void)connect:(NSTimer*)timer;

@end

@implementation AirFileManager

+ (AirFileManager*)getInstance
{
    static AirFileManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AirFileManager new];
    });
    
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        // memo:FlashAirに接続するので、多少時間がかかる
        //_flashAir = [[FAFlashAir alloc] initWithHostname:@"aircard.local"];
        //_flashAir = [[FAFlashAir alloc] initWithHostname:@"192.168.0.1"];
        // todo:TBD
        //_rootPath = @"/DCIM/IMGS";
        //_rootPath = @"/SD_WLAN";
        _rootPath = @"/data";
        _state = NO;
        _connectInfinity = YES;
        
        _airConnQueue = dispatch_queue_create(QUEUE_SERIAL_FLASHAIR_CONNECTION, DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(_airConnQueue, ^{
            _flashAir = [[FAFlashAir alloc] initWithHostname:@"aircard.local"];
            //_flashAir = [[FAFlashAir alloc] initWithHostname:@"192.168.0.1"];
            [self connectWithRetryCount:0];
        });
        
        // todo: timer start here?
    }
    
    return self;
}

- (void)finalize
{
    NSLog(@"finalize");
    if (_connTimer != nil && _connTimer.valid) {
        [_connTimer invalidate];
    }
}

// todo:lock retryCount?
- (void)connect:(NSTimer*)timer
{
    if (_flashAir) {
        NSError *error = nil;
        BOOL isConn = NO;
        int version = [_flashAir getFirmwareVersion:&error];
        if (version != -1 && error != nil) {
            isConn = YES;
        } else if (error != nil) {
            NSLog(@"isConnected %@\n", error);
        }
        
        // memo: notify always
        //if (_state != isConn) {
            _state = isConn;
            if (_delegate != nil) {
                if ([_delegate respondsToSelector:@selector(airFileManager:isConnected:)]) {
                    [_delegate airFileManager:self isConnected:_state];
                }
            }
        //}
    }
    
    // decreace when not infinity
    if (!_connectInfinity) {
        _retryCount--;
        
        if (_state || _retryCount <= 0) {
            if (_connTimer != nil && _connTimer.valid) {
                [_connTimer invalidate];
            }
        }
    }
}

- (NSString*)getLatestFolderPath
{
    NSError *error = nil;
    NSString *folderPath = nil;
    NSString *dataFilePath = [NSString stringWithFormat:@"%@/%@", _rootPath, @"NUM_FLD.DAT"];
    
    // 下記でもとれるかも
    //[NSString stringWithContentsOfFile:dataFilePath encoding:NSASCIIStringEncoding error:&error];
    NSData *data = [_flashAir getFile:dataFilePath error:&error];
    if (data) {
        NSString *latestFolder = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        if (latestFolder) {
            folderPath = [NSString stringWithFormat:@"%@/FLD%@", _rootPath, latestFolder];
        }
    }
    
    return folderPath;
}

// todo: retry all the time and notify by delegate or hold the state which returned by isConnect
- (void)connectWithRetryCount:(int)retryCount
{
    if (_connTimer != nil && _connTimer.valid) {
        [_connTimer invalidate];
    }
    
    _retryCount = retryCount;
    _connTimer = [NSTimer scheduledTimerWithTimeInterval:CONNECTION_INTERVAL target:self selector:@selector(connect:) userInfo:nil repeats:YES];
}

- (BOOL)isConnected
{
    // todo: TBD delete? -> return current state
    /*if (_state == NO) {
        if (_flashAir) {
            NSError *error = nil;
            int version = [_flashAir getFirmwareVersion:&error];
            if (version != -1 && error != nil) {
                _state = YES;
            } else if (error != nil) {
                NSLog(@"isConnected %@\n", error);
            }
        }
    }*/
    
    return _state;
}

- (void)setRootPath:(NSString*)path
{
    _rootPath = path;
}

- (NSArray*)foldersAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *folders = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"foldersAtDirectory %@\n", error);
        return folders;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && item.isDirectory) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [folders addObject:airFile];
        }
    }
    
    return folders;
}

// folders and files
- (NSArray*)filesAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n",error);
        return files;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [files addObject:airFile];
        }
    }
    
    return files;
}

- (NSArray*)imagesAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSString *ext = @"JPG";
    
    // Get file list
    if (path) {
        NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
        if (error){
            NSLog(@"filesAtDirectory %@\n", error);
            return images;
        }
        
        for (int i = 0; i < fileList.count; i++) {
            FAItem *item = (FAItem*)[fileList objectAtIndex:i];
            if (item != nil && [item hasExtension:ext]) {
                AirImage *airImage = [[AirImage alloc] initWithItem:item];
                [images addObject:airImage];
            }
        }
    }
    
    return images;
}

- (int)latestImageIndex
{
    int index = -1;
    NSString *latestPath = nil;
    
    // todo:変わった時(電源ON)１回とれば良いので、タイミングについて検討
    NSString *latestFolder = [self getLatestFolderPath];
    if (latestFolder) {
        latestPath = [NSString stringWithFormat:@"%@/%@", _rootPath, latestFolder];
    }

    if (latestPath) {
        index = [self fileCountAtDirectory:latestPath fileExt:@"JPG"];
    }
    
    return index;
}

- (NSArray*)latestFolderImages
{
    NSString *latestPath = nil;
    NSArray *images = [[NSArray alloc] init];
    
    // todo:変わった時(電源ON)１回とれば良いので、タイミングについて検討
    NSString *latestFolder = [self getLatestFolderPath];
    if (latestFolder) {
        latestPath = [NSString stringWithFormat:@"%@/%@", _rootPath, latestFolder];
    }
    
    if (latestPath) {
        images = [self imagesAtDirectory:latestPath];
    }
    
    return images;
}

- (AirImage*)latestImage
{
    AirImage *airImage = nil;
    
    NSError *error = nil;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSString *ext = @"JPG";
    
    // todo:変わった時(電源ON)１回とれば良いので、タイミングについて検討
    NSString *latestPath = [self getLatestFolderPath];
    
    // Get file list()
    if (latestPath) {
        NSArray *fileList = [_flashAir getFileListWithDirectory:latestPath error:&error];
        if (error){
            NSLog(@"filesAtDirectory %@\n", error);
            return nil;
        }
        
        int lastImageIndex = (int)fileList.count - 1;
        
        while (true) {
            FAItem *item = (FAItem*)[fileList objectAtIndex:lastImageIndex];
            if (item != nil && item.size > 0 && [item hasExtension:ext]) {
                airImage = [[AirImage alloc] initWithItem:item];
                break;
            }
            
            lastImageIndex--;
            if (lastImageIndex < 0) {
                break;
            }
        }
    }
    
    return airImage;
}

- (void)requestLatestImage
{
    dispatch_async(_airConnQueue, ^{
        AirImage *latestImage = [self latestImage];
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(airFileManager:requestedLatestImage:)]) {
                [_delegate airFileManager:self requestedLatestImage:latestImage];
            }
        }
    });
}

- (AirImage*)latestImageAt:(int)index;
{
    AirImage *airImage = nil;
    NSString *latestPath = nil;
    NSString *latestImagePath = nil;
    
    // todo:変わった時(電源ON)１回とれば良いので、タイミングについて検討
    NSString *latestFolder = [self getLatestFolderPath];
    if (latestFolder) {
        latestPath = [NSString stringWithFormat:@"%@/%@", _rootPath, latestFolder];
    }
    
    if (latestPath) {
        latestImagePath = [NSString stringWithFormat:@"%3d", index];
    }
    
    if (latestImagePath) {
        NSData *data = [self getFileData:latestImagePath];
        if (data) {
            airImage = [[AirImage alloc] initWithData:data];
        }
    }
    
    return airImage;
}

- (void)requestLatestImageStartAt:(int)index
{
    dispatch_async(_airConnQueue, ^{
        AirImage *latestImage = [self latestImageAt:index];
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(airFileManager:requestedLatestImage:)]) {
                [_delegate airFileManager:self requestedLatestImage:latestImage];
            }
        }
    });
}

- (NSArray*)latestImagesStartAt:(int)startIndex
{
    NSError *error = nil;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSString *ext = @"JPG";
    
    // todo:変わった時(電源ON)１回とれば良いので、タイミングについて検討
    NSString *latestPath = [self getLatestFolderPath];
    
    // Get file list()
    if (latestPath) {
        NSArray *fileList = [_flashAir getFileListWithDirectory:latestPath error:&error];
        if (error){
            NSLog(@"filesAtDirectory %@\n", error);
            return images;
        }
        
        int fileCount = (int)fileList.count;
        // last 1 image
        if (startIndex < 0) {
            startIndex = fileCount > 0 ? (int)fileCount - 1 : 0;
        }
        
        if (startIndex < fileCount) {
            for (int i = startIndex; i < fileCount; i++) {
                FAItem *item = (FAItem*)[fileList objectAtIndex:i];
                if (item != nil && item.size > 0 && [item hasExtension:ext]) {
                    AirImage *airImage = [[AirImage alloc] initWithItem:item];
                    [images addObject:airImage];
                }
            }
        }
    }
    
    return images;
}

- (void)requestLatestImagesStartAt:(int)index
{
    dispatch_async(_airConnQueue, ^{
        NSArray *airImages = [self latestImagesStartAt:index];
        if (airImages) {
            if (_delegate) {
                if ([_delegate respondsToSelector:@selector(airFileManager:requestedLatestImage:)]) {
                    for (AirImage *latestImage in airImages) {
                        [_delegate airFileManager:self requestedLatestImage:latestImage];
                    }
                }
            }
        }
    });
}

- (NSArray*)filesAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return files;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && [item hasExtension:ext]) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [files addObject:airFile];
        }
    }
    
    return files;
}

- (int)fileCountAtDirectory:(NSString*)path
{
    NSError *error = nil;
    int fileCount = 0;
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return 0;
    }
    
    fileCount = (int)fileList.count;
    
    return fileCount;
}

- (int)fileCountAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    int fileCount = 0;
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return 0;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && [item hasExtension:ext]) {
            fileCount++;
        }
    }
    
    return fileCount;
}

- (AirFile*)firstFileAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    AirFile *airFile = nil;
    
    NSArray *fileList = [self filesAtDirectory:path fileExt:ext];
    if (fileList != nil && fileList.count > 0) {
        airFile = fileList[0];
    }
    
    if (airFile == nil) {
        NSString *contImage = [_flashAir getControlImage:&error];
        airFile = [[AirFile alloc] init];
        airFile.fileType = AirFileTypeFile;
        airFile.filePath = contImage;
    }
    
    return airFile;
}

- (NSData*)getFileData:(NSString*)path
{
    NSError *error = nil;
    NSData *fileData = nil;
    
    fileData = [_flashAir getFile:path error:&error];
    if (error) {
        NSLog(@"getFileData %@\n", error);
        return nil;
    }
    
    return fileData;
}

- (NSData*)getPreviewData
{
    NSError *error = nil;
    NSData *fileData = nil;
    
    NSString *previewPath = [_flashAir getControlImage:&error];
    if (previewPath) {
        fileData = [_flashAir getFile:previewPath error:&error];
        if (error) {
            NSLog(@"getFileData %@\n", error);
            return nil;
        }
    }
    
    return fileData;
}

// FAFlashAirDelegate

- (void)FAFlashAirSuccessRequest:(NSArray *)filelist
{
    
}

- (void)FAFlashAirErrorRequest:(NSError *__autoreleasing *)anError
{
    
}

@end
