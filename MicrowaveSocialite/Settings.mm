//
//  Settings.m
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+(Settings*)sharedInstance{
    static Settings * sharedInstance;
    if(sharedInstance == nil){
        sharedInstance = [[Settings alloc] init];
    }
    return sharedInstance;
}

/*
 Returns the FFT bin index belonging to the most promenant frequency of the microwave beep
 */
-(NSInteger)beepFrequency{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * frequencyKey = @"beepFrequency";
    return [defaults integerForKey:frequencyKey];
}

-(void)setBeepFrequency:(NSInteger)newBeepFrequency{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * frequencyKey = @"beepFrequency";
    [defaults setInteger:newBeepFrequency forKey:frequencyKey];
    [defaults synchronize];
}

-(void)reset{
    [self setBeepFrequency:0];
}

@end
