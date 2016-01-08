//
//  MicrowaveOperationDelegate.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MicrowaveOperationDelegate <NSObject>


// This will get called on the delegate when we hear a beep
-(void)didHearBeepAtFrequencyWithIndex:(int)index;

@end
