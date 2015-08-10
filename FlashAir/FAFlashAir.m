/**
 *  FAFlashAir.m
 *
 *  Copyright (c) 2013 Toshiba Corporation. All rights reserved.
 *  Created by kitano, Fixstars Corporation on 2013/11/28.
 */


#import "FAFlashAir.h"
#import "FAItem.h"

@implementation FAFlashAir

@synthesize _hostname;
@synthesize _fwversion;
@synthesize _currentdir;
@synthesize delegate;


const int kFSFW01_00_00=10000;  /**< Ver1.00.00 */
const int kFSFW01_00_03=10003;  /**< Ver1.00.03 */
const int kFSFW02_00_00=20000;  /**< Ver2.00.00 */
const int kFSFW02_00_02=20003;  /**< Ver2.00.02 */

/**
 * \eng
 * AP mode.
 * \gne
 * \jap
 * APモード
 */
const int kAppModeAP=0;
/**
 * \eng
 * STA mode.
 * \gne
 * \jap
 * STAモード
 * \paj
 */
const int kAppModeSTA=2;
/**
 * \eng
 * BRG mode.
 * \gne
 * \jap
 * BRGモード
 * \paj
 */
const int kAppModeBRG=3;
/**
 * \eng
 * AP mode. WiFi starts on booting.
 * \gne
 * \jap
 * 自動起動のAPモード
 * \paj
 */
const int kAppModeAPAuto=4;
/**
 * \eng
 * STA mode. WiFi starts on booting.
 * \gne
 * \jap
 * 自動起動のSTAモード
 * \paj
 */
const int kAppModeSTAAuto=5;
/**
 * \eng
 * BRG mode. WiFi starts on booting.
 * \gne
 * \jap
 * 自動起動のBRGモード
 * \paj
 */
const int kAppModeBRGAuto=6;        


/**
 * \eng
 * Returns an initialized FAFlashAir object that is connected to "http://flashair".
 * @return An initialized FAFlashAir object that is connected to "http://flashair".
 * \gne
 * \jap
 * "http://flashair"に接続するように初期化されたFAFlashAirオブジェクトを返します。
 * @return "http://flashair"に接続するように初期化されたFAFlashAirオブジェクト。
 * \paj
 */
- (id) init
{
    self = [self initWithHostname:@"flashair"];
    return self;
}

/**
 * \eng
 * Returns an initialized FAFlashAir object that is connected to a given host.
 * @param hostname The name of a host.
 * @return An initialized FAFlashAir object that is connected to a given host.
 * \gne
 * \jap
 * 指定したホストに接続するように初期化されたFAFlashAirオブジェクトを返します。
 * @param hostname ホスト名
 * @return 指定したホストに接続するように初期化されたFAFlashAirオブジェクト。
 * \paj
 */
- (id) initWithHostname:(NSString *)hostname;
{
    NSError *error = nil;
    self = [super init];
    self._hostname = hostname;
    self._fwversion = [self getFirmwareVersion:&error];
    self._currentdir= @"/";
    return self;
}


/**
 * \eng
 * Changes the current directory.
 * @param path    A path to the directory to be set.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return true.
 * \gne
 * \jap
 * カレントディレクトリの変更
 * @param path 参照先ディレクトリのフルパス
 * @param anError エラーオブジェクトへの参照
 * @return 常にtrueが返ります
 * \paj
 */
- (bool) changeDir:(NSString*) path error:(NSError **)anError
{
    self._currentdir=path;
    return true;
}

/**
 * \eng
 * Returns data of a file.
 * @param path A path string to a file.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A byte array contains data of the file.
 * \gne
 * \jap
 * ファイルのデータを返します。
 * @param path 参照先ファイルのフルパス
 * @param anError エラーオブジェクトへの参照
 * @return ファイルのデータを格納したNSDataオブジェクト。
 * \paj
 */
- (NSData *) getFile:(NSString *)path error:(NSError **)anError
{
    // Run
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", self._hostname, path]];
    // Get data
	NSData *data = [NSData dataWithContentsOfURL:url];
    return data;

}

