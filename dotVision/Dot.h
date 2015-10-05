/**
 *  Dot.h, model component
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 *
 *  A Dot is a single point within the DotLog.
 */

#import <Foundation/Foundation.h>

@interface Dot : NSObject

@property (assign) NSPoint point;
@property (assign) float   timestamp;    // timestamp in fractional secs since start of the log (ie. all timestamps are relative to first Dot)
@property (assign) int     colour;
@property (assign) BOOL    waypoint;

@end
