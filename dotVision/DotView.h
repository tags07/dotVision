/**
 *  DotView.h
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import <Cocoa/Cocoa.h>

@class DotLog;

@interface DotView : NSView {
    float       _yMin, _yMax;
    float       _xMin, _xMax;
    NSImage *   _snapshot;
}

- (void)setYRange:(float)min max:(float)max;
- (void)setXRange:(float)min max:(float)max;
- (void)snapshot;
- (void)restoreSnapshot;

@property (weak) DotLog *dotLog;
@property (assign) int gridLineCountY;
@property (assign) int gridLineCountX;

@end
