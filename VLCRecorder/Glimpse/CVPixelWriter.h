//
//  CVPixelWriter.h
//  VLCRecorder
//
//  Created by 장웅 on 2018. 4. 5..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CVPixelWriter : NSObject
//@property(readonly) NSURL  *outputurl;
@property(readonly) CGSize  size;
@property(readonly) NSUInteger maxBufSize;
@property(nonatomic) double fps;
@property(nonatomic) NSDate *startDate;
@property(nonatomic) NSDate *endDate;
-(id)initWithSize:(CGSize)size maxBufSize:(NSUInteger)bufsz;
-(void)storeBuf:(UIImage*)buf;
-(void)write:(void(^)(NSError*))complete;
@end
