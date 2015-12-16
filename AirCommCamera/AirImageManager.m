//
//  AirImageManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/08.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "AirImageManager.h"
#import "Log.h"


@implementation DetectInfo


@end

@interface AirImageManager()

@property (nonatomic) CIDetector *detector;

@end

@implementation AirImageManager

+(AirImageManager*)getInstance
{
    static AirImageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AirImageManager new];
    });
    
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                            forKey:CIDetectorAccuracy];
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:nil
                                       options:options];
    }
    
    return self;
}

- (UIImage*)rotateImage:(UIImage*)img
{
    CGImageRef      imgRef = [img CGImage];
    CGContextRef    context;
    CGFloat         width = img.size.width;
    CGFloat         height = img.size.height;
    UIImageOrientation orientation = img.imageOrientation;
    
    NSLog(@"orientation:%ld width:%f height:%f", (long)orientation, width, height);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, img.scale);
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, width, 0);
    CGContextScaleCTM(context, 1, -1);
    CGContextRotateCTM(context, -M_PI);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    // imageOrientation:0になっているので、情報が失っている?
    UIImage*    oriImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSLog(@"oriImage orientation:%ld width:%f height:%f", (long)oriImage.imageOrientation, oriImage.size.width, oriImage.size.height);
    
    return oriImage;
}

-(UIImage*)resizeImageToFill:(UIImage*)orgImage bounds:(CGRect)bounds
{
    // 指定された画像の大きさのコンテキストを用意.
    UIGraphicsBeginImageContext(CGSizeMake(bounds.size.width, bounds.size.height));
    
    // コンテキストに自身に設定された画像を描画する.
    [orgImage drawInRect: bounds];
    
    // コンテキストからUIImageを作る.
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // コンテキストを閉じる.
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(UIImage*)resizeImage:(UIImage*)orgImage size:(CGSize)size
{
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    
    return [self resizeImageToFill:orgImage bounds:bounds];
}

-(UIImage*)resizeImageWithSameRatio:(UIImage*)orgImage size:(CGSize)size
{
    CGFloat width_ratio  = size.width / orgImage.size.width;
    CGFloat height_ratio = size.height / orgImage.size.height;
    CGFloat ratio = (width_ratio < height_ratio) ? width_ratio : height_ratio;
    CGRect bounds = CGRectMake(0, 0, size.width * ratio, size.height * ratio);
    
    return [self resizeImageToFill:orgImage bounds:bounds];
}

-(UIImage*)clipImage:(UIImage*)orgImage rect:(CGRect)rect
{
    float scale = orgImage.scale;
    // NG:
    //CGRect scaleRect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
    
    CGImageRef cgImage = CGImageCreateWithImageInRect(orgImage.CGImage, rect);
    UIImage *clipImage = [UIImage imageWithCGImage:cgImage scale:scale orientation:orgImage.imageOrientation];
    CGImageRelease(cgImage);
    
    return clipImage;
}

-(UIImage*)clipImage:(UIImage*)orgImage atOrigin:(CGPoint)origin withAspectRatio:(AirImageAspectRatio)ratio
{
    //CGFloat width = orgImage.size.width;
    //CGFloat height = orgImage.size.height;
    // memo:buffer sizeから切り出しサイズを計算
    CGFloat width = CGImageGetWidth(orgImage.CGImage);
    CGFloat height = CGImageGetHeight(orgImage.CGImage);
    CGFloat width_ratio = width;
    CGFloat height_ratio = height;
    float aspectRatio = 0.5625;
    
    // memo:imageOrientaionは正しく表示時の向きなので、表示時のwidth/heightベースにアスペクト比に切り取れば良い
    switch (ratio) {
        case AirImageAspectRatio4x3:
            aspectRatio = 0.75;
            break;
        case AirImageAspectRatio16x9:
            aspectRatio = 0.5625;
            break;
        default:
            break;
    }
    
    DEBUGLOG(@"orgImage.CGImage orientation(before crop):%ld width:%f height:%f", (long)orgImage.imageOrientation, width, height);
    
    // todo:bufferがportraitでもlandscapeでは同じ(画像向き(つまりデバイス向き?)で処理すれば良い)のはず
    switch (orgImage.imageOrientation) {
        case UIImageOrientationUp:
            // memo:w=width h=w*ratio
            width_ratio = width;
            height_ratio = width_ratio * aspectRatio;
            break;
        case UIImageOrientationRight:
            // h=height w=h*ratio 横向きbufferだが、画像を回転する必要がある(デバイスportrait向きで撮影)ので、小さい値heightを基準にする
            height_ratio = height;
            width_ratio = height_ratio * aspectRatio;
        default:
            break;
    }
    
    DEBUGLOG(@"orgImage.CGImage orientation(after crop):%ld width_ratio:%f height_ratio:%f aspectRatio:%f", (long)orgImage.imageOrientation, width_ratio, height_ratio, aspectRatio);
    
    CGRect clipRect = CGRectMake(origin.x, origin.y, width_ratio, height_ratio);
    return [self clipImage:orgImage rect:clipRect];
}

-(UIImage*)clipImage:(UIImage*)orgImage atOrigin:(CGPoint)origin withSize:(AirImageSize)size
{
    CGFloat width = orgImage.size.width;
    CGFloat height = orgImage.size.height;
    CGFloat width_ratio = width;
    CGFloat height_ratio = height;
    
    switch (size) {
        case AirImageSize1280x720:
            width = 1280;
            height = 720;
            break;
        case AirImageSize1920x1080:
            width = 1920;
            height = 1080;
            break;
        default:
            break;
    }
    
    switch (orgImage.imageOrientation) {
        case UIImageOrientationUp:
            width_ratio = height;
            height_ratio = width;
            break;
        case UIImageOrientationRight:
            width_ratio = width;
            height_ratio = height;
            break;
        default:
            break;
    }
    
    CGRect clipRect = CGRectMake(origin.x, origin.y, width_ratio, height_ratio);
    return [self clipImage:orgImage rect:clipRect];
}

-(int)exifOrientation:(UIImage*)image
{
    int orientation = 0;
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            orientation = 1;
            break;
        case UIImageOrientationDown:
            orientation = 3;
            break;
        case UIImageOrientationLeft:
            orientation = 8;
            break;
        case UIImageOrientationRight:
            orientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            orientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            orientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            orientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            orientation = 7;
            break;
        default:
            break;
    }
    return orientation;
    
}

