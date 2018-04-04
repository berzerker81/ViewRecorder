//
//  ViewController.m
//  VLCRecorder
//
//  Created by 장웅 on 2018. 3. 30..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import "ViewController.h"
#import "Glimpse.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewRecorder.h"

@interface ViewController ()

@end

@implementation ViewController
{
    VLCMediaPlayer * player;
    NSURL          * outputURL;
    ViewRecorder   * rec;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initPlayer];
    [self initRecorder];
    
    NSArray  * paths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docPath = [paths firstObject];
    NSURL    * pathURL = [NSURL fileURLWithPath:docPath];
    rec = [[ViewRecorder alloc] initWithBasePath:pathURL view:self.renderView];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)initPlayer
{
    NSString * mediaURLString = @"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_175k.mov";
    player = [[VLCMediaPlayer alloc] initWithOptions:@[@"-vvvv"]];
    player.drawable = self.renderView;
    player.media = [VLCMedia mediaWithURL:[NSURL URLWithString:mediaURLString]];
    
}

-(void)initRecorder
{

}

- (IBAction)play:(id)sender {
    
    [player play];
    
}
- (IBAction)stop:(id)sender {
    [player stop];
}
- (IBAction)recordStart:(id)sender {
    [rec startCapture:@"file.mp4"];
}

-(void)showLoading
{
    [self.loadingView setHidden:NO];
    [self.loadingView setUserInteractionEnabled:YES];
}

-(void)hideLoading
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingView setHidden:YES];
        [self.loadingView setUserInteractionEnabled:NO];
    });
}
- (IBAction)recordStop:(id)sender {
    [rec stopCapture:^(bool complete) {
        NSLog(@"record ok");
    }];
}
- (IBAction)show:(id)sender {
    AVPlayerViewController * apvc = [[AVPlayerViewController alloc] init];
    apvc.view.frame = self.view.bounds;
    
    NSURL * path = [rec outputURL];
    NSLog(@"path %@",path);
    apvc.player = [AVPlayer playerWithURL:path];
    [self presentViewController:apvc animated:YES completion:^{
        NSLog(@"present");
    }];
    
}





@end
