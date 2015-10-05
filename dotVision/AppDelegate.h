/**
 *  AppDelegate.h
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import <Cocoa/Cocoa.h>

@class DotLog;
@class DotView;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    DotLog *    _dotLog;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *currentFrameCounter;
@property (weak) IBOutlet NSTextField *totalFrameCounter;
@property (weak) IBOutlet NSButton *realTimePlayBack;
@property (weak) IBOutlet NSSlider *scrubber;
@property (weak) IBOutlet DotView *dotView;

- (IBAction)play:(id)sender;
- (IBAction)scrubToFrame:(id)sender;
- (IBAction)selectDotLog:(id)sender;
- (IBAction)toggleRealTimePlayBack:(id)sender;

@end
