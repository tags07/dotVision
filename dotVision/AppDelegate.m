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
    _dotLog = [[DotLog alloc] init];
	[_dotView setNeedsDisplay:YES];
}

- (IBAction)play:(id)sender
{
    /**
     * The first frame is assumed to be t = 0, the second frame has a relative timestamp that indicates how long
     * after the first frame it took place.
     */

    [_currentFrameCounter setStringValue:@"1"];
    [_scrubber setIntValue:1];

    [_dotLog setCurrentFrame:0];
    [_dotView setDotLog:_dotLog];
    [_dotView setNeedsDisplay:YES];   // this just adds it to the runloop, it does not synchronously display the new frame, so we can't increment the frame until after the timer
    
    if ([_realTimePlayBack state] == NSOnState)
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

        [_dotLog setCurrentFrame:[[_dotLog getDots] count] - 1];
        [_dotView setNeedsDisplay:YES];
        [_currentFrameCounter setStringValue:[NSString stringWithFormat:@"%d", [[_dotLog getDots] count]]];
        [_scrubber setIntValue:[[_dotLog getDots] count]];
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
    if ([_realTimePlayBack state] == NSOffState)
    {
        return;
    }
    
    // Draw the "current" frame
    [_dotLog setCurrentFrame:[_dotLog nextFrame]];
    [_dotView setNeedsDisplay:YES];

    [_currentFrameCounter setStringValue:[NSString stringWithFormat:@"%d", [_dotLog currentFrame] + 1]];
    [_scrubber setIntValue:[_dotLog currentFrame] + 1];

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
    NSLog(@"Toggling real-time playback (%@)", ([_realTimePlayBack state] == NSOnState) ? @"yes" : @"no");
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
            [_dotLog setLogFile:[[files objectAtIndex:i] path]];
            
            [_dotView setYRange:[_dotLog yMin]-10 max:[_dotLog yMax]+10];
            [_dotView setXRange:[_dotLog xMin]-10 max:[_dotLog xMax]+10];
            
            [_currentFrameCounter setStringValue:@"0"];
            [_totalFrameCounter setStringValue:[NSString stringWithFormat:@"%d", [[_dotLog getDots] count]]];
            
            [_scrubber setMinValue:0];
            [_scrubber setMaxValue:[[_dotLog getDots] count] - 1];
            [_scrubber setIntValue:0];
        }
    }
}

@end
