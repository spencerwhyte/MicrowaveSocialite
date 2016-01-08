//
//  MicrowaveViewController.m
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import "MicrowaveViewController.h"

@interface MicrowaveViewController ()

@property AVCaptureSession * captureSession;

@property UIImageView * microwaveView;

@property AVCaptureVideoPreviewLayer *previewLayer;

@property UILabel * cookTimerView;

@property NSTimer * cookTimer;

@property int cookSeconds;
@property int cookMinutes;

@end

@implementation MicrowaveViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.hasSetupView = NO;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Custom initialization
    self.view.backgroundColor = [UIColor purpleColor];
    
    // Do any additional setup after loading the view.
    NSInteger beepFrequency = [[Settings sharedInstance] beepFrequency];
    if(beepFrequency == 0){ // If the user has not yet recorded a beep yet
        // Show them the UI that allows them to record the beep
        CollectBeepViewController * collectBeepFrequency = [[CollectBeepViewController alloc] init];
        
        LandscapeLeftViewController * containerNavView = [[LandscapeLeftViewController alloc] initWithRootViewController:collectBeepFrequency];
        

        [self presentViewController:containerNavView animated:YES completion:^(void){
            
        }];
    }else{ // The user has recorded a beep, so we should just get to listening for beeps and stuff
        [self startListening];
    }
    
}

/*
    Sets up the audio stuff to listen for beeps
    Sets up the food manager to figure out what
    is going on
 */
-(void)startListening{
    // Get a FFTView going..

    self.hasSetupView = YES;
    self.fftView = [[FFTView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width*0.7, self.view.frame.size.height, self.view.frame.size.width*0.3)];
    self.fftView.isInDiscoverMode = NO;
    self.fftView.targetDelegate = self;
    [self.fftView setFFTBackgroundColor:[UIColor purpleColor]];
    [self.fftView setFFTPrimaryColor:[UIColor orangeColor]];
    [self.fftView setFFTThresholdColor:[UIColor whiteColor]];
    [self.fftView setBackgroundColor:[UIColor purpleColor]];
    [self.view addSubview: self.fftView];
    
    self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.height/2 - self.view.frame.size.width*0.15, self.view.frame.size.width*0.3, self.view.frame.size.width*0.3, self.view.frame.size.width*0.3)];
    self.countdownLabel.backgroundColor = [UIColor blackColor];
    self.countdownLabel.text = @"3";
    self.countdownLabel.textAlignment = NSTextAlignmentCenter;
    self.countdownLabel.font =[self.countdownLabel.font fontWithSize:48];
    self.countdownLabel.alpha = 0;
    self.countdownLabel.textColor = [UIColor whiteColor];
    self.countdownLabel.layer.cornerRadius = 5;
    self.countdownLabel.layer.masksToBounds = YES;
    [self.view addSubview: self.countdownLabel];
    
    self.cookTimerView = [[UILabel alloc] initWithFrame:CGRectMake(10, 25, self.view.frame.size.width*0.5 - 5, self.view.frame.size.height*0.5 - 12.5)];
    self.cookTimerView.backgroundColor = [UIColor blackColor];
    self.cookTimerView.text = @"1:00";
    self.cookTimerView.textAlignment = NSTextAlignmentCenter;
    self.cookTimerView.font =[self.countdownLabel.font fontWithSize:48];
    self.cookTimerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self.cookTimerView.alpha = 0;
    self.cookTimerView.textColor = [UIColor whiteColor];
    self.cookTimerView.layer.cornerRadius = 5;
    self.cookTimerView.layer.masksToBounds = YES;
    [self.view addSubview: self.cookTimerView];
    

    self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 75, 25, 50, 50)];
    [self.settingsButton setTitle:@"⚙" forState:UIControlStateNormal];
    self.settingsButton.backgroundColor = [UIColor blackColor];
    self.settingsButton.layer.cornerRadius = 10;
    self.settingsButton.layer.masksToBounds = YES;
    self.settingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.settingsButton.titleLabel.font = [self.settingsButton.titleLabel.font fontWithSize:32];
    self.settingsButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.settingsButton];

    AVCaptureSession * session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    AVCaptureDevice *inputDevice = [self frontCamera];
    NSError * error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    CALayer *rootLayer = [[self view] layer];
    
    [rootLayer setMasksToBounds:YES];
    CGRect cameraFrame = CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height * 0.7);
    [previewLayer setFrame:cameraFrame];
    previewLayer.opacity = 0;

    self.previewLayer = previewLayer;
    
    [rootLayer insertSublayer:self.previewLayer atIndex:0];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:self.stillImageOutput];
    
    self.captureSession = session;
    
    self.whiteView = [[UIView alloc] initWithFrame:cameraFrame];
    self.whiteView.backgroundColor = [UIColor whiteColor];

    self.microwaveView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AlphaMicrowave"]];
    self.microwaveView.center = CGPointMake(self.view.frame.size.width/2 - self.microwaveView.frame.size.width/2, self.view.frame.size.height * 0.5 - );
    [self.view addSubview:self.microwaveView];
    
    self.foodManager = [[FoodManager alloc] init];
    
    self.foodManager.delegate = self;
    
    self.fftView.targetIndex =[[Settings sharedInstance] beepFrequency];
    [self.fftView startAnimation];
    
    
}

