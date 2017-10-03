#import "VDOpentok.h"

@implementation VDOpentok

- (void)startVideo:(CDVInvokedUrlCommand*)command
{

    NSString* kApiKey = [[[command arguments] objectAtIndex:0] stringValue];
    NSString* kSession = [[command arguments] objectAtIndex:1];
    NSString* kToken = [[command arguments] objectAtIndex:2];
    
    NSString* msg = @"opentok session started";

    _videoViewController = [[VDVideoViewController alloc] initWithNibName:@"VDVideoViewController" bundle:nil];
    
    _videoViewController.kToken = kToken;
    _videoViewController.kSessionId = kSession;
    _videoViewController.kApiKey = kApiKey;
    
    [self.viewController presentViewController:_videoViewController animated:YES completion:^{
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:msg];
        
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