/**
 * \eng
 * Returns the thumbnail of an image.
 * @param path A path string to a file.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A byte array contains thumbnail of the image.
 * \gne
 * \jap
 * サムネイル画像を返します。
 * @param path 参照先ファイルのフルパス
 * @param anError エラーオブジェクトへの参照
 * @return サムネイルデータを格納したNSDataオブジェクト。
 * \paj
 */
- (NSData *) getThumbnail:(NSString *)path error:(NSError **)anError
{
    // Make url
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@/thumbnail.cgi?%@", self._hostname, path]];
    // Get data
	NSData *data = [NSData dataWithContentsOfURL:url];
    return data;
}

/**
 * \eng
 * Returns a list of files in the current directory.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An array of FAItem.
 * \gne
 * \jap
 * カレントディレクトリのファイルリストを返します。
 * @param anError エラーオブジェクトへの参照
 * @return FAItemが配列で返ります
 * \paj
 */
- (NSArray *) getFileList:(NSError **)anError
{
    return [self getFileListWithDirectory:self._currentdir error:anError];
}

/**
 * \eng
 * Returns the number of files in the current directory.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return The number of files.
 * \gne
 * \jap
 * カレントディレクトリのファイル数を返します。
 * @param anError エラーオブジェクトへの参照
 * @return ファイル数が整数で返ります
 * \paj
 */
- (int) getFileCount:(NSError **)anError
{
    return [self getFileCountWithDirectory:self._currentdir error:anError];
}

/**
 * \eng
 * Returns a list of files in the current directory asynchronously.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * \gne
 * \jap
 * カレントディレクトリのファイルリストを非同期的に返します。
 * @param anError エラーオブジェクトへの参照
 * \paj
 */
- (void) requestFileList:(NSError **)anError
{
    NSArray *filelist = [self getFileList:anError];
    if(*anError){
        if([self.delegate respondsToSelector:@selector(FAFlashAirErrorRequest)] ){
            [self.delegate FAFlashAirErrorRequest:anError];
        }
        return;
    }
    [self.delegate FAFlashAirSuccessRequest:filelist];
    return;
}


/**
 * \eng
 * Returns a list of files in a given directory.
 * @param path A path to the directory.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An array of FAItem. Or, nil if error occurs.
 * \gne
 * \jap
 * 指定したディレクトリのファイル一覧を返します。
 * @param path 参照先ディレクトリのフルパス
 * @param anError エラーオブジェクトへの参照
 * @return FAItemが配列で返ります。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSArray *) getFileListWithDirectory:(NSString*) path error:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"100",@"op",
                         path,@"DIR",
                         nil];
    NSString *resultString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    self._currentdir=path;
    NSArray *rowlist = [resultString componentsSeparatedByString:@"\n"];
    NSMutableArray *itemList = [NSMutableArray array];
    for(int i = 1; i < rowlist.count - 1; i++){
        NSString *row = [rowlist objectAtIndex:i];
        [itemList addObject:[FAItem itemWithString:path row:row]];
    }
    return (NSArray *)itemList;
}

/**
 * \eng
 * Returns the number of files in a given directory.
 * @param path A path to the directory.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return The number of files in the given directory. Or, -1 if error occurs.
 * \gne
 * \jap
 * パス指定付きファイル数取得
 * @param path 参照先ディレクトリのフルパス
 * @param anError エラーオブジェクトへの参照
 * @return ファイル数が整数で返ります。エラー発生時には−1が返ります。
 * \paj
 */
- (int) getFileCountWithDirectory:(NSString*) path error:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"101",@"op",
                         path,@"DIR",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return -1;
    }
    return [rtnString intValue];
}

/**
 * \eng
 * Returns a Boolean value that indicates whether contents on a FlashAir is updated or not.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if there is any update after the previous check. Otherwise or if error occurs, NO.
 * \gne
 * \jap
 * アップデート情報取得
 * @param anError エラーオブジェクトへの参照
 * @return 前回の取得以降書き込みがあればTrue/無ければFalse。エラー発生時にはfalseが返ります。
 * \paj
 */
- (bool) getFileUpdate:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"102",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return false;
    }
    return [rtnString isEqualToString:@"1"];
}

