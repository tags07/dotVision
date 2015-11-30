/**
 *  AppDelegate.h
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import <Cocoa/Cocoa.h>
#import "DotLogServer.h"

@class DotLog;
@class DotView;

@interface AppDelegate : NSObject <NSApplicationDelegate, DotLogDisplayController>
{
    DotLog *        _dotLog;
    DotLogServer *  _dotLogServer;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *currentFrameCounter;
@property (weak) IBOutlet NSTextField *totalFrameCounter;
@property (weak) IBOutlet NSButton *realTimePlayBack;
@property (weak) IBOutlet NSSlider *scrubber;
@property (weak) IBOutlet NSButton *btnOpen;
@property (weak) IBOutlet NSButton *btnPlay;
@property (weak) IBOutlet NSButton *btnServer;
@property (weak) IBOutlet DotView *dotView;

- (IBAction)play:(id)sender;
- (IBAction)scrubToFrame:(id)sender;
- (IBAction)selectDotLog:(id)sender;
- (IBAction)toggleRealTimePlayBack:(id)sender;
- (IBAction)snapshot:(id)sender;
- (IBAction)startDotLogServer:(id)sender;

#pragma mark DotLogDisplayController Protocol

- (void)addDot:(CGPoint)dotPoint withTimestamp:(float)timestamp;

@end
