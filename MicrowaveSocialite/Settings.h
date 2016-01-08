//
//  Settings.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject


/*
    Returns the FFT bin index belonging to the most promenant frequency of the microwave beep
 */
-(NSInteger)beepFrequency;

-(void)setBeepFrequency:(NSInteger)newBeepFrequency;

-(void)reset;

+(Settings*)sharedInstance;

@end
