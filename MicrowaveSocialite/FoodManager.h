//
//  FoodManager.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

/*
 
    The purpose of this class is to use logic to try and deduce what is going on inside the microwave.
 
    A normal microwave sequence is as follows.
 
    1. Place food in microwave
    2. Press a few buttons on the microwave within a 20 second window
    3. Wait for food to cook
    4. The microwave beeps when complete.
 
 
    This translates to an application sequence of
 
    1. When a beep is heard, take a picture of the user.
    2. Send out a tweet with the picture.
    3. Wait 20 seconds.
    4. When a beep is heard, the food is done, tweet about it and the length of the cook time.
    5. If we do not hear anything for 10 minutes, tweet that we fell asleep and that we must have missed the person at the microwave.
 
    Ideas for v2:
 
 
    -    Use facial recognition to tweet at people and remind them that their food is ready.
 
 */

#import "MicrowaveOperationDelegate.h"
#import "FoodManagerDelegate.h"
#import <Foundation/Foundation.h>
#import "Cloud.h"


typedef enum : NSUInteger {
    NothingHappening,
    GettingUserInputAndCooking,
    FinishedCooking
} MicrowaveStates;

@interface FoodManager : NSObject<MicrowaveOperationDelegate>

@property NSObject<FoodManagerDelegate> * delegate;

@property NSTimer * waitForCookingToStartTimer;
@property MicrowaveStates state;
@property NSTimeInterval timeOfUserInputStart;
@property NSTimeInterval timeOfFinalButtonPress;
@property NSTimeInterval timeOfFirstFinishBeep;
@property UIImage * lastPhotoTaken;
-(void)didHearBeepAtFrequencyWithIndex:(int)index;

@end