-(NSArray*)detectFace:(UIImage*)image inBounds:(CGRect)bounds
{
    NSMutableArray *faces = [[NSMutableArray alloc] init];
    // 顔検出
    // memo: resizeしないと、実際画像サイズで処理される(座標に合わない)
    // todo: UIImageViewの表示モードによって、矩形がズレるな。調査
    // imageのsizeとframeの比率で調整。オリジナル写真で顔位置検出し、比率でframeにあった位置に変換
    UIImage *detectImage = [self resizeImageToFill:image bounds:bounds];
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:detectImage.CGImage];
    // UIImageOrientationUp
    //NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CIDetectorImageOrientation];
    
    // orientation for image that capture with iOS camera.
    //NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self exifOrientation:image]] forKey:CIDetectorImageOrientation];
    NSDictionary *imageOptions = @{
                                   CIDetectorSmile:@YES,
                                   CIDetectorEyeBlink:@YES,
                                   CIDetectorImageOrientation:[NSNumber numberWithInt:[self exifOrientation:detectImage]]
                                   };
    
    NSArray *array = [_detector featuresInImage:ciImage options:imageOptions];
    
    // CoreImageは、左下の座標が (0,0) となるので、UIKitと同じ座標系に変換
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -bounds.size.height);
    
    // 検出されたデータを取得
    for (CIFaceFeature *faceFeature in array)
    {
        DetectInfo *info = [[DetectInfo alloc] init];
        Face face;
        
        // 座標変換
        DEBUGLOG_RECT(bounds);
        DEBUGLOG_RECT(faceFeature.bounds);
        CGRect faceRect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        face.bounds = faceRect;
        DEBUGLOG_RECT(face.bounds);
        
        if (faceFeature.hasLeftEyePosition) {
            CGPoint leftEyePos = CGPointApplyAffineTransform(faceFeature.leftEyePosition, transform);
            face.leftEyePosition = leftEyePos;
            face.leftEyeClosed = faceFeature.leftEyeClosed;
        }
        face.hasLeftEye = faceFeature.hasLeftEyePosition;
        
        if (faceFeature.hasRightEyePosition) {
            CGPoint rightEyePos = CGPointApplyAffineTransform(faceFeature.rightEyePosition, transform);
            face.rightEyePosition = rightEyePos;
            face.rightEyeClosed = faceFeature.rightEyeClosed;
        }
        face.hasRightEye = faceFeature.hasRightEyePosition;
        
        if (faceFeature.hasMouthPosition) {
            CGPoint mouthEyePos = CGPointApplyAffineTransform(faceFeature.mouthPosition, transform);
            face.mouthPosition = mouthEyePos;
        }
        face.hasMouth = faceFeature.hasMouthPosition;
        
        if (faceFeature.hasFaceAngle) {
            face.faceAngle = faceFeature.faceAngle;
        }
        
        if (faceFeature.hasTrackingID) {
            face.trackingID = faceFeature.trackingID;
        }
        
        if (faceFeature.hasTrackingFrameCount) {
            face.trackingFrameCount = faceFeature.trackingFrameCount;
        }
        
        face.hasSmile = faceFeature.hasSmile;
        
        info.face = face;
        [faces addObject:info];
    }
    
    return faces;
}

