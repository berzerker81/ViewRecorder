//
//  UIView+capture.m
//  PetSafer
//
//  Created by 장웅 on 2018. 3. 14..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import "UIView+capture.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES3/gl.h>
#import <MobileVLCKit/MobileVLCKit.h>


@implementation UIView (capture)


-(NSData*)saveCurrentContext:(CGSize)size
{
    GLenum error = GL_NO_ERROR;
    
//    GLint viewport[4];
//    glGetIntegerv(GL_VIEWPORT, viewport);
//    int width = viewport[2];
//    int height = viewport[3];
    
    int width = size.width;
    int height = size.height;
    
    int x = 0, y = 0;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    glFinish();
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    NSData *pixelsRead = [NSData dataWithBytes:data length:dataLength];
    
    error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"error happend, error is %d, line %d",error,__LINE__);
    }
    
    free(data);
    
    return pixelsRead;
}

-(void)renderData:(NSData*)data
{
    
}


+(UIImage*)toImagedata:(NSData*)data:(CGSize)size
{
//    GLint viewport[4];
//    glGetIntegerv(GL_VIEWPORT, viewport);
//
//
//    int width = viewport[2];
//    int height = viewport[3];
    int width = size.width;
    int height = size.height;
    if(width * height <= 0) return nil;
    
    int dataLength = width * height * 4;
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, [data bytes], dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
//    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    return image;
}

-(UIImage*)snapUIImageSize:(int)width height:(int)height
{
    GLenum error = GL_NO_ERROR;
    
    NSInteger x = 0, y = 0;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    NSData *pixelsRead = [NSData dataWithBytes:data length:dataLength];
    
    error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"error happend, error is %d, line %d",error,__LINE__);
    }
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    return image;
}




@end
