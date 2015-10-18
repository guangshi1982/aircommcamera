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

@end
