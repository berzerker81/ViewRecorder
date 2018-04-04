//
//  ViewController.h
//  VLCRecorder
//
//  Created by 장웅 on 2018. 3. 30..
//  Copyright © 2018년 장웅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DynamicMobileVLCKit/VLCMediaPlayer.h>
@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *renderView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *soundStatus;


@end

