#import "VDOpentok.h"
@interface VDOpentok(){
    NSString* callBackId;
}
@end
@implementation VDOpentok

- (void)startVideo:(CDVInvokedUrlCommand*)command
{

    NSString* kApiKey = [[command arguments] objectAtIndex:0] ;
    NSString* kSession = [[command arguments] objectAtIndex:1];
    NSString* kToken = [[command arguments] objectAtIndex:2];
    
    NSString* msg = @"opentok session started";

    _videoViewController = [[VDVideoViewController alloc] initWithNibName:@"VDVideoViewController" bundle:nil];
    
    _videoViewController.kToken = kToken;
    _videoViewController.kSessionId = kSession;
    _videoViewController.kApiKey = kApiKey;

    callBackId = command.callbackId;
    
    __weak VDOpentok* weakSelf = self;
    
    _videoViewController.sessionDisconnected = ^{
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_ERROR
                                   messageAsString:@"session_ended"];
        [weakSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    };
    
    [self.viewController presentViewController:_videoViewController animated:YES completion:^{
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:msg];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        
    }];
    

    
}


- (void)endVideo:(CDVInvokedUrlCommand*)command
{
    
    [_videoViewController stopCall];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"video_stopped"];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}


@end
