//
//  ViewController.m
//  VideoDeocde-objc
//
//  Created by larryhou on 14/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

#import "ViewControllerObjc.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <ScreenRecording/ScreenRecording.h>

@interface ViewControllerObjc ()


@end

@implementation ViewControllerObjc

int playCount;
AVAssetReaderTrackOutput* trackOutput;
AVAssetReader* reader;
AVAssetExportSession* exporter;

NSURL* outputURL;
NSDateFormatter* formatter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_progressView setHidden:YES];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* bundle = [NSBundle.mainBundle pathForResource:@"movie" ofType:@"bundle"];
    NSURL* location = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/funny.mp4", bundle]];
    AVPlayerLayer* layer = [AVPlayerLayer playerLayerWithPlayer:[AVPlayer playerWithURL:location]];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [layer setFrame:[self.view frame]];
    [self.view.layer insertSublayer:layer atIndex:0];
    [layer.player play];
    
    self.loopIndicator.text = [NSString stringWithFormat:@"#%02d", playCount];
    [layer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time)
    {
        __weak typeof(layer) wlayer = layer;
        CMTime duration = wlayer.player.currentItem.duration;
        if (CMTimeCompare(duration, time) == 0)
        {
            playCount++;
            [wlayer.player seekToTime:kCMTimeZero];
            [wlayer.player play];
            self.loopIndicator.text = [NSString stringWithFormat:@"#%02d", playCount];
        }
        
        self.timeIndicator.text = [formatter stringFromDate:[[NSDate alloc] init]];
    }];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stop:)];
    [tap setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:tap];
}

- (IBAction)record:(id)sender
{
    [self.recordButton setHidden:YES];
    [ScreenRecorder.shared startRecordingWithCompletion:nil];
}

-(void)stop:(UITapGestureRecognizer*) sender
{
    if (sender.state != UIGestureRecognizerStateRecognized) {return;}
    
    [self.progressView setHidden:NO];
    ScreenRecorder.shared.progressObserver = ^(float value)
    {
        self.progressView.progress = value;
    };
    
    [ScreenRecorder.shared stopRecordingWithClipContext:@"0-5;10-15" completion:^(NSURL* url, AVAssetExportSessionStatus status)
     {
         [self.recordButton setHidden:NO];
         [self.progressView setHidden:YES];
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}
@end
