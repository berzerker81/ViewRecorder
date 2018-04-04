//
//  RecordManager.h
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 3..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>
typedef enum {
    RecorderState_
    
    
}RecorderState;
typedef void(^recordEnd)(bool);
@interface ViewRecorder : NSObject<RPScreenRecorderDelegate>
@property(weak) UIView* view;
@property(strong) NSURL* path;
@property(nonatomic) NSString* fileName;
@property(nonatomic) float videoFrameRate;
@property(readonly) CGSize videoSize;
@property(nonatomic) bool recording;
@property(nonatomic) NSURL * outputURL;
@property(strong) recordEnd completion;
-(id)initWithBasePath:(NSURL*)path view:(UIView*)view;
-(void)startCapture:(NSString*)fileName;
-(void)stopCapture:(recordEnd)complete;
-(NSURL*)fullPath;
@end