/**
 * \eng
 * Returns the SSID of the FlashAir.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An SSID. Or nil if error occurs.
 * \gne
 * \jap
 * SSIDを返します。
 * @param anError エラーオブジェクトへの参照
 * @return SSID文字列。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getSSID:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"104",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Returns the network password of the FlashAir.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A network password string. Or, nil if error occurs.
 * \gne
 * \jap
 * ネットワークパスワードを返します。
 * @param anError エラーオブジェクトへの参照
 * @return パスワード文字列。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getNetworkPassword:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"105",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}
/**
 * \eng
 * Returns MAC address of the client.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return MAC address. Or nil if error occurs.
 * \gne
 * \jap
 * 呼び出し元のMACアドレスを返します。
 * @param anError エラーオブジェクトへの参照
 * @return MACアドレス文字列。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getMacAddress:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"106",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Returns the firmware version of the FlashAir.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An integer value contains the firmware version of the FlashAir.
 *         If the number is 20001, the firmware version should be 2.00.01. 
 *         Or, -1 if error occurs.
 * \gne
 * \jap
 * ファームウェアバージョン取得
 * @param anError エラーオブジェクトへの参照
 * @return ファームウェアのバージョンを示す数値。20001の場合、バージョン2.00.01であることを表します。
 *         エラー発生時には-1が返ります。
 */
- (int) getFirmwareVersion:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"108",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return -1;
    }
    NSString *version = [NSString stringWithFormat:@"%@%@%@",[rtnString substringWithRange:NSMakeRange(9,1)]
                         , [rtnString substringWithRange:NSMakeRange(11,2)]
                         , [rtnString substringWithRange:NSMakeRange(14,2)]];
    return [version intValue];
}

/**
 * \eng
 * Returns Card Identifier(CID).
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return Card Identifier(CID). Or, nil if error occurs.
 * \gne
 * \jap
 * Card Identifier(CID)を返します。
 * @param anError エラーオブジェクトへの参照
 * @return Card Identifier(CID)文字列。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getCardIdentifier:(NSError **)anError
{
    if(self._fwversion < kFSFW01_00_03)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"120",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Returns information about a capacity of the FlashAir.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An NSDictionary object contains the information about the capacity of the FlashAir. Or nil if error occurs.
 *         To get the values, use keys: "emptysec" for the number of empty sectors,
 *         "totalsec" for the number of all sectors, and "sizesec" for the size of a sector in bytes.
 * \gne
 * \jap
 * 容量に関する情報を返します。
 * @param anError エラーオブジェクトへの参照
 * @return 容量に関する情報が格納されたNSDictionaryオブジェクト。エラー発生時にはnilが返ります。
 *         個々の値を取得するには、次のキーを使用してください。
 *         "emptysec" 空セクター数、"totalsec" 全セクター数、"sizesec" セクターサイズ(バイト)。
 * \paj
 */
- (NSDictionary *) getFreeSector:(NSError **)anError
{
    if(self._fwversion < kFSFW01_00_03)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"140",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    NSString *emptysec = [[rtnString componentsSeparatedByString:@"/"] objectAtIndex:0];
    NSString *totalsec = [[[[rtnString componentsSeparatedByString:@","] objectAtIndex:0] componentsSeparatedByString:@"/"] objectAtIndex:1];
    NSString *sizesec = [[rtnString componentsSeparatedByString:@","] objectAtIndex:1];
    NSDictionary *rtnDic = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:[emptysec intValue]], @"emptysec",
                           [NSNumber numberWithInt:[totalsec intValue]], @"totalsec",
                           [NSNumber numberWithInt:[sizesec intValue]], @"sizesec",
                           nil];
    return rtnDic;
}

/**
 * \eng
 * Returns a path to the control image.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A path to the control image. Or nil if error occurs.
 * \gne
 * \jap
 * 制御イメージのパスを取得
 * @param anError エラーオブジェクトへの参照
 * @return 制御イメージファイルのフルパス。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getControlImage:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"109",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Returns a WiFi mode.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A WiFi mode as an integer value. See kFSAppModeXxx constants. Or, -1 if error occurs.
 * \gne
 * \jap
 * 無線LANモードを取得
 * @param anError エラーオブジェクトへの参照
 * @return 無線LANモードを数値型で返します。kFSAppModeXxx定数を参照のこと。エラー発生時には-1が返ります。
 * \paj
 */
