/**
 *  DotLog.h
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 *
 *  The model for a DotLog from the robot.
 *
 *  This model parses an DotLog log file (each row consists of a timestamp, an x position and a y position)
 *  and creates an NSMutableArray of CGPoints from it for the DotView. When DotView wants to draw itself (or
 *  draw a specific frame of the DotLog), it uses this class as its data source.
 */

#import <Foundation/Foundation.h>

@interface DotLog : NSObject
{
    NSMutableArray *    _dots;         // an array of Dots
    int                 _currentFrame; // counter to support stepping and use of getDotsUpToCurrentFrame
    float               _yMin, _yMax;  // range of y values found from latest load
    float               _xMin, _xMax;  // as above for x
}

- (NSMutableArray *)getDots;
- (NSArray *)getDotsUpToCurrentFrame;

- (void)setCurrentFrame:(int)currentFrame;
- (void)setLogFile:(NSString *)logFile;
- (int)currentFrame;
- (int)nextFrame;
- (float)xMin;
- (float)xMax;
- (float)yMin;
- (float)yMax;
- (void)addDotWithPoint:(CGPoint)dotPoint timestamp:(float)timestamp colour:(int)hexCode waypoint:(BOOL)waypoint atIndex:(int)index;

@end
