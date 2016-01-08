//
//  Cloud.h
//  MicrowaveSocialite
//
//  Created by Spencer Whyte on 2014-05-27.
//  Copyright (c) 2014 Spencer Whyte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface Cloud : NSObject

+(Cloud*)sharedInstance;
- (void)postStatus:(NSString *)status;
- (void)postImage:(UIImage*)image withStatus:(NSString *)status;
@end
