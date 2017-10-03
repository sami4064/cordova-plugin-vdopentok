//
//  VDVideoViewController.h
//  Basic-Video-Chat
//
//  Created by Abdul Sami on 02/10/2017.
//  Copyright © 2017 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@interface VDVideoViewController : UIViewController
@property (nonatomic, copy, nullable) NSString* kApiKey;
@property (nonatomic, copy, nullable) NSString* kSessionId;
@property (nonatomic, copy, nullable) NSString* kToken;

-(void)stopCall;
@end
