//
//  VDVideoViewController.m
//  Basic-Video-Chat
//
//  Created by Abdul Sami on 02/10/2017.
//  Copyright © 2017 TokBox, Inc. All rights reserved.
//

#import "VDVideoViewController.h"

#import <OpenTok/OpenTok.h>


// Change to NO to subscribe to streams other than your own.
static bool subscribeToSelf = NO;


@interface VDVideoViewController ()<OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate>
@property (weak, nonatomic) IBOutlet UIView *buttonsWrapperView;
@property (weak, nonatomic) IBOutlet UIView *myVideoWrapperView;


@end

@implementation VDVideoViewController{
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
}

static double widgetHeight = 120;
static double widgetWidth = 120;

-(void)stopCall{
    
    _sessionDisconnected = nil;
    
    [_session disconnect:nil];
    [self cleanupPublisher];
    [self cleanupSubscriber];
}

- (IBAction)micSwitchPressed:(id)sender {
        _publisher.publishAudio = !_publisher.publishAudio;
}


- (IBAction)cameraChangePressed:(id)sender {
    if (_publisher.cameraPosition == AVCaptureDevicePositionFront) {
        _publisher.cameraPosition = AVCaptureDevicePositionBack;
    } else {
        _publisher.cameraPosition = AVCaptureDevicePositionFront;
    }
}


- (IBAction)cameraTurnOffPressed:(id)sender {
    _publisher.publishVideo = !_publisher.publishVideo;

}

- (IBAction)speakerTurnOffButton:(id)sender {
    _subscriber.subscribeToAudio = !_subscriber.subscribeToAudio;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak VDVideoViewController* weakSelf = self;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
//    [self authenticatUserWithUsername:@"naieemsupto@gmail.com" Password:@"1234" AppointmentID:@"196" completionBlock:^(NSString *sessionId, NSString *tokenId, NSString *apiKey) {
//        _kApiKey = apiKey;
//        _kSessionId = sessionId;
//        _kToken = tokenId;
//        
        // Step 1: As the view comes into the foreground, initialize a new instance
        // of OTSession and begin the connection process.
        _session = [[OTSession alloc] initWithApiKey:_kApiKey
                                           sessionId:_kSessionId
                                            delegate:weakSelf];
        [weakSelf doConnect];
        
//    }];
}

-(CGRect*)getMyVideoRect{
    
}

-(void)OrientationDidChange:(NSNotification*)notification {
    UIDeviceOrientation Orientation=[[UIDevice currentDevice]orientation];
    
    if(Orientation==UIDeviceOrientationLandscapeLeft || Orientation==UIDeviceOrientationLandscapeRight) {
        NSLog(@"Landscape");
        if(_subscriber.view){
            [_subscriber.view setFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                                  self.view.frame.size.height)];

        }
    } else if(Orientation==UIDeviceOrientationPortrait) {
        NSLog(@"Potrait Mode");
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice]
                                      userInterfaceIdiom])
    {
        return NO;
    } else {
        return YES;
    }
}
#pragma mark - OpenTok methods

/**
 * Asynchronously begins the session connect process. Some time later, we will
 * expect a delegate method to call us back with the results of this action.
 */
