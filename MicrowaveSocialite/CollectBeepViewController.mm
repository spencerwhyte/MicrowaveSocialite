//
//  CollectBeepViewController.m
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import "CollectBeepViewController.h"

@interface CollectBeepViewController ()

@end

#define RECORD_WIDTH 70
#define RECORD_HEIGHT 70

@implementation CollectBeepViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.isRecording = NO;
        
        self.view.backgroundColor = [UIColor purpleColor];
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    CGRect frame = CGRectMake(self.view.frame.size.width * 0.1, self.view.frame.size.height * 0.1, self.view.frame.size.width * 0.8, self.view.frame.size.height * 0.7);
    
    UILabel * explanationLabel =  [[UILabel alloc] initWithFrame:frame];
    explanationLabel.text = @"I would like to know what the beep on your microwave sounds like :)\n\n 1. Tap record\n 2. Press a button on your microwave\n 3. Tap stop";
    explanationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    explanationLabel.numberOfLines = 0;
    explanationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    explanationLabel.textColor = [UIColor whiteColor];
    
    self.recordOrStopButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0.5 - RECORD_WIDTH/2, self.view.frame.size.height * 0.80 - RECORD_HEIGHT/2, RECORD_WIDTH, RECORD_HEIGHT)];
    [self.recordOrStopButton addTarget:self action:@selector(didPressRecordOrStop:) forControlEvents:UIControlEventTouchUpInside];
    self.recordOrStopButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    UIImage * recordImage = [UIImage imageNamed:@"record"];
    [self.recordOrStopButton setImage:recordImage forState:UIControlStateNormal];
    
    self.fftView = [[FFTView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height * 0.7, self.view.frame.size.width, self.view.frame.size.height * 0.3)];
    self.fftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.fftView setFFTBackgroundColor:[UIColor purpleColor]];
    [self.fftView setFFTPrimaryColor:[UIColor orangeColor]];
    [self.fftView setFFTThresholdColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.fftView];
    [self.view addSubview:self.recordOrStopButton];
    [self.view addSubview:explanationLabel];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:) ];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didPressRecordOrStop:(id)sender{
    self.isRecording = !self.isRecording;
    if(self.isRecording){ // We are recording, so show a stop button
        [self.fftView startAnimation];
        UIImage * recordImage = [UIImage imageNamed:@"stop"];
        [self.recordOrStopButton setImage:recordImage forState:UIControlStateNormal];
    }else{ // We are waiting to record, so show a record button
        [self.fftView stopAnimation];
        UIImage * recordImage = [UIImage imageNamed:@"record"];
        [self.recordOrStopButton setImage:recordImage forState:UIControlStateNormal];
    }
}

-(void)done:(id)sender{
    if(self.fftView.targetIndex != 0){
        [[Settings sharedInstance] setBeepFrequency:self.fftView.targetIndex];
    
        [self dismissViewControllerAnimated:YES completion:^(void){
        
        }];
    }else{
        NSString * louderTitle = NSLocalizedStringWithDefaultValue(@"LoaderTitle", nil, [NSBundle mainBundle], @"Louder Please", @"Title of the alert view that tells the user that they did not hold their phone close enough to their microwave");
        
        NSString * louderMessage = @"Try holding your phone closer to the microwave, that wasn't quite loud enough.";
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:louderTitle message:louderMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
    }
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeRight;
}

#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    // Do nothing really
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
