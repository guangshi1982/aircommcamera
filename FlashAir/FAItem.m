/**
 *  FAItem.m
 *
 *  Copyright (c) 2013 Toshiba Corporation. All rights reserved.
 *  Created by kitano, Fixstars Corporation on 2013/11/28.
 */

#import "FAItem.h"

@interface FAItem ()
    
@end

@implementation FAItem

@synthesize _directory;
@synthesize _filename;
@synthesize _size;
@synthesize _attribute;
@synthesize _date;
@synthesize _time;
#if 0
@synthesize _pathOfRawImage;
@synthesize _isDownloaded;
@synthesize _isSelected;
#endif

/**
 * \eng
 * An initialized FAItem object that contains no data.
 * @return An initialized FAItem object.
 * \gne
 * \jap
 * 初期化されたFAItemオブジェクトを返します。
 * @return 初期化されたFAItemオブジェクト。
 * \paj
 */

- (id)init
{
    self = [super init];
    
    self._directory = nil;
    self._filename = nil;
    self._size = 0;
    self._date = 0;
    self._time = 0;
    self._attribute = 0;
    self._isDownloaded = NO;
    self._isSelected = NO;
    return self;
}

/**
 * \eng
 * An initialized FAItem object that contains given information made from a given record.
 * @param _aDirectory A parent directory.
 * @param aRow A record
 * @return An initialized FAItem object.
 * \gne
 * \jap
 * 指定されたデータで初期化されたFAItemオブジェクトを返します。
 * @param _aDirectory 検出対象ディレクトリ
 * @param aRow カンマ区切りデータ1行分
 * @return 初期化されたFAItemオブジェクト。
 * \paj
 */

- (id)initWithString:(NSString*)_aDirectory row:(NSString*)aRow
{
    self = [super init];
    
    // If the directory is the root directory, _aDirectory contain no characters.
    NSString* aDirectory = [_aDirectory isEqualToString:@"/"] ? @"" : _aDirectory;

    // Directory and Filename may contain ',', so we can't split aRow
    // with ','.
    // Instead of doint that, we use given directory name,
    // and skip a head of aRow by the length of directory name
    // to split aRow with ','.
    NSArray* tmpArray = [[aRow substringFromIndex:[aDirectory length]]componentsSeparatedByString:@","];

    self._directory = aDirectory;
    self._filename = [[tmpArray subarrayWithRange:NSMakeRange(1, [tmpArray count] - 5)] componentsJoinedByString:@","];
    self._size = [tmpArray[[tmpArray count] - 4] intValue];
    self._attribute = [tmpArray[[tmpArray count] - 3] intValue];
    self._date = [tmpArray[[tmpArray count] - 2] intValue];
    self._time = [tmpArray[[tmpArray count] - 1] intValue];

	#if 0
    self._pathOfRawImage = @"";
	#endif

    return self;
}

/**
 * \eng
 * Returns a new FAItem object that contains given information made from a given file record.
 * @param _aDirectory The name of the directory where a file is located in.
 * @param aRow A string of a file record.
 * @return An initialized FAItem object.
 * \gne
 * \jap
 * 指定されたファイル情報で初期化された新しいFAItemオブジェクトを返します。
 * @param _aDirectory ファイルの親ディレクトリ。
 * @param aRow カンマ区切りデータ1行分
 * @return 初期化されたFAItemオブジェクト。
 * \paj
 */
+ (id)itemWithString:(NSString*)_aDirectory row:(NSString*)aRow
{
    return [[FAItem alloc] initWithString:_aDirectory row:aRow];
}
/**
 * \eng
 * Dealloc the object.
 * \gne
 * \jap
 * デアロケータ
 * \paj
 */
- (void)dealloc
{

}

/**
 * \eng
 * Returns the name of the directory where the file associated with this item locates.
 * @return The string contains the name of the directory where the file associated with this item locates.
 * \gne
 * \jap
 * ファイルが格納されているディレクトリを返します。
 * @return ファイルの格納されているディレクトリ名が格納された文字列です。
 * \paj
 */
- (NSString*)directory
{
    return self._directory;
}
/**
 * \eng
 * Returns the extension of the file associated with this item.
 * @return The string contains the extension of the file associated with this item.
 * \gne
 * \jap
 * 拡張子を返します。
 * @return 拡張子が格納された文字列です。
 * \paj
 */
- (NSString*)extension
{
    return [self._filename pathExtension];
}

/**
 * \eng
 * Returns the name of the file associated with this item.
 * @return The string contains the name of the file associated with this item.
 * \gne
 * \jap
 * ファイル名を返します。
 * @return ファイル名が格納された文字列です。
 * \paj
 */
- (NSString*)filename
{
    return self._filename;
}

/**
 * \eng
 * Returns the path from the root directory to the file associated with this item.
 * @return The string contains the path from the root directory to the file associated with this item.
 * \gne
 * \jap
 * ルートディレクトリからのパスを返します。
 * @return ルートディレクトリからのパスが格納された文字列です。
 * \paj
 */
