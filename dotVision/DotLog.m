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
    }
    
    return self;
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
    if (currentFrame >= [_dots count])
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
            NSLog(@"Skipping invalid line %d", i);
            continue;
        }
        
        float x = [[tokens objectAtIndex:1] floatValue];
        float y = [[tokens objectAtIndex:2] floatValue];
        
        if (x < _xMin)
        {
            _xMin = x;
        }

        if (x > _xMax)
        {
            _xMax = x;
        }
        
        if (y < _yMin)
        {
            _yMin = y;
        }
        
        if (y > _yMax)
        {
            _yMax = y;
        }        
        
        Dot *dot = [[Dot alloc] init];
        CGPoint p;
        
        p.x = x;
        p.y = y;
        
        unsigned int hex;
        NSScanner *scanner = [NSScanner scannerWithString:[tokens objectAtIndex:3]];
        [scanner scanHexInt:&hex];

        [dot setPoint:p];
        [dot setTimestamp:[[tokens objectAtIndex:0] floatValue]];
        [dot setColour:hex];
        [dot setWaypoint:([[tokens objectAtIndex:4] intValue]) ? YES : NO];
        
        [_dots insertObject:dot atIndex:i];
    }
    
    [self setCurrentFrame:0];
}

@end
