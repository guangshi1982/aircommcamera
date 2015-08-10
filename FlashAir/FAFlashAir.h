/**
 *  FAFlashAir.h
 *
 *  Copyright (c) 2013 Toshiba Corporation. All rights reserved.
 *  Created by kitano, Fixstars Corporation on 2013/11/28.
 */

#import <Foundation/Foundation.h>
#import "FAItem.h"

/**
 * \eng
 * \gne
 * \jap
 * delegate用のプロトコル宣言
 *
 * 非同期通信でのファイルリスト取得(requestFileList)を実行する際に必要となる
 * \paj
 */
@protocol FAFlashAirDelegate <NSObject>
/**
 * \eng
 * \gne
 * \jap
 * requestFileListが成功したときに呼び出されるメソッド
 * @param filelist FAItemの配列
 * \paj
 */
- (void)FAFlashAirSuccessRequest:(NSArray *) filelist ;
/**
 * \eng
 * \gne
 * \jap
 * requestFileListが失敗したときに呼び出されるメソッド
 * @param anError エラーオブジェクトへの参照
 * \paj
 */
- (void)FAFlashAirErrorRequest:(NSError **) anError;
@end



@interface FAFlashAir : NSObject {
	/**
	 * \eng
	 * \gne
	 * \jap
	 * FlashAirのホスト名
	 * \paj
	 */
    NSString* _hostname; 
	/**
	 * \eng
	 * \gne
	 * \jap
	 * ファームウェアバージョン
	 * \paj
	 */
    int _fwversion;
	/**
	 * \eng
	 * \gne
	 * \jap
	 * カレントディレクトリのパス
	 * \paj
	 */
    NSString* _currentdir;  
}

/**
 * \eng
 * \gne
 * \jap
 * FlashAirのホスト名
 * \paj
 */
@property (nonatomic, copy) NSString *_hostname;  
/**
 * \eng
 * \gne
 * \jap
 * ファームウェアバージョン
 * \paj
 */              
@property (nonatomic) int _fwversion;                           
/**
 * \eng
 * \gne
 * \jap
 * カレントディレクトリのパス
 * \paj
 */
@property (nonatomic, copy) NSString *_currentdir;
/**
 * \eng
 * \gne
 * \jap
 * デリゲート
 * \paj
 */
@property (nonatomic,assign) id<FAFlashAirDelegate> delegate;   


extern const int kFSFW01_00_00;       /**< Ver1.00.00 */
extern const int kFSFW01_00_03;       /**< Ver1.00.03 */
extern const int kFSFW02_00_00;       /**< Ver2.00.00 */
extern const int kFSFW02_00_02;       /**< Ver2.00.02 */


/**
 * \eng
 * AP mode.
 * \gne
 * \jap
 * APモード
 * \paj
 */
extern const int kFSAppModeAP;
/**
 * \eng
 * STA mode.
 * \gne
 * \jap
 * STAモード
 * \paj
 */
extern const int kFSAppModeSTA;
/**
 * \eng
 * BRG mode.
 * \gne
 * \jap
 * BRGモード
 * \paj
 */
extern const int kFSAppModeBRG;
/**
 * \eng
 * AP mode. WiFi is turned on when booting.
 * \gne
 * \jap
 * 自動起動のAPモード
 * \paj
 */
extern const int kFSAppModeAPAuto;
/**
 * \eng
 * STA mode. WiFi is turned on when booting.
 * \gne
 * \jap
 * 自動起動のSTAモード
 * \paj
 */
extern const int kFSAppModeSTAAuto;   
/**
 * \eng
 * BRG mode. WiFi is turned on when booting.
 * \gne
 * \jap
 * 自動起動のBRGモード
 * \paj
 */
extern const int kFSAppModeBRGAuto;   


typedef enum : NSInteger{
	/**
	 * \eng
	 * Version does not match.
	 * \gne
	 * \jap
	 * バージョンが合わない
	 * \paj
	 */
    kFSErrorInvalidVersion,
	/**
	 * \eng
	 * HTTP request timed out.
	 * \gne
	 * \jap
	 * タイムアウト
	 * \paj
	 */
    kFSErrorConnectionTimeOut         
}kFSErrorCodeList;