// todo: return categories supported in current version
-(NSArray*)imageFilterCategories
{
    /* Categories */
    NSArray* categories = [NSArray arrayWithObjects:
        kCICategoryDistortionEffect,
        kCICategoryGeometryAdjustment,
        kCICategoryCompositeOperation,
        kCICategoryHalftoneEffect,
        kCICategoryColorAdjustment,
        kCICategoryColorEffect,
        kCICategoryTransition,
        kCICategoryTileEffect,
        kCICategoryGenerator,
        //@available(iOS 5.0, *)
        kCICategoryReduction,
        kCICategoryGradient,
        kCICategoryStylize,
        kCICategorySharpen,
        kCICategoryBlur,
        kCICategoryVideo,
        kCICategoryStillImage,
        kCICategoryInterlaced,
        kCICategoryNonSquarePixels,
        kCICategoryHighDynamicRange,
        kCICategoryBuiltIn,
        //@available(iOS 9.0, *)
        kCICategoryFilterGenerator,
        nil
    ];
    
    return categories;
}
-(NSArray*)imageFilterNamesInCategory:(NSString*)category
{
    NSMutableArray* filterNames = [[NSMutableArray alloc] init];
    
    if (category) {
        NSArray* allFilterNames = [CIFilter filterNamesInCategory:category];
        if (allFilterNames) {
            for (NSString* filterName in allFilterNames) {
                // todo: check if neccesary
                [filterNames addObject:filterName];
            }
        }
    }
    
    return filterNames;
}
-(NSArray*)imageFilterNamesInCategories:(NSArray*)categories
{
    NSMutableArray* filterNames = [[NSMutableArray alloc] init];
    
    if (categories) {
        NSArray* allFilterNames = [CIFilter filterNamesInCategories:categories];
        if (allFilterNames) {
            for (NSString* filterName in allFilterNames) {
                // todo: check if neccesary
                [filterNames addObject:filterName];
            }
        }
    }
    
    return filterNames;
}

-(UIImage*)imageFilteredWithName:(NSString*)name image:(UIImage*)image
{
    UIImage* filteredImage = nil;
    
    if (name && image) {
        CIImage *inputImage = [[CIImage alloc] initWithImage:image];
        CIFilter* filter = [CIFilter filterWithName:name];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        [filter setDefaults];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CIImage *outputImage = [filter outputImage];
        CGImageRef cgImage = [context createCGImage:outputImage
                                           fromRect:[outputImage extent]];
        filteredImage = [UIImage imageWithCGImage:cgImage];
    }
    
    return filteredImage;
}

