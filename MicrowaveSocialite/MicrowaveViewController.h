//
//  MicrowaveViewController.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Settings.h"

#import "CollectBeepViewController.h"
#import "FFTView.h"
#import "FoodManager.h"
#import <VLBCameraView/VLBCameraView.h>
#import "FoodManagerDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "LandscapeLeftViewController.h"
#import "SettingsTableViewController.h"

@interface MicrowaveViewController : UIViewController<TargetFrequencyDelegate, FoodManagerDelegate>
@property FFTView * fftView;

@property FoodManager * foodManager;

@property AVCaptureStillImageOutput * stillImageOutput;

@property (copy) void (^photoCompletion)(UIImage * photo);

@property int countdownIndex;

@property UILabel * countdownLabel;

@property NSTimer * countdownTimer;

@property UIView * whiteView;

@property UIButton * settingsButton;

@property BOOL isAnimatingBeep;

@property BOOL hasSetupView;

@property BOOL isRunningFFT;

-(void)didBecomeActive;
-(void)willResignActive;

@end
