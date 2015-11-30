/**
 *  AppDelegate.m
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import "AppDelegate.h"
#import "DotLog.h"
#import "DotView.h"
#import "Dot.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // @todo: add support for multiple DotLog plots at the same time
	[self.dotView setNeedsDisplay:YES];
    
    _dotLogServer = [[DotLogServer alloc] initWithDisplayController:self];
}

- (IBAction)play:(id)sender
{
    /**
     * The first frame is assumed to be t = 0, the second frame has a relative timestamp that indicates how long
     * after the first frame it took place.
     */

    [self.currentFrameCounter setStringValue:@"1"];
    [self.scrubber setIntValue:1];

    [_dotLog setCurrentFrame:0];
    [self.dotView setDotLog:_dotLog];
    [self.dotView setNeedsDisplay:YES];   // this just adds it to the runloop, it does not synchronously display the new frame, so we can't increment the frame until after the timer
    
    if ([self.realTimePlayBack state] == NSOnState)
    {
        NSLog(@"Playing with real-time playback");

        // Peek at the next dot
        Dot *nextDot = [[_dotLog getDots] objectAtIndex:[_dotLog nextFrame]];
        
        NSLog(@"initial delay: %.2f", [nextDot timestamp]);
        NSTimeInterval interval = [nextDot timestamp];
        [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(drawFrame:) userInfo:nil repeats:NO];
    }
    else
    {
        NSLog(@"Playing in one hit");

        [self.dotView restoreSnapshot];
        [_dotLog setCurrentFrame:[[_dotLog getDots] count] - 1];
        [self.dotView setNeedsDisplay:YES];
        [self.currentFrameCounter setStringValue:[NSString stringWithFormat:@"%lu", [[_dotLog getDots] count]]];
        [self.scrubber setIntValue:[[_dotLog getDots] count]];
    }
}

- (IBAction)scrubToFrame:(id)sender
{
    // @todo: implement
    NSLog(@"Scrubbing to %1.2f (not implemented)", [sender floatValue]);
    
    [_dotLog setCurrentFrame:[sender intValue]];
}

- (void)drawFrame:(NSTimer*)timer
{
    if ([self.realTimePlayBack state] == NSOffState)
    {
        return;
    }
    
    // Draw the "current" frame
    [_dotLog setCurrentFrame:[_dotLog nextFrame]];
    [self.dotView setNeedsDisplay:YES];

    [self.currentFrameCounter setStringValue:[NSString stringWithFormat:@"%d", [_dotLog currentFrame] + 1]];
    [self.scrubber setIntValue:[_dotLog currentFrame] + 1];

    // Get the timestamp from the current Dot
    float currentTimestamp = [(Dot *)[[_dotLog getDots] objectAtIndex:[_dotLog currentFrame]] timestamp];

    // Peek at the next dot
    Dot *nextDot = [[_dotLog getDots] objectAtIndex:[_dotLog nextFrame]];
    
    NSLog(@"next TS: %.2f diff: %.2f", [nextDot timestamp], [nextDot timestamp] - currentTimestamp);
    NSTimeInterval interval = [nextDot timestamp] - currentTimestamp;
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(drawFrame:) userInfo:nil repeats:NO];
}

- (IBAction)toggleRealTimePlayBack:(id)sender
{
    NSLog(@"Toggling real-time playback (%@)", ([self.realTimePlayBack state] == NSOnState) ? @"yes" : @"no");
}

- (IBAction)selectDotLog:(id)sender
{
    NSOpenPanel *dlg = [NSOpenPanel openPanel];
        
    [dlg setCanChooseFiles:YES];
    [dlg setAllowedFileTypes:[NSArray arrayWithObjects:@"dlg", nil]];
    
    if ([dlg runModal] == NSOKButton)
    {
        NSArray *files = [dlg URLs];
        
        for (int i = 0; i < [files count]; i++)
        {
            _dotLog = [[DotLog alloc] init];

            [_dotLog setLogFile:[[files objectAtIndex:i] path]];
            
            [self.dotView setYRange:[_dotLog yMin]-10 max:[_dotLog yMax]+10];
            [self.dotView setXRange:[_dotLog xMin]-10 max:[_dotLog xMax]+10];
            
            [self.currentFrameCounter setStringValue:@"0"];
            [self.totalFrameCounter setStringValue:[NSString stringWithFormat:@"%lu", [[_dotLog getDots] count]]];
            
            [self.scrubber setMinValue:0];
            [self.scrubber setMaxValue:[[_dotLog getDots] count] - 1];
            [self.scrubber setIntValue:0];
            
            [self.scrubber setEnabled:YES];
            [self.btnPlay setEnabled:YES];
            
            break;
        }
    }
}

- (IBAction)snapshot:(id)sender
{
    [self.dotView snapshot];
}

- (IBAction)startDotLogServer:(id)sender
{
    if ([_dotLogServer running])
    {
        [self.btnOpen setEnabled:YES];
        [self.realTimePlayBack setEnabled:YES];
        [self.btnServer setTitle:@"Start Server"];
    }
    else
    {
        _dotLog = [[DotLog alloc] init];

        [self.btnOpen setEnabled:NO];
        [self.btnPlay setEnabled:NO];
        [self.realTimePlayBack setState:NSOffState];
        [self.realTimePlayBack setEnabled:NO];
        [self.scrubber setEnabled:NO];
        [self.btnServer setTitle:@"Stop Server"];
        
        [self.currentFrameCounter setStringValue:@"0"];
        [self.totalFrameCounter setStringValue:[NSString stringWithFormat:@"%d", 0]];

        [_dotLogServer start];
    }
}

#pragma mark DotLogDisplayController Protocol

- (void)addDot:(CGPoint)dotPoint withTimestamp:(float)timestamp
{
    [_dotLog addDotWithPoint:dotPoint timestamp:timestamp colour:0 waypoint:NO atIndex:-1];

    // Adding a dot recalculates the X & Y ranges of the dotLog, ensure the view is synchronised
    [self.dotView setYRange:[_dotLog yMin]-10 max:[_dotLog yMax]+10];
    [self.dotView setXRange:[_dotLog xMin]-10 max:[_dotLog xMax]+10];
    
    [self.totalFrameCounter setStringValue:[NSString stringWithFormat:@"%lu", [[_dotLog getDots] count]]];

    [self play:self];
}

@end
