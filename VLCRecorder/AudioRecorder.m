//
//  AudioRecorder.m
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 2..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import "AudioRecorder.h"


@interface AudioRecorder()
//@property(nonatomic)AudioEngine * engine;
@end

@implementation AudioRecorder

-(id)init
{
    self = [super init];
    {
        recordingQueue = dispatch_queue_create("record.queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)startRecorder:(NSURL*)filePath
{
    _fullpath = filePath;
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:_fullpath fileType:AVFileTypeQuickTimeMovie error:nil];
    self.assetWriter.movieFragmentInterval = kCMTimeInvalid;
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    
    NSDictionary * audioSetting = @{
                                    AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                    AVNumberOfChannelsKey:@(2),
                                    AVSampleRateKey:@(44100.0),
                                    AVEncoderBitRateKey:@(192000)
                                    };
    
    NSDictionary * videoSetting = @{};
    
    
}
-(void)endRecord:(recordFinish)finish
{
}
@end