-(NSArray*)imagesFilteredWithNames:(NSArray*)names image:(UIImage*)image
{
    NSMutableArray* filteredImages = [[NSMutableArray alloc] init];
    
    for (NSString* name in names) {
        UIImage* filteredImage = [self imageFilteredWithName:name image:image];
        // add any image filtered whatever it is nil.
        [filteredImages addObject:filteredImage];
    }
    
    return filteredImages;
}

-(CVPixelBufferRef)pixelBufferFromImage:(UIImage*)image
{
    if (image == nil) {
        return nil;
    }
    
    return [self pixelBufferFromCGImage:image.CGImage withOrientation:image.imageOrientation size:image.size];
}

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image withOrientation:(UIImageOrientation)orientation size:(CGSize)size
{
    // ピクセルバッファを作成するためのオプションを設定
    NSDictionary *options = @{
                              (NSString *)kCVPixelBufferCGImageCompatibilityKey : @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
                              };
    
    CVPixelBufferRef buffer = NULL;
    // memo:orientationによって、image.size.widthと異なる(orientation:0のサイズを取っている?)
    // image.size.xxxはorientationの情報を見て、システムが正常に回転した後の画像のxxxになっている（実際表示上の向きのxxxと同じ。デバイス/UIInterfaceなどの向きと関係ある）。
    // CGImageGetxxxは実際のバッファーからxxxの情報を取得する。例えば、landscapeでキャプチャーした場合、実際のデータはlandscape形式で作成されるとので、デバイスがportraitで正常に表示されても、landscapeデータのxxxになる
    CGFloat imageWidth = CGImageGetWidth(image);
    CGFloat imageHeight = CGImageGetHeight(image);
    //CGFloat width = size.width;
    //CGFloat height = size.height;
    
    DEBUGLOG(@"UIImage orientation(before):%ld width:%f height:%f", (long)orientation, imageWidth, imageHeight);
    
    // ピクセルバッファを作成
    CVPixelBufferCreate(kCFAllocatorDefault,
                        imageWidth,
                        imageHeight,
                        kCVPixelFormatType_32ARGB,// 4byte -> size:imageWidth * 4 * imageHeight
                        (__bridge CFDictionaryRef)options,
                        &buffer);
    
    // ピクセルバッファをロック(readonly:1?)
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // ピクセルバッファのベースアドレスのポインタを返す(描画用)
    void *base = CVPixelBufferGetBaseAddress(buffer);
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);//imageWidth * 4
    
    // memo:CGImageGetxxxと同じ
    DEBUGLOG(@"PixelImage(before) width:%zu height:%zu bytesPerRow:%zu", width, height, bytesPerRow);
    
    // カラースペースとコンテキストの作成
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    // memo:向きはあくまでの付加？情報(正しく表示される向き)。実際物理(バッファー)データと向きの情報は異なる可能性がある。
    // transform変換処理を行う場合、バッファーデータ（の向き：ピクセル？配置情報）を基準に変換する必要がある(contextが変換後描画できる配置にする)。
    CGContextRef context = CGBitmapContextCreate(
                                                 base,
                                                 width,
                                                 height,
                                                 8, // RGBのbit数(メモリ内のピクセルの各成分に使用するビット数) bitsPerComponent
                                                 //4 * width, // size per line (bytes) // 向き変換する時、heightになるので
                                                 bytesPerRow,// 向きと関係ないかも。実際変換後の向きに合わせる必要がある
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
#if true
    // todo:orientationの情報がなくなる？ので、座標変換が必要？
    // 存在する場合も、変換が必要（現状portrait表示にしているので、landscape->portraitが必要）
    // 実際のorientaionのままvideoを作成し、再生時正しくtransformを設定すれば、正常に表示(QuickTime)される？が、
    // apple以外の場合、向きが正常に表示されないかも。ビデオ(H264)の仕様であれば問題ない？(transformの情報があればFacebookなどでも正常に表示される？)
    switch (orientation) {// todo:座標系は左上になっているようだ??
            // todo:orientation情報がある場合、上向きに表示されるはず(システムが左?/右?に回転して表示？)
            // 情報がなくなるので、基準方向(landscape/right)になるので、上向きに手動で90度回転(右?/左?)が必要
            // 座標系、デバイスの向き、画像向きなどの変換について調査!!!
        case UIImageOrientationRight:// カメラでLandescapleRightでキャプチャー
            /*CGContextTranslateCTM(context, width, height);
             CGContextScaleCTM(context, 1, -1);// 左右反転になる
             CGContextRotateCTM(context, M_PI_2);*/
            //CGContextTranslateCTM(context, -height, -width);// OK 変換順番要注意(上記と同じ)
            /*
             CGContextTranslateCTM(context, width, 0);
             CGContextRotateCTM(context, M_PI_2);
             */ // 180回転になっている。ただ、左右反転になっていない。座標系は左上のようだ？？
            CGContextTranslateCTM(context, 0, height);
            CGContextRotateCTM(context, -M_PI_2);
            CGContextDrawImage(context, CGRectMake(0, 0, height, width), image);
            //CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
            break;
        case UIImageOrientationUp:// Portraitキャプチャー。iOS以外で撮った写真でorientaion情報がない場合もここに入る
            // context(空buffer)へimageを書き込み
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        default:
            // LandscapeLeft/Portraitキャプチャーした画像はとりあえず非サポート。エラー出すか画像非選択非するか
            break;
    }
    
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // memo:CGImageGetxxxと同じ
    DEBUGLOG(@"PixelImage(after) width:%zu height:%zu bytesPerRow:%zu", width, height, bytesPerRow);
    
    imageWidth = CGImageGetWidth(image);
    imageHeight = CGImageGetHeight(image);
    //CGFloat width = size.width;
    //CGFloat height = size.height;
    
    DEBUGLOG(@"UIImage orientation(after):%ld width:%f height:%f", (long)orientation, imageWidth, imageHeight);
    
#endif
    
#if false // todo:不要？逆転になる？横方向の画像はOK。縦方向の写真は90度回転になるので、対応が必要
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    // CG座標原点:左下
    // a=cos b=-sin
    // c=sin d=cos
    
    // a=1 b=0  tx=0
    // c=0 d=-1 ty=height
    // ->x'=ax+by=x
    //   y'=cx+dy=-y
    // ->x軸に上下裏返し反転->上にheight移動->上下反転
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, width);
    
    CGContextConcatCTM(context, flipVertical);
    
    // a=-1 b=0  tx=width
    // c=0  d=1  ty=0
    // ->x'=-x
    //   y'=y
    // ->y軸に左右裏返し(元に戻る)反転->右にwith移動
    // ->最終的に左下座標系が左上座標系になる
    CGAffineTransform flipHorizontal = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
    
    CGContextConcatCTM(context, flipHorizontal);
    
    //#else
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    /*
     // a=cos b=-sin
     // c=sin d=cos
     // degree:90 -> 0, -1, 1, 0
     CGAffineTransform rotation = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
     CGContextConcatCTM(context, rotation);
     */
    
    CGFloat angle = [self imageRotationAngle:orientation];
    NSLog(@"orientation:%ld angle:%f width:%f height:%f", (long)orientation, angle, width, height);
    if (angle != 0 ) {
        // memo:Rotationすると正常に動画が作成されない？真っ暗になる
        //CGContextConcatCTM(context, CGAffineTransformMakeRotation(angle));
        //CGContextRotateCTM(context, angle);
    }
    /* // NG: width:3264.000000 height:2448.000000 .  width > height when portrait
     NSLog(@"width:%f height:%f", width, height);
     if (height > width) {
     
     CGFloat angle = -90 * M_PI / 180.0;
     CGContextConcatCTM(context, CGAffineTransformMakeRotation(angle));
     }*/
    
#endif
    
    // 画像をコンテキストに描画
    //CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // カラースペースとコンテキストを解放
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    // ピクセルバッファのロックを解除
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return buffer;
}

@end
