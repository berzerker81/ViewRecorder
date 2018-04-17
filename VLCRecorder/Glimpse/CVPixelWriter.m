//
//  CVPixelWriter.m
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 5..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import "CVPixelWriter.h"
#import <AVFoundation/AVFoundation.h>

@implementation CVPixelWriter
{
    //2차원적으로 버퍼링을 담는다.
    NSMutableArray                       * _totalBufs;
    NSMutableArray                       * _curBufs;
    NSMutableArray                       * _outputFiles;
    
    //출력된 파일들
//    NSMutableArray                       * _inputs;
//    NSMutableArray                       * _adaptors;
    
    AVAssetWriter                        * _writer;
    CMTime                                 _present;
    AVAssetWriterInput                   * _videoInput;
    AVAssetWriterInputPixelBufferAdaptor * _adaptor;
    NSTimeInterval                         _sleepOffset;
}

- (NSURL *)createFileOutputURLWithNum:(int)num
{
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    NSString *filename          = [NSString stringWithFormat:@"cvwrite%01d.mov", num];
    NSString *path              = [NSString stringWithFormat:@"%@/%@", documentDirectory, filename];
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:path])
        [fileManager removeItemAtPath:path error:nil];
    
    NSLog(@"OUTPUT: %@", path);
    return [NSURL fileURLWithPath:path];
}

-(id)initWithSize:(CGSize)size maxBufSize:(NSUInteger)bufsz
{
    self = [super init];
    
    if(self)
    {
//        _outputurl = [self createFileOutputURL];
        _size      = size;
        _maxBufSize = bufsz;
        _totalBufs = [NSMutableArray array];
        _curBufs   = [NSMutableArray arrayWithCapacity:_maxBufSize];
        _outputFiles = [NSMutableArray array];
//        _adaptors  = [NSMutableArray array];
//        _inputs    = [NSMutableArray array];
    }
    
    return self;
}

-(void)storeBuf:(UIImage *)buf
{
    if(_curBufs.count > _maxBufSize)
    {
        [_totalBufs addObject:_curBufs.copy];
        [_curBufs   removeAllObjects];
    }
    
    [_curBufs addObject:buf];
}


void (^complte)(NSError*);

-(void)write:(void(^)(NSError*))complete
{
    complte = complete;

    //모두 담고 준비함.
    if(_curBufs.count > 0)
    {
        [_totalBufs addObject:_curBufs.copy];
        [_curBufs   removeAllObjects];
    }
    
    self.endDate = [NSDate date];
    int allFrameBufferCnt = 0;
    
    for (NSArray * bufs in _totalBufs)
    {
        allFrameBufferCnt += bufs.count;

    }
    
    NSTimeInterval startTimeDiff    = [self.startDate timeIntervalSinceNow];
    NSTimeInterval endTimeDiff      = [self.endDate timeIntervalSinceNow];
    _sleepOffset      = ((endTimeDiff - startTimeDiff) / allFrameBufferCnt);
    
    int counter = 0;
    [self loopWrite:&counter];
}

void (^loopComplete)(void) = ^(void){
    
};

-(void)loopWrite:(int*)counter
{
    
    __block int ct = *counter;
    [self writeIndex:ct completion:^(NSError * error)
    {
        if(error == nil)
        {
            ct++;
            if(ct >= _totalBufs.count){
//                complte();
                loopComplete();
                return;
            }
            [self loopWrite:&ct];

        }
        
    }];
    
}

-(void)writeIndex:(int)index completion:(void(^)(NSError*))completion
{
    @autoreleasepool{
        NSArray * eachBuf = [_totalBufs objectAtIndex:index];
        _writer  = nil;
        [self allocWriter:index];
        [self allocInput];
        [_writer startWriting];
        [_writer startSessionAtSourceTime:kCMTimeZero];
        
        for (UIImage * imgBuf in eachBuf)
        {
            
            if(_videoInput.readyForMoreMediaData)
            {
                @autoreleasepool
                {
                    int imgIdx = (int)[eachBuf indexOfObject:imgBuf];
                    //                printf("increment %d\n",imgIdx + index*self.maxBufSize);
                    _present = CMTimeMake(imgIdx + index * self.maxBufSize, self.fps);
                    
                    CVPixelBufferRef buf = [self pixelBufferForImage:imgBuf];
                    bool result = [_adaptor appendPixelBuffer:buf withPresentationTime:_present];
                    
                    if(result == false)
                    {
                        NSLog(@"error");
                        NSLog(@"%@",_writer.error.localizedDescription);
                        complte([_writer error]);
                        return;
                    }
                    
                    if(buf)
                    {
                        CVPixelBufferRelease(buf);
                    }
                    
                    [NSThread sleepForTimeInterval:_sleepOffset];
                }
            }
        }
        
        [_videoInput markAsFinished];
        
        [_writer finishWritingWithCompletionHandler:^{
            
            CVPixelBufferPoolRelease(_adaptor.pixelBufferPool);
            _adaptor = nil;
            _videoInput = nil;
            completion(nil);
        }];
        
    }
    
}


- (CVPixelBufferRef)pixelBufferForImage:(UIImage *)image
{
    CGImageRef cgImage = image.CGImage;
    
    NSDictionary *options = @{
                              (NSString *)kCVPixelBufferCGImageCompatibilityKey: @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES)
                              };
    CVPixelBufferRef buffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &buffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    void *data                  = CVPixelBufferGetBaseAddress(buffer);
    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
    CGContextRef context        = CGBitmapContextCreate(data, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, CVPixelBufferGetBytesPerRow(buffer), colorSpace, (kCGBitmapAlphaInfoMask & kCGImageAlphaNoneSkipFirst));
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return buffer;
}

#pragma mark - make Writer
-(void)allocWriter:(int)num
{
    NSError * error = nil;
    NSURL * url = [self createFileOutputURLWithNum:num];
    [_outputFiles addObject:url];
    _writer = [[AVAssetWriter alloc] initWithURL:url
                                        fileType:AVFileTypeQuickTimeMovie
                                           error:&error];
    
    url = nil;
}

-(void)allocInput
{
    NSDictionary *settings = @{
                               AVVideoCodecKey: AVVideoCodecTypeH264,
                               AVVideoWidthKey: @(self.size.width),
                               AVVideoHeightKey: @(self.size.height)
                               };
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    
    NSDictionary *attributes = @{
                                 (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
                                 (NSString *)kCVPixelBufferWidthKey: @(self.size.width),
                                 (NSString *)kCVPixelBufferHeightKey: @(self.size.height)
                                 };
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput sourcePixelBufferAttributes:attributes];
    
    [_writer addInput:_videoInput];
    
//    [_inputs addObject:videoInput];
//    [_adaptors addObject:adaptor];
    
    _videoInput.expectsMediaDataInRealTime = YES;
}

#pragma mark - dispose Writer
-(void)disposeInput:(AVAssetWriterInput*)input adaptor:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
{
    
}
@end
