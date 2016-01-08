//
//  FoodManagerDelegate.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-06-24.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FoodManagerDelegate <NSObject>

-(void)takePhotoCompletion:(void (^)(UIImage* photo))callbackBlock;


-(void)mayHaveStartedCooking;
-(void)stoppedCooking;

@end