- (int) getAppmode:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return -1;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"110",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return -1;
    }
    return [rtnString intValue];
}
/*!
 * \if english
 * Returns a timeout length to stop WiFi in seconds.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A timeout length to stop WiFi in seconds. Or, -1 if error occurs.
 * \endif
 * \if japanese
 * 無線LANタイムアウト秒数を返します。
 * @param anError エラーオブジェクトへの参照
 * @return 秒数を数値型で返します。エラー発生時には-1が返ります。
 * \endif
 */
- (int) getAppauto:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return -1;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"111",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return -1;
    }
    return [rtnString intValue];
}

/**
 * \eng
 * Returns an application specfic information (APPINFO).
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A APPINFO string. Or nil if error occurs.
 * \gne
 * \jap
 * アプリケーション独自情報(APPINFO)の取得
 * @param anError エラーオブジェクトへの参照
 * @return APPINFO文字列を返します。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getAppInfo:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"117",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Returns a data read from the scratch pad on the FlashAir.
 * @param addr An address
 * @param len  A length in bytes.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return A string contains the retrieved data. Or nil if error occurs.
 * \gne
 * \jap
 * 共有メモリからのデータを読み込んで返します。
 * @param addr 参照先アドレス
 * @param len 長さ
 * @param anError エラーオブジェクトへの参照
 * @return 取得したデータを文字列で返します。エラー発生時にはnilが返ります。
 * \paj
 */
- (NSString *) getRegister:(int) addr length:(int) len error:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"130",@"op",
                         [NSString stringWithFormat:@"%d", addr],@"ADDR",
                         [NSString stringWithFormat:@"%d", len],@"LEN",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}

/**
 * \eng
 * Writes a data to the scratch pad on the FlashAir.
 * @param addr An address
 * @param len  A length in bytes.
 * @param data A data to be written.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * 共有メモリへのデータ書き込み
 * @param addr 参照先アドレス
 * @param len 長さ
 * @param data データ内容文字列
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setRegister:(int) addr length:(int) len data:(NSString*) data error:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return false;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"131",@"op",
                         [NSString stringWithFormat:@"%d", addr],@"ADDR",
                         [NSString stringWithFormat:@"%d", len],@"LEN",
                          data, @"DATA",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError || ![rtnString isEqualToString:@"SUCCESS"]){
        return false;
    }
    return true;
}

/**
 * \eng
 * Enables PhotoShare.
 * @param date A date to share.
 * @param path A path to a directory to share.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * フォトシェアモードの有効化
 * @param date シェア対象日付
 * @param path シェア対象日付
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setPhotoShareMode:(NSDate *)date directory:(NSString *)path error:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return false;
    }
    *anError = nil;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateCompnents;
    dateCompnents =[calendar components:NSYearCalendarUnit
                    | NSMonthCalendarUnit
                    | NSDayCalendarUnit
                    | NSHourCalendarUnit
                    | NSMinuteCalendarUnit
                    | NSSecondCalendarUnit fromDate:date];
    NSInteger year =([dateCompnents year]-1980) << 9;
    NSInteger month = [dateCompnents month] <<5;
    NSInteger day = [dateCompnents day];
    NSString *datePart = [NSString stringWithFormat:@"%d" ,year+month+day];
    
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"200",@"op",
                         path,@"DIR",
                         datePart, @"DATE",
                         nil];
    
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError || ![rtnString isEqualToString:@"OK"]){
        return false;
    }
    return true;
}

/**
 * \eng
 * Disables PhotoShare.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * フォトシェアモードの無効化
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) releasePhotoShareMode:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return false;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"201",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError || ![rtnString isEqualToString:@"OK"]){
        return false;
    }
    return true;
}

/**
 * \eng
 * Returns a Boolean value that indicates whether PhotoShare is enabled or not.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if PhotoShare is enabled, otherwise NO.
 * \gne
 * \jap
 * フォトシェアモードの状態取得
 * @param anError エラーオブジェクトへの参照
 * @return シェア中ならYES/非シェア中もしくはAPI失敗時にはNOを返します。
 * \paj
 */
