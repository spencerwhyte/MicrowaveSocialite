//
//  CollectBeepViewController.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFTView.h"
#import "Settings.h"

@interface CollectBeepViewController : UIViewController <UIAlertViewDelegate>
@property BOOL isRecording;
@property UIButton * recordOrStopButton;
@property FFTView * fftView;
@end
