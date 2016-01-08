//
//  FoodManager.m
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import "FoodManager.h"

@implementation FoodManager

-(id)init{
    if(self=[super init]){
        self.state = NothingHappening;
        self.timeOfFinalButtonPress = 0;
        self.timeOfFirstFinishBeep = 0;
    }
    return self;
}


// Gets called when we hear a beep from the microwave
-(void)didHearBeepAtFrequencyWithIndex:(int)index{
    
    if(self.state == GettingUserInputAndCooking){ // They must be still inputing the numbers
        NSTimeInterval cookingTime = [[NSDate date] timeIntervalSince1970] - self.timeOfFinalButtonPress;
        if(cookingTime > 8*60){ // If the cook time is longer than 8 minutes, we probably made a mistake
            self.timeOfFinalButtonPress = [[NSDate date] timeIntervalSince1970];
            
        }else if(cookingTime > 10 && self.timeOfFinalButtonPress != 0){
            // If it has been more than 10 seconds since their last button press, it means the food is done
            
            //NSLog(@"Send out a tweet of the total cook time, and the pic of who put it in there");
            //NSLog(@"The cook time was %f", cookingTime);
            
          
            int minutes = ((int)cookingTime)/60;
            int seconds = ((int)cookingTime)%60;
            
            seconds++; // Warning hax
            
            NSString * cookingTimeString = @"";
            NSString * minutesString = @"";
            NSString * secondsString = @"";
            NSString * connector = @"";
            
            if(minutes > 1){
                minutesString = [NSString stringWithFormat:@"%d minutes", minutes];
            }else if (minutes == 1){
                minutesString = [NSString stringWithFormat:@"%d minute",minutes];
            }
            
            if(seconds > 0 && minutes > 0){
                connector = @" and ";
            }
            
            if(seconds > 1){
                secondsString = [NSString stringWithFormat:@"%d seconds", seconds];
            }else if (seconds == 1){
                secondsString = [NSString stringWithFormat:@"%d second", seconds];
            }
            
            cookingTimeString = [NSString stringWithFormat:@"%@%@%@", minutesString, connector, secondsString];
            
            NSString * status = [NSString stringWithFormat:@"Just finished cooking something for %@.", cookingTimeString];
            [[Cloud sharedInstance] postImage:self.lastPhotoTaken withStatus:status];
            
            NSLog(@"STATUS: %@", status);
            
            self.state = FinishedCooking;
            self.timeOfFirstFinishBeep = [[NSDate date] timeIntervalSince1970];
            
            [self.delegate stoppedCooking];
            
        }else{
            self.timeOfFinalButtonPress = [[NSDate date] timeIntervalSince1970];
            [self.delegate mayHaveStartedCooking];
        }
    }else if(self.state == FinishedCooking){
        // We need to sit in this state for 10 seconds because a cook finishes with more than one microwave beep
        if([[NSDate date] timeIntervalSince1970] - self.timeOfFirstFinishBeep > 4 && self.timeOfFirstFinishBeep != 0){
            
            // If we have waited the 10 seconds
            self.state = NothingHappening;
        }
    }
    
    if(self.state == NothingHappening){ // We are waiting around for someone to cook food
        // We should take their picture and send out a tweet

        
        NSLog(@"Taking picture of who put it in the microwave");
        [self.delegate mayHaveStartedCooking];
        [self.delegate takePhotoCompletion:^(UIImage * photo){
            self.lastPhotoTaken = photo;
        }];
        
        self.timeOfFinalButtonPress = [[NSDate date] timeIntervalSince1970];
        
        self.state = GettingUserInputAndCooking;
        
    }
}


@end