//ホスト名付きコンストラクタ
- (id) initWithHostname:(NSString *) hostname;

//ユーティリティ
- (bool) changeDir:(NSString *) path error:(NSError **)anError;           //カレントディレクトリのセット
- (NSData *) getFile:(NSString *) path error:(NSError **)anError;         //イメージ取得
- (NSData *) getThumbnail:(NSString *) path error:(NSError **)anError;     //サムネイル1件取得
- (NSArray *) getFileList:(NSError **)anError;                            //100:カレントディレクトリのファイルリスト取得(FAItemのArray)
- (int) getFileCount:(NSError **)anError;                                //101:カレントディレクトリのファイル数取得
- (void) requestFileList:(NSError **)anError;                               //非同期でのカレントディレクトリのファイルリスト取得

//プリミティブなAPI関数
//command.cgi系
- (NSArray *) getFileListWithDirectory:(NSString*) path error:(NSError **)anError;    //100:パス指定付きファイルリスト取得
- (int) getFileCountWithDirectory:(NSString*) path error:(NSError **)anError;        //101:パス指定付きファイル数取得
- (bool) getFileUpdate:(NSError **)anError;                                         //102:アップデート情報取得
- (NSString *) getSSID:(NSError **)anError;                                           //104:SSID取得
- (NSString *) getNetworkPassword:(NSError **)anError;                                //105:ネットワークパスワードの取得
- (NSString *) getMacAddress:(NSError **)anError;                                     //106:MACアドレスの取得
- (int) getFirmwareVersion:(NSError **)anError;                                     //108:ファームウェアバージョンの取得(定数を参照)

//ここから1.00.03+
- (NSString *) getCardIdentifier:(NSError **)anError;                                 //120:Card Identifier(CID)の取得
- (NSDictionary *) getFreeSector:(NSError **)anError;                               //140:空きセクターの取得

//ここから2.00.00+
- (NSString *) getControlImage:(NSError **)anError;                                   //109:制御イメージパスの取得
- (int) getAppmode:(NSError **)anError;                                             //110:無線LANモード(APPMODE)の取得
- (int) getAppauto:(NSError **)anError;                                             //111:無線LANタイムアウト(APPAUTO)の取得
- (NSString *) getAppInfo:(NSError **)anError;                                        //117:アプリケーション独自情報(APPINFO)の取得
- (NSString *) getRegister:(int) addr length:(int) len error:(NSError **)anError;     //130:共有メモリからのデータ取得
- (bool) setRegister:(int) addr length:(int) len data:(NSString*) data error:(NSError **)anError; //131:共有メモリへのデータ書き込み
- (bool) setPhotoShareMode:(NSDate *)date directory:(NSString *)path error:(NSError **)anError;                 //200:フォトシェアモードの有効化
- (bool) releasePhotoShareMode:(NSError **)anError;                                 //201:フォトシェアモードの無効化
- (bool) getPhotoShareMode:(NSError **)anError;                                     //202:フォトシェアモードの状態取得
- (NSString *) getPhotoShareModeSSID:(NSError **)anError;                             //203:フォトシェアモードのSSID取得


//config.cgi系
- (bool) setConfig:(NSString *) mastercode params:(NSDictionary *) params error:(NSError **)anError;               //まとめてセット


//upload.cgi系
- (bool) setWriteProtect:(NSError **)anError;                                       //ホスト機器からの書き込み禁止
- (bool) setSystemTime:(NSDate *)datetime error:(NSError **)anError;                //システム時間の設定
- (bool) deleteFile:(NSString *)path error:(NSError **)anError;                     //ファイルの削除
- (bool) setUploadDirectory:(NSError **)anError;                              //カレントディレクトリをアップロード先に設定
- (bool) setUploadDirectoryWithPath:(NSString *)path error:(NSError **)anError;     //アップロード先を設定

- (bool) uploadBinary:(NSData *)data filename:(NSString *)filename error:(NSError **)anError;    //バイナリファイルのアップロード
- (bool) uploadText:(NSString *)data filename:(NSString *)filename error:(NSError **)anError;    //テキストのアップロード
@end
