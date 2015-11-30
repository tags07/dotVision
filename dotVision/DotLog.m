/**
 *  DotLog.m
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import "DotLog.h"
#import "Dot.h"

@implementation DotLog

- (id)init
{
    if (self = [super init])
    {
        NSLog(@"DotLog initialised");
        
        _currentFrame = 0;
        _yMin = _yMax = 0;
        _xMin = _xMax = 0;
        _dots = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"Destroying DotLog instance...");
}

- (NSMutableArray *)getDots
{
    return _dots;
}

- (NSArray *)getDotsUpToCurrentFrame
{
    NSRange range;
    
    range.location = 0;
    range.length = _currentFrame + 1;       // frames are indexed from 0
    
    return [_dots subarrayWithRange:range];
}

- (void)setCurrentFrame:(int)currentFrame
{
    if (currentFrame >= [_dots count] && [_dots count])
    {
        currentFrame %= [_dots count];
    }
    
    _currentFrame = currentFrame;
}

- (int)currentFrame
{
    return _currentFrame;
}

- (int)nextFrame
{
    int nextFrame = [self currentFrame] + 1;
    
    if (nextFrame >= [_dots count])
    {
        nextFrame %= [_dots count];
    }
    
    return nextFrame;
}

- (float)xMin
{
    return _xMin;
}

- (float)xMax
{
    return _xMax;
}

- (float)yMin
{
    return _yMin;
}

- (float)yMax
{
    return _yMax;
}

- (void)setLogFile:(NSString *)logFile
{
    NSLog(@"Parsing file: %@", logFile);

    NSString *fileContents = [NSString stringWithContentsOfFile:logFile encoding:NSUTF8StringEncoding error:nil];
    NSArray  *lines        = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    _dots = [NSMutableArray arrayWithCapacity:[lines count]];
    _yMin = _yMax = 0;
    _xMin = _xMax = 0;
    
    for (int i = 0; i < [lines count]; i++)
    {
        NSArray *tokens = [[lines objectAtIndex:i] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([tokens count] != 5)
        {
            NSLog(@"Skipping invalid line %d (%@) as it has %lu tokens", i, [lines objectAtIndex:i], [tokens count]);
            continue;
        }
        
        CGPoint p;
        p.x = [[tokens objectAtIndex:1] floatValue];
        p.y = [[tokens objectAtIndex:2] floatValue];
        
        unsigned int hexCode;
        NSScanner *scanner = [NSScanner scannerWithString:[tokens objectAtIndex:3]];
        [scanner scanHexInt:&hexCode];
        
        BOOL  waypoint  = ([[tokens objectAtIndex:4] intValue]) ? YES : NO;
        float timestamp = [[tokens objectAtIndex:0] floatValue];
        
        [self addDotWithPoint:p timestamp:timestamp colour:hexCode waypoint:waypoint atIndex:i];
    }
    
    [self setCurrentFrame:0];
}

- (void)addDotWithPoint:(CGPoint)dotPoint timestamp:(float)timestamp colour:(int)hexCode waypoint:(BOOL)waypoint atIndex:(int)index
{
    Dot *dot = [[Dot alloc] init];
    
    NSLog(@"Adding dot (%.2f, %.2f)", dotPoint.x, dotPoint.y);
    
    [dot setPoint:dotPoint];
    [dot setTimestamp:timestamp];
    [dot setColour:hexCode];
    [dot setWaypoint:waypoint];

    if (dotPoint.x < _xMin)
    {
        _xMin = dotPoint.x;
    }
    
    if (dotPoint.x > _xMax)
    {
        _xMax = dotPoint.x;
    }
    
    if (dotPoint.y < _yMin)
    {
        _yMin = dotPoint.y;
    }
    
    if (dotPoint.y > _yMax)
    {
        _yMax = dotPoint.y;
    }
    
    [_dots addObject:dot];
}

@end