- (bool) getPhotoShareMode:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return false;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"202",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError || ![rtnString isEqualToString:@"SHAREMODE"]){
        return false;
    }
    return true;
}

/**
 * \eng
 * Returns an SSID that is prefered to use during PhotoShare mode.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An SSID string that is prefered to use during PhotoShare mode. Or, nil if error occurs.
 * \gne
 * \jap
 * フォトシェアモードのSSID取得
 * @param anError エラーオブジェクトへの参照
 * @return フォトシェアモードで使用しているSSIDが文字列で返ります。フォトシェアをしていない場合とエラー発生時にはnilになります。
 * \paj
 */
- (NSString *) getPhotoShareModeSSID:(NSError **)anError
{
    if(self._fwversion < kFSFW02_00_00)    {
        [self makeError:kFSErrorInvalidVersion error:anError];
        return nil;
    }
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"203",@"op",
                         nil];
    NSString *rtnString = [self sendCommand:dict error:anError];
    if(*anError){
        return nil;
    }
    return rtnString;
}


/**
 * \eng
 * config.cgi helper.
 * @param mastercode A master code.
 * @param params An NSDictionary object contains query parameters.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * config.cgiのラッパー関数
 * @param anError エラーオブジェクトへの参照
 * @param mastercode マスターコード文字列
 * @param params コマンドとともに投げるクエリ文字列に設定するパラメータのDictionary
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setConfig:(NSString *) mastercode params:(NSDictionary *) params error:(NSError **)anError
{
    NSError *error = nil;
    NSString *rtnString= @"";
    NSString *parameter = @"";
    
    // Add paramaters
    if(params.count > 0){
        NSArray *keys = [params allKeys];
        NSString *key = [keys objectAtIndex:0];
        parameter = [NSString stringWithFormat:@"%@=%@", @"MASTERCODE", mastercode];
        for(int i=0; i<[keys count]; i++){
            key = [keys objectAtIndex:i];
            parameter = [NSString stringWithFormat:@"%@&%@=%@", parameter, key, [params objectForKey:key]];
            if(self._fwversion < kFSFW02_00_02){
                if ([key isEqualToString:@"BRGNETWORKKEY"] || [key isEqualToString:@"BRGSSID"]){
                    [self makeError:kFSErrorInvalidVersion error:anError];
                    return false;
                }
            }
        }
    }
    
    // Make url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/config.cgi?%@", self._hostname, parameter]];
    
    // Run cgi
    rtnString =[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        
        [self makeError:kFSErrorConnectionTimeOut error:anError];
        
    }
    
    if(![rtnString isEqualToString:@"SUCCESS"])
    {
        return false;
    }
    
    return true;

}

//Upload系

/**
 * \eng
 * Enable write protection to the FlashAir.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * ホスト機器からの書き込みを禁止する
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setWriteProtect:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         @"ON",@"WRITEPROTECT",
                         nil];
    NSString *rtnString = [self sendUpload:dict error:anError];
    if(*anError){
        return false;
    }
    return [rtnString isEqualToString:@"SUCCESS"];

}

/**
 * \eng
 * Set a timestamp of a file to be uploaded.
 * @param datetime A timestamp.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * アップロードするファイルの更新日時を設定する
 * @param datetime 設定するシステム時間
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setSystemTime:(NSDate *)datetime error:(NSError **)anError
{
    // Set Write-Protect and upload directory and System-Time
    // Make System-Time
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateCompnents;
    dateCompnents =[calendar components:NSYearCalendarUnit
                    | NSMonthCalendarUnit
                    | NSDayCalendarUnit
                    | NSHourCalendarUnit
                    | NSMinuteCalendarUnit
                    | NSSecondCalendarUnit fromDate:datetime];
    
    NSInteger year =([dateCompnents year]-1980) << 9;
    NSInteger month = ([dateCompnents month]) << 5;
    NSInteger day = [dateCompnents day];
    NSInteger hour = [dateCompnents hour] << 11;
    NSInteger minute = [dateCompnents minute]<< 5;
    NSInteger second = floor([dateCompnents second]/2);
    
    NSString *datePart = [@"0x" stringByAppendingString:[NSString stringWithFormat:@"%04x%04x" ,year+month+day,hour+minute+second]];
    
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         datePart,@"FTIME",
                         nil];
    NSString *rtnString = [self sendUpload:dict error:anError];
    if(*anError){
        return false;
    }
    return [rtnString isEqualToString:@"SUCCESS"];
}

/**
 * \eng
 * Removes a file on the FlashAir.
 * @param path A path to be removed.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * ファイルを削除する
 * @param anError エラーオブジェクトへの参照
 * @param path 削除するファイル
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) deleteFile:(NSString *)path error:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         path,@"DEL",
                         nil];
    NSString *rtnString = [self sendUpload:dict error:anError];
    if(*anError){
        return false;
    }
    return [rtnString isEqualToString:@"SUCCESS"];
}

/**
 * \eng
 * Set the current directory as an upload destination.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * カレントディレクトリをアップロード先に設定
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setUploadDirectory:(NSError **)anError
{
    return [self setUploadDirectoryWithPath:self._currentdir error:anError];
}

/**
 * \eng
 * Set an upload destination directory.
 * @param path A directory to be set as an upload destination.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * アップロード先を設定
 * @param path アップロード先のディレクトリ
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) setUploadDirectoryWithPath:(NSString *)path error:(NSError **)anError
{
    *anError = nil;
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                         path,@"UPDIR",
                         nil];
    NSString *rtnString = [self sendUpload:dict error:anError];
    if(*anError){
        return false;
    }
    return [rtnString isEqualToString:@"SUCCESS"];
}
/**
 * \eng
 * Uploads a given binary data.
 * @param data A data to be uploaded.
 * @param filename A file name.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * バイナリデータのアップロード
 * @param data アップロードするデータ
 * @param filename ファイル名
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 * \paj
 */