- (void)doConnect
{
    OTError *error = nil;
    
    [_session connectWithToken:_kToken error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

/**
 * Sets up an instance of OTPublisher to use with this session. OTPubilsher
 * binds to the device camera and microphone, and will provide A/V streams
 * to the OpenTok session.
 */
- (void)doPublish
{
    OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
    settings.name = [UIDevice currentDevice].name;
    _publisher = [[OTPublisher alloc] initWithDelegate:self settings:settings];
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
    
    [self.myVideoWrapperView addSubview:_publisher.view];
    [_publisher.view setFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
    
    [self.view bringSubviewToFront: self.buttonsWrapperView];
}

/**
 * Cleans up the publisher and its view. At this point, the publisher should not
 * be attached to the session any more.
 */
- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
    // this is a good place to notify the end-user that publishing has stopped.
}

/**
 * Instantiates a subscriber for the given stream and asynchronously begins the
 * process to begin receiving A/V content for this stream. Unlike doPublish,
 * this method does not add the subscriber to the view hierarchy. Instead, we
 * add the subscriber only after it has connected and begins receiving data.
 */
- (void)doSubscribe:(OTStream*)stream
{
    _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    
    OTError *error = nil;
    [_session subscribe:_subscriber error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

/**
 * Cleans the subscriber from the view hierarchy, if any.
 * NB: You do *not* have to call unsubscribe in your controller in response to
 * a streamDestroyed event. Any subscribers (or the publisher) for a stream will
 * be automatically removed from the session during cleanup of the stream.
 */
- (void)cleanupSubscriber
{
    [_subscriber.view removeFromSuperview];
    _subscriber = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    
    // Step 2: We have successfully connected, now instantiate a publisher and
    // begin pushing A/V streams into OpenTok.
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)",
     session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    
    if(_sessionDisconnected) _sessionDisconnected();
}


- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
    
    // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
    // have seen on the OpenTok session.
    if (nil == _subscriber && !subscribeToSelf)
    {
        [self doSubscribe:stream];
    }
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
}

- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)    session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if ([_subscriber.stream.connection.connectionId
         isEqualToString:connection.connectionId])
    {
        [self cleanupSubscriber];
    }
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)",
          subscriber.stream.connection.connectionId);
    assert(_subscriber == subscriber);
    CGRect frame = self.view.frame;
    [_subscriber.view setFrame:CGRectMake(0, 0, frame.size.width,
                                          frame.size.height)];
    [self.view addSubview:_subscriber.view];
    [self.view bringSubviewToFront:self.buttonsWrapperView];
    if(_publisher.view)[self.view bringSubviewToFront:self.myVideoWrapperView];
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@",
          subscriber.stream.streamId,
          error);
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
    // all participants in the OpenTok session. We will attempt to subscribe to
    // our own stream. Expect to see a slight delay in the subscriber video and
    // an echo of the audio coming from the device microphone.
    if (nil == _subscriber && subscribeToSelf)
    {
        [self doSubscribe:stream];
    }
}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
    
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher
 didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTError"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] ;
        [alert show];
    });
}

#pragma mark - User Authentication Methods
-(void)authenticatUserWithUsername:(NSString*)username Password:(NSString*)password AppointmentID:(NSString*)appointmentId completionBlock:(void(^)(NSString* sessionId, NSString* tokenId, NSString* apiKey)) completionBlock{
    
    NSURL *url = [NSURL URLWithString:@"https://www.myvirtualdoctor.com/api/"];
    
    AFHTTPSessionManager* sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [sessionManager.requestSerializer setValue:@"application/json"  forHTTPHeaderField:@"Content-Type"];
    
    //    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //    [sessionManager.responseSerializer setAcceptableContentTypes:[[NSSet alloc] initWithArray:@[@"text/html"]]];
    
    [sessionManager POST:@"user/login" parameters:@{@"email":username, @"password":password} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString* authToken = responseObject[@"token"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getOpenTokDataWithAuthToken:authToken AppointmentID:appointmentId completionBlock:completionBlock];
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error %@",[error description]);
    }];
    
}

-(void)getOpenTokDataWithAuthToken:(NSString* ) authToken AppointmentID:(NSString*)appointmentId completionBlock:(void(^)(NSString* sessionId, NSString* tokenId, NSString* apiKey)) completionBlock{
    NSURL *url = [NSURL URLWithString:@"https://www.myvirtualdoctor.com/api/"];
    
    AFHTTPSessionManager* sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    
    NSString* path = [NSString stringWithFormat: @"appointment/startVideo/%@",appointmentId];
    
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [sessionManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [sessionManager.requestSerializer setValue:authToken forHTTPHeaderField:@"Authorization"];
    
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];  //AFHTTPResponseSerializer serializer
    
    [sessionManager GET:path parameters:@{} progress:nil
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject2) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"%@",responseObject2);
                        NSDictionary* dic = [[NSDictionary alloc] initWithDictionary:responseObject2];
                        
                        NSLog(@"%@",dic);
                        if(responseObject2){
                            NSDictionary* result = [responseObject2 valueForKey:@"result"];
                            
                            NSString* apiKey = [[result valueForKey:@"apiKey"] stringValue];
                            
                            NSDictionary* appointment = [result valueForKey: @"appointment"];
                            NSString* sessionID = [appointment valueForKey:@"tokbox_session"];
                            
                            NSString* tokenID = [result valueForKey:@"openTokToken"];
                            
                            NSLog(@"session: %@ , token: %@ , apiKey: %@ ",sessionID,tokenID,apiKey);
                            if(completionBlock) completionBlock(sessionID , tokenID, apiKey);
                        }else{
                            NSLog(@"error ,[error description]");
                        }
                    });
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"error %@",[error description]);
                }];
    
}


@end
