//
//  TargetFrequencyDelegate.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-06-14.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TargetFrequencyDelegate <NSObject>

-(void)didHitTargetFrequencyIndex:(NSInteger)frequencyIndex;

@end