- (bool) uploadBinary:(NSData *)data filename:(NSString *)filename error:(NSError **)anError;
{
    return [self postUpload:data filename:filename mode:false error:anError];

}
/**
 * \eng
 * Uploads a given text data.
 * @param data A data to be uploaded.
 * @param filename A file name.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return YES if successful, otherwie NO.
 * \gne
 * \jap
 * テキストデータのアップロード
 * @param data アップロードするデータ
 * @param filename ファイル名
 * @param anError エラーオブジェクトへの参照
 * @return 成功したらYES/失敗したらNOを返します。
 */
- (bool) uploadText:(NSString *)data filename:(NSString *)filename error:(NSError **)anError
{
    
    NSData *textData=[data dataUsingEncoding:NSUTF8StringEncoding ];
    return [self postUpload:textData filename:filename mode:true error:anError];
}


/**
 * \eng
 * command.cgi helper.
 *
 * @param params An NSDictionary object contains query parameters.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return The HTML document returned from the FlashAir.
 * \gne
 * \jap
 * command.cgiラッパー関数（Private）
 *
 * @param params コマンドとともに投げるクエリ文字列に設定するパラメータのDictionary
 * @param anError エラーオブジェクトへの参照
 * @return FlashAirから返ってきたHTML文書
 * \paj
 */
- (NSString *) sendCommand:(NSDictionary *) params error:(NSError **)anError
{
    NSError *error = nil;
    NSString *rtnString= @"";
    NSString *parameter = @"";
    
    // Add paramaters
    if(params.count > 0){
        NSArray *keys = [params allKeys];
        NSString *key = [keys objectAtIndex:0];
        parameter = [NSString stringWithFormat:@"%@=%@", key, [params objectForKey:key]];
        for(int i=1; i<[keys count]; i++){
            key = [keys objectAtIndex:i];
            parameter = [NSString stringWithFormat:@"%@&%@=%@", parameter, key, [params objectForKey:key]];
        }
    }
    
    // Make url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/command.cgi?%@", self._hostname, parameter]];
    
    // Run cgi
    rtnString =[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        
        [self makeError:kFSErrorConnectionTimeOut error:anError];
        
    }

    return rtnString;
}