- (NSString*)path
{
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendString:self._directory];
    [str appendString:@"/"];
    [str appendString:self._filename];
    return str;
}

#if 0
/**
 * \eng
 * RAWイメージのパスの取得
 * @return パス
 * \gne
 * \jap
 * RAWイメージのパスの取得
 * @return パス
 * \paj
 */
- (NSString*)pathOfRawImage
{
    return self._pathOfRawImage;
}
#endif


/**
 * \eng
 * Returns a Boolean value that indicates whether the name of this item ends with a given extension (suffix).
 * @param extention A string. Its format must be ".ext".
 * @return YES if this item has the given extension, otherwise NO.
 * \gne
 * \jap
 * 指定された拡張子かどうか調べます。
 * @param extention ".ext"の形式で与えられた文字列。
 * @return 拡張子が一致する場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)hasExtension:(NSString*)extension
{
    if ([self isDirectory]) return false;
    return [self._filename hasSuffix:extension];
}

/**
 * \eng
 * Returns a Boolean value that indicates whether this item is an archive.
 * @return YES if this item is an archive, otherwise NO.
 * \gne
 * \jap
 * アーカイブかどうか調べます。
 * @return アーカイブである場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isArchive
{
    return (self._attribute & 0x20) != 0;
}
/**
 * \eng
 * Returns a Boolean value that indicates whether this item is a directory.
 * @return YES if this item is a directory, otherwise NO.
 * \gne
 * \jap
 * ディレクトリかどうか調べます。
 * @return ディレクトリである場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isDirectory
{
    return (self._attribute & 0x10) != 0;
}
/**
 * \eng
 * Returns a Boolean value that indicates whether this item is a volume label.
 * @return YES if this item is a volume label, otherwise NO.
 * \gne
 * \jap
 * ボリュームラベルかどうか調べます。
 * @return ボリュームラベルである場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isVolumeLabel
{
    return (self._attribute & 0x08) != 0;
}
/**
 * \eng
 * Returns a Boolean value that indicates whether this item is a system file.
 * @return YES if this item is a system file, otherwise NO.
 * \gne
 * \jap
 * システムファイルかどうか調べます。
 * @return システムファイルである場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isSystemFile
{
    return (self._attribute & 0x04) != 0;
}
/**
 * \eng
 * Returns a Boolean value that indicates whether this item is hidden.
 * @return YES if this item is hidden, otherwise NO.
 * \gne
 * \jap
 * 不可視属性が付いているファイルかどうか調べます。
 * @return 不可視属性が付いている場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isHidden
{
    return (self._attribute & 0x02) != 0;
}
/**
 * \eng
 * Returns a Boolean value that indicates whether this item is read only.
 * @return YES if this item is read only, otherwise NO.
 * \gne
 * \jap
 * 書き込み禁止属性が付いているファイルかどうか調べます。
 * @return 書き込み禁止属性が付いている場合はYESを、それ以外の場合はNOを返します。
 * \paj
 */
- (BOOL)isReadOnly
{
    return (self._attribute & 0x01) != 0;
}

#if 0
/**
 * \eng
 * 既にダウンロードしたファイルかどうか調べる。
 * これを利用するにはあらかじめ自分で属性をつけておく必要がある
 * \gne
 * \jap
 * 既にダウンロードしたファイルかどうか調べる。
 * これを利用するにはあらかじめ自分で属性をつけておく必要がある
 * \paj
 */
- (BOOL)isDownloaded
{
    return self._isDownloaded;
}
/**
 * \eng
 * 選択されたファイルかどうか調べる。
 * これを利用するにはあらかじめ自分で属性をつけておく必要がある
 * \gne
 * \jap
 * 選択されたファイルかどうか調べる。
 * これを利用するにはあらかじめ自分で属性をつけておく必要がある
 * \paj
 */
- (BOOL)isSelected
{
    return self._isSelected;
}
#endif

/**
 * \eng
 * Returns the timestamp of this item.
 * @return An NSDate object that contains the timestamp of this item.
 * \gne
 * \jap
 * タイムスタンプを返します。
 * @return タイムスタンプを格納したNSDataオブジェクトです。
 * \paj
 */
- (NSDate*)dateAsDate
{
    NSDateFormatter* aFormatter = [[NSDateFormatter alloc] init];
    [aFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* aString = [NSString stringWithFormat:@"%04u-%02u-%02u %02u:%02u:%02u",
        (((self._date >> 9)  & 0x1FF) + 1980),
         ((self._date >> 5)  & 0xF),
          (self._date        & 0x1F),
         ((self._time >> 11) & 0x1F),
         ((self._time >> 5)  & 0x3F),
         ((self._time        & 0x1F) * 2)
     ];
    NSDate* aDate = [aFormatter dateFromString:aString];
    return aDate;
}
/**
 * \eng
 * Returns the size in bytes of this item.
 * @return The number of bytes of this item.
 * \gne
 * \jap
 * ファイルサイズをbyte単位で返します。
 * @return byte単位のファイルサイズです。
 * \paj
 */
- (unsigned int)size
{
    return self._size;
}


@end



