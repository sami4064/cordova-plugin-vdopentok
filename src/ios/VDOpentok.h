#import <Cordova/CDV.h>
#import  "VDVideoViewController.h"

@interface VDOpentok : CDVPlugin
@property (nullable, nonatomic, strong) VDVideoViewController* videoViewController;

- (void)startVideo:(CDVInvokedUrlCommand*)command;

@end