-(void)stopListening{
    [self.fftView stopAnimation];
    [self.fftView removeFromSuperview];
    [self.whiteView removeFromSuperview];
    [self.countdownLabel removeFromSuperview];
    [self.previewLayer removeFromSuperlayer];
    [self.captureSession stopRunning];
    [self.microwaveView removeFromSuperview];
    [self.cookTimerView removeFromSuperview];
    [self.cookTimer invalidate];
    [self.countdownTimer invalidate];
 
    self.fftView = nil;
    self.whiteView = nil;
    self.countdownLabel = nil;
    self.previewLayer = nil;
    self.captureSession = nil;
    self.microwaveView = nil;
    self.foodManager = nil;
    self.countdownTimer = nil;
    self.isAnimatingBeep = NO;
    self.cookTimer = nil;
}

-(void)didBecomeActive{
    [self.fftView startAnimation];
}

-(void)willResignActive{
    [self.fftView stopAnimation];
}



-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotate {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TargetFrequencyDelegate

// We have heard a microwave beep
- (void)didHitTargetFrequencyIndex:(NSInteger)frequencyIndex{
    // Tell the food guy about it
    [self.foodManager didHearBeepAtFrequencyWithIndex:(int)frequencyIndex];
    
    if(!self.isAnimatingBeep){
        self.isAnimatingBeep = YES;
        [UIView animateWithDuration:0.15 animations:^(void){
                [self.microwaveView setTransform:CGAffineTransformMakeScale(1.3, 1.3)];
                [self.microwaveView setTransform:CGAffineTransformMakeRotation(-3.14159/100)];
        }completion:^(BOOL finished){
            [UIView animateWithDuration:0.15 animations:^(void){
                [self.microwaveView setTransform:CGAffineTransformMakeRotation(3.14159/100)];
            }completion:^(BOOL finished){
                [UIView animateWithDuration:0.3 animations:^(void){
                [self.microwaveView setTransform:CGAffineTransformMakeScale(1, 1)];
                [self.microwaveView setTransform:CGAffineTransformMakeRotation(0)];
                }completion:^(BOOL finished){
                    self.isAnimatingBeep = NO;
                }];
            }];
        }];
    }
}





#pragma mark helper methods

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

-(void)startCountdown{

    if([self videoConnection]){
        [UIView animateWithDuration:1 animations:^(void){
            self.microwaveView.alpha = 0;
        }];
        self.previewLayer.opacity = 1;
        [self.captureSession startRunning];
        
        self.countdownIndex = 4;
        [self countDown];
        
        // Show the count down control
        self.countdownLabel.alpha = 0.5;
        
        // Start the count down timer
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
    }
}

-(void)countDown{
    self.countdownIndex--;
    self.countdownLabel.text = [NSString stringWithFormat:@"%d", self.countdownIndex];
    [self.countdownLabel setTransform:CGAffineTransformMakeScale(3, 3)];
    [UIView animateWithDuration:0.8 animations:^(void){
        [self.countdownLabel setTransform:CGAffineTransformMakeScale(1, 1)];
    }];
    
    if(self.countdownIndex == 0){
        [self countDownDidFinish];
        self.countdownLabel.alpha = 0;
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        
        self.whiteView.alpha = 1.0;
        [self.view addSubview:self.whiteView];
        
        [UIView animateWithDuration:0.4 animations:^(void){
            self.whiteView.alpha = 0.0;
        }completion:^(BOOL finished){
            [self.whiteView removeFromSuperview];
        }];
    }
}

-(AVCaptureConnection *)videoConnection{
    AVCaptureConnection *vc = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                vc = connection;
                break;
            }
        }
        if (vc) { break; }
    }
    return vc;
}

-(void)incrementCookTime{
    self.cookSeconds ++;
    if(self.cookSeconds == 60){
        self.cookSeconds = 0;
        self.cookMinutes++;
    }
    [self updateCookTimer];
}

-(void)updateCookTimer{
    NSString * timeString = [NSString stringWithFormat:@"%02d:%02d", self.cookMinutes, self.cookSeconds];
    [self.cookTimerView setText:timeString];
}


#pragma mark FoodManagerDelegate

-(void)takePhotoCompletion:(void (^)(UIImage *))callbackBlock{
    self.photoCompletion = callbackBlock;
    [self startCountdown];
}

-(void)mayHaveStartedCooking{
    self.cookMinutes = 0;
    self.cookSeconds = 0;
    [self updateCookTimer];
    [self.cookTimer invalidate];
    self.cookTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementCookTime) userInfo:nil repeats:YES];
  
    self.cookTimerView.alpha = 1;
    
}

-(void)stoppedCooking{
    [self.cookTimer invalidate];
    self.cookTimerView.alpha = 0;
}

-(void)countDownDidFinish{
    AVCaptureConnection *videoConnection = [self videoConnection];

    NSLog(@"about to request a capture from: %@", self.stillImageOutput);
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        self.previewLayer.opacity = 0;
        [self.captureSession stopRunning];
        
        [UIView animateWithDuration:1 animations:^(void){
            self.microwaveView.alpha = 1;
        }];

        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        UIImage * landscapeImage = [[UIImage alloc] initWithCGImage: image.CGImage
                                                             scale: 1.0
                                                       orientation: UIImageOrientationDown];
 
        self.photoCompletion(landscapeImage);
        
    }];
}

#pragma mark UIButton presses

-(void)settingsButtonPressed:(id)sender{
    [self stopListening];
    
    SettingsTableViewController * settingsViewController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    LandscapeLeftViewController * containerNavView = [[LandscapeLeftViewController alloc] initWithRootViewController:settingsViewController];
    [self presentViewController:containerNavView animated:YES completion:^(void){
        
    }];
}

@end