/**
 * \eng
 * upload.cgi helper for GET request.
 * @param params An NSDictionary object contains query parameters.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * @return The HTML document returned from the FlashAir.
 * \gne
 * \jap
 * upload.cgiラッパー関数（Private:GET）
 *
 * @param params コマンドとともに投げるクエリ文字列に設定するパラメータのDictionary
 * @param anError エラーオブジェクトへの参照
 * @return FlashAirから返ってきたHTML文書
 * \paj
 */
- (NSString *) sendUpload:(NSDictionary *) params error:(NSError **)anError
{
    NSError *error = nil;
    NSString *rtnString= @"";
    NSString *parameter = @"";
    
    // Add paramaters
    if(params.count > 0){
        NSArray *keys = [params allKeys];
        NSString *key = [keys objectAtIndex:0];
        parameter = [NSString stringWithFormat:@"%@=%@", key, [params objectForKey:key]];
        for(int i=1; i<[keys count]; i++){
            key = [keys objectAtIndex:i];
            parameter = [NSString stringWithFormat:@"%@&%@=%@", parameter, key, [params objectForKey:key]];
        }
    }
    
    // Make url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/upload.cgi?%@", self._hostname, parameter]];
    
    // Run cgi
    rtnString =[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        
        [self makeError:kFSErrorConnectionTimeOut error:anError];
        
    }
    
    return rtnString;
}

/**
 * \eng
 * upload.cgi helper for POST request.
 * @param mode Set YES for text transfer, or NO for binary transfer.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * \gne
 * \jap
 * upload.cgiラッパー関数（Private:POST）
 * @param mode true:テキストモード/false:バイナリモード
 * \paj
 */
- (bool) postUpload:(NSData *)data filename:(NSString *)filename mode:(bool)mode error:(NSError **)anError
{
    
    NSURL *url=[NSURL URLWithString:@"http://flashair/upload.cgi"];
    
    //boundary
    CFUUIDRef uuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, uuid);
	CFRelease(uuid);
    NSString *boundary = [NSString stringWithFormat:@"flashair-%@",uuidString];
    
    //header
    NSString *header = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    
    //body
    NSMutableData *body=[NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",filename] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //switch for binary or plain text
    if(mode){
        [body appendData:[[NSString stringWithFormat:@"Content-Type: text/plain\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }else{
        [body appendData:[[NSString stringWithFormat:@"Content-Type: octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
	[body appendData:data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:header forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:body];
    
    
    NSURLResponse *response;
    NSError *error = nil;;
    NSData *result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:&error];
    NSString *rtnStr =[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    if ([error.domain isEqualToString:NSCocoaErrorDomain]){
        
        [self makeError:kFSErrorConnectionTimeOut error:anError];
        return false;
        
    }else{
        if([rtnStr rangeOfString:@"Success"].location==NSNotFound){     //v2.0
            return false;
        }else{
            return true;
        }
    }
}




/**
 * \eng
 * Create an error object. It is intended to be an internal use.
 * @param errorCode An error code.
 * @param anError If an error occurs, upon return contains an NSError object that describes the problem.
 * \gne
 * \jap
 * エラーオブジェクトを返します。
 * @param errorCode 内部エラーコード
 * @param anError エラーオブジェクトへの参照
 * \paj
 */
- (void) makeError:(NSInteger) errorCode error:(NSError **)anError
{
    if(anError != NULL){
        
        NSDictionary* errorDic;

        switch (errorCode) {
            case kFSErrorInvalidVersion:
                errorDic = @{
                                NSLocalizedDescriptionKey : @"Invalid Firmware Version.",
                                NSLocalizedRecoverySuggestionErrorKey : @"Check your firmware version of FlashAir"
                                };
                break;
            case kFSErrorConnectionTimeOut:
                errorDic = @{
                                NSLocalizedDescriptionKey : @"Connection Timeout.",
                                NSLocalizedRecoverySuggestionErrorKey : @"Check your Network"
                                };
                break;
                
            default:
                break;
        }
        *anError = [NSError errorWithDomain:@"com.fixstars.Flashair.SDK" code:errorCode userInfo:errorDic];
    }
    // TODO:
   

}
@end
