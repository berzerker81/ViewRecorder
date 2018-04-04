//
//  AudioRecorder.h
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 2..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
//#import "AudioEngine.h"
typedef void(^recordFinish)(bool);
@interface AudioRecorder : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate>
{
    @private
    dispatch_queue_t recordingQueue;
    
}
@property(nonatomic,readonly) NSURL * fullpath;
@property(nonatomic) AVCaptureVideoDataOutput * videoOutput;
@property(nonatomic) AVCaptureAudioDataOutput * audioOutput;
@property(nonatomic) AVCaptureConnection * audioConnection;
@property(nonatomic) AVCaptureConnection * videoConnection;

@property(nonatomic) AVAssetWriter * assetWriter;
@property(nonatomic) AVAssetWriterInput * audioInput;
@property(nonatomic) AVAssetWriterInput * videoInput;


-(void)startRecorder:(NSURL*)filePath;
-(void)endRecord:(recordFinish)finish;
@end
