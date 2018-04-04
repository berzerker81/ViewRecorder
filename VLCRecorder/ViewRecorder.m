//
//  RecordManager.m
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 3..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import "ViewRecorder.h"
#import "Glimpse.h"



/*
 //https://medium.com/@giridharvc7/replaykit-screen-recording-8ee9a61dd762
 //AudioRecord   Apple RosyWriter
 */

@implementation ViewRecorder
{
    __weak RPScreenRecorder * _audioRecorder;
    
    AVAssetWriter                         * _writer;
    AVAssetWriterInputPixelBufferAdaptor  * _adapter;
    
    AVAssetWriterInput                    * _micInput;
    AVAssetWriterInput                    * _audioInput;
    AVAssetWriterInput                    * _videoInput;
    
    NSMutableArray                        * _frameBuffer;
    NSMutableArray                        * _previousSecondTimestamps;

    NSUInteger                              _frameCount;
    double                                  _interval;
    
    Glimpse                               * _videoRecorder;
    
    NSURL                                 * _videoSour;
    

}
-(id)initWithBasePath:(NSURL*)path view:(UIView*)view
{
    self = [super init];
    if(self)
    {
        _path = path;
        _view = view;
        _audioRecorder = [RPScreenRecorder sharedRecorder];
        _audioRecorder.delegate = self;
        _videoSize = CGSizeMake(_view.frame.size.width, _view.frame.size.height);
        
        //오디오 세팅
        NSDictionary*  audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                              [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                              [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                              [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                              nil];
        _micInput   = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        _micInput.expectsMediaDataInRealTime = YES;
        _audioInput.expectsMediaDataInRealTime = YES;
        
        //비디오 세팅
        NSDictionary *videoOutputSettings = @{
                                   AVVideoCodecKey: AVVideoCodecTypeH264,
                                   AVVideoWidthKey: @(_videoSize.width),
                                   AVVideoHeightKey: @(_videoSize.height)
                                   };
        
        
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
        
        
        NSDictionary *attributes = @{
                                     (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
                                     (NSString *)kCVPixelBufferWidthKey: @(_videoSize.width),
                                     (NSString *)kCVPixelBufferHeightKey: @(_videoSize.height)
                                     };
        _adapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput sourcePixelBufferAttributes:attributes];
        
        _previousSecondTimestamps = [NSMutableArray array];
        
        _videoRecorder = [[Glimpse alloc] init];
        
    }
    return self;
}

-(void)destory
{
    _audioRecorder = nil;
    _writer = nil;
     _adapter = nil;
    
     _micInput = nil;
     _audioInput = nil;
     _videoInput = nil;
    
    [_frameBuffer removeAllObjects];
    _frameBuffer = nil;
    [_previousSecondTimestamps removeAllObjects];
    _previousSecondTimestamps = nil;
    
     _frameCount = 0;
     _interval   = 0;
    
     _videoRecorder = nil;
}

-(void)dealloc
{
    [self destory];
    _path = nil;
    _view = nil;
    _audioRecorder = nil;
    _videoRecorder = nil;
}

-(void)startCapture:(NSString*)fileName
{
    //WriterSetting
    _fileName = fileName;
    NSError * error = nil;
    _frameCount = 0;
    
    NSArray * contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path.path error:nil];
    
    for (NSString * eachFile in contents)
    {
        if([eachFile isEqualToString:_fileName])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self.path URLByAppendingPathComponent:eachFile].path error:nil];
        }
        
    }
    
    NSURL * url = [self.path URLByAppendingPathComponent:fileName];
    _writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeMPEG4 error:&error];
    
    [_writer addInput:_micInput];
    [_writer addInput:_audioInput];

    [_audioRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        
        if(self.recording == NO)
        {
            self.recording = YES;
            [self startVideoRec];
        }
        
        if(CMSampleBufferDataIsReady(sampleBuffer))
        {
            
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            
            
            if(_writer.status == AVPlayerStatusUnknown)
            {
                [_writer startWriting];
                [_writer startSessionAtSourceTime:timestamp];
            }
            
            switch (bufferType) {
                case RPSampleBufferTypeAudioApp:
                {
                    
                        if(_audioInput.isReadyForMoreMediaData)
                        {
                            [_audioInput appendSampleBuffer:sampleBuffer];
                            NSLog(@"Append AudioBuf");
                        }
                }
                    break;
                    
                case RPSampleBufferTypeAudioMic:
                {
                    
                    if(_micInput.isReadyForMoreMediaData)
                    {
                        [_micInput appendSampleBuffer:sampleBuffer];
                        NSLog(@"Append MicBuf");
                    }
                }
                    break;
                   
                case RPSampleBufferTypeVideo:
                {
                    //쓰레드 오류때문에 사용하지 않음. 별도 타이머로 구현
                }
                    break;
                    
                default:
                    break;
            }
            
        }
        
    } completionHandler:^(NSError * _Nullable error) {
        
    }];
}

-(void)startVideoRec
{
    //VideoRec
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [_videoRecorder startRecordingView:self.view onCompletion:^(NSURL *fileOuputURL) {
            _videoSour = fileOuputURL;
        }];

    });
}

-(void)stopCapture:(recordEnd)complete
{
    self.completion = complete;
    [_audioRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
        if(error ==nil)
        {
            [_writer finishWritingWithCompletionHandler:^{
                NSLog(@"complete");
                
                //VideoRecorder 정지
                [_videoRecorder stop];
                
                NSURL * audio = [self.path URLByAppendingPathComponent:self.fileName];
                
//                NSURL * video = _videoSour;
                
                
                dispatch_async(dispatch_queue_create("com.hipuppy.waitEncode", DISPATCH_QUEUE_CONCURRENT), ^{
                    while (_videoSour == nil)
                    {
                        NSLog(@"Wait");
                        sleep(1);
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self combineFileAudioSource:audio videoSource:_videoSour];
                    });
                });
            }];
        }else
        {
            
            NSLog(@"finish - error %@",error.localizedDescription);
            complete(NO);
        }
    }];
}

#pragma mark - combine

-(void)combineFileAudioSource:(NSURL*)audio videoSource:(NSURL*)video
{
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                                        ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                         atTime:kCMTimeZero error:nil];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:kCMTimeZero error:nil];
    
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetHighestQuality];
    
    NSString* videoName = @"export.mov";
    
    
//    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    NSString *exportPath = [self.path URLByAppendingPathComponent:videoName].path;
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = [self.path URLByAppendingPathComponent:videoName];
    _assetExport.shouldOptimizeForNetworkUse = YES;
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
       
        self.outputURL = _assetExport.outputURL;
        self.completion(YES);
    }];
}

#pragma mark - RPScreenRecorderDelegate
- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder
{
    if(screenRecorder.available)
    {
        
    }
    
}
#pragma mark - get Path
-(NSURL*)fullPath
{
    return [_path URLByAppendingPathComponent:self.fileName];
}

@end
