//
//  UIView+capture.h
//  PetSafer
//
//  Created by 장웅 on 2018. 3. 14..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (capture)
-(UIImage*)snapUIImageSize:(int)width height:(int)height;
-(NSData*)saveCurrentContext:(CGSize)size;
+(UIImage*)toImagedata:(NSData*)data:(CGSize)size;
@end
