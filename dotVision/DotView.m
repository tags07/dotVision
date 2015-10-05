/**
 *  DotView.m
 *  dotVision
 *
 *  oroboto@oroboto.net, www.oroboto.net, 2015
 */

#import "DotView.h"
#import "DotLog.h"
#import "Dot.h"

@implementation DotView

- (void)awakeFromNib
{
    [self setGridLineCountX:5];
    [self setGridLineCountY:5];
    
    [self setYRange:-100 max:100];
    [self setXRange:-100 max:100];
}

#pragma mark -
#pragma mark Properties

- (void)setYRange:(float)min max:(float)max
{
	if (max < min)
    {
		NSAssert(0, @"Invalid range.");
    }
	
    _yMin = min;
    _yMax = max;
	
	NSLog(@"Vertical range set [min: %f, max: %f]", _yMin, _yMax);
}

- (void)setXRange:(float)min max:(float)max
{
	if (max < min)
    {
		NSAssert(0, @"Invalid range.");
    }
	
    _xMin = min;
    _xMax = max;
	
	NSLog(@"Horizontal range set [min: %f, max: %f]", _xMin, _xMax);
}


#pragma mark -
#pragma mark Drawing

/**
 * Cocoa's co-ordinate system is cartesian based and (0,0) starts in the lower left corner of the view.
 */

- (void)drawRect:(NSRect)rect
{
 	CGRect	rectBounds = [self bounds];     // our dimensions in the view's user space co-ordinates (not necessarily pixels)
    
	float yPixelsPerUnit = rectBounds.size.height / (_yMax - _yMin);
    float xPixelsPerUnit = rectBounds.size.width  / (_xMax - _xMin);

    NSLog(@"Mapping robot space (%.2f, %.2f) -> (%.2f, %.2f) onto view user space %.2fx%.2f using xPPU[%.2f], yPPU[%.2f]",
          _xMin, _yMin, _xMax, _yMax, rectBounds.size.width, rectBounds.size.height, xPixelsPerUnit, yPixelsPerUnit);
    
	// Draw our border.
	[[NSColor blackColor] setStroke];
    [[NSColor whiteColor] setFill];

    NSRect aRect = NSMakeRect(0, 0, rectBounds.size.width, rectBounds.size.height);
    
    [NSBezierPath fillRect:aRect];
    [NSBezierPath strokeRect:aRect];
    
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:9.0];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    
	// Draw grid lines.
	if ([self gridLineCountY] > 0)
	{
		// Recalculate the axis labels.
		float yGridSpacing = rectBounds.size.height / ([self gridLineCountY] + 1);

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path setLineWidth:0.5];
        
		for (int i = 1; i <= [self gridLineCountY]; i++)
		{
            [path moveToPoint:NSMakePoint(0, i * yGridSpacing)];
            [path lineToPoint:NSMakePoint(rectBounds.size.width, i * yGridSpacing)];
            
//          NSString *str = [NSString stringWithFormat:@"%.0f", (((i * yGridSpacing) - (rectBounds.size.height / 2.0)) / yPixelsPerUnit)];
            NSString *str = [NSString stringWithFormat:@"%.0f", _yMin + (i * ((_yMax - _yMin) / ([self gridLineCountY]+1)))];

            [str drawAtPoint:NSMakePoint(5, (i * yGridSpacing) - 15) withAttributes:dict];
		}
        
        [path closePath];
        [path stroke];
	}

	if ([self gridLineCountX] > 0)
	{
		float xGridSpacing = rectBounds.size.width / ([self gridLineCountX] + 1);
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path setLineWidth:0.5];
		
		for (int i = 1; i <= [self gridLineCountX]; i++)
		{
            [path moveToPoint:NSMakePoint(i * xGridSpacing, 0)];
            [path lineToPoint:NSMakePoint(i * xGridSpacing, rectBounds.size.height)];
            
//          NSString *str = [NSString stringWithFormat:@"%.0f", (((i * xGridSpacing) - (rectBounds.size.width / 2.0)) / xPixelsPerUnit)];
            NSString *str = [NSString stringWithFormat:@"%.0f", _xMin + (i * ((_xMax - _xMin) / ([self gridLineCountX]+1)))];
            [str drawAtPoint:NSMakePoint((i * xGridSpacing) + 5, 5) withAttributes:dict];
		}
        
        [path closePath];
        [path stroke];
	}
    
    NSAffineTransform *xfTranslate = [NSAffineTransform transform];
    NSAffineTransform *xfScale = [NSAffineTransform transform];
    NSAffineTransform *xf = [NSAffineTransform transform];
 
    // Cocoa origin (0,0) in the lower left corner becomes the middle of the view
//  [xfTranslate translateXBy:(rectBounds.size.width / 2.0) yBy:(rectBounds.size.height / 2.0)];
    [xfTranslate translateXBy:(-_xMin*xPixelsPerUnit) yBy:(-_yMin*yPixelsPerUnit)];
    
    // The co-ordinate system in the dot log must be mapped (scaled) onto the view
    [xfScale scaleXBy:xPixelsPerUnit yBy:yPixelsPerUnit];
    
    [xf appendTransform:xfScale];
    [xf appendTransform:xfTranslate];
    
    if ( ! [self dotLog])
    {
        NSLog(@"dotLog is not yet present");
        return;
    }
   
    NSArray *dots = [[self dotLog] getDotsUpToCurrentFrame];

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:2];

    BOOL    firstPointOfPath = YES, firstPointOfLog = YES;
    int     colour           = 0, lastColour = 0;
    NSPoint previousPoint;

    for (Dot *dot in dots)
    {
        NSPoint p = [dot point];
        
        if ([dot waypoint] == YES)
        {
            colour = 0xffff0000;    // yellow
        }
        else
        {
            colour = [dot colour];
        }

        NSLog(@"plotting robot space (%.2f,%.2f) %08x", p.x, p.y, colour);
        
        /* If the colour changes on this point, close the old path and stroke in current
         * colour before switching colour.
         */
        
        if (colour != lastColour)
        {
            NSBezierPath *xfPath = [xf transformBezierPath:path];
            [xfPath stroke];
         
            path = [NSBezierPath bezierPath];
            [path setLineWidth:2];

            firstPointOfPath = YES;
        }

        if (firstPointOfPath)
        {
            if ( ! firstPointOfLog)
            {
                // Don't leave a gap from the last point
                [path moveToPoint:previousPoint];
                [path lineToPoint:p];
            }
            else
            {
                [path moveToPoint:p];
            }

            firstPointOfPath = NO;
        }
        else
        {
            [path lineToPoint:p];
        }
        
        if (colour != lastColour)
        {
            switch (colour)
            {
                case 0x0000ff00:
                    NSLog(@"colour changed to RED, starting new path");
                    [[NSColor redColor] setStroke];
                    break;
                    
                case 0x00ff0000:
                    NSLog(@"colour changed to GREEN, starting new path");
                    [[NSColor greenColor] setStroke];
                    break;
                    
                case 0xff00000:
                    NSLog(@"colour changed to BLUE, starting new path");
                    [[NSColor blueColor] setStroke];
                    break;
                    
                case 0xffff0000:
                    NSLog(@"colour changed to YELLOW, starting new path");
                    [[NSColor yellowColor] setStroke];
                    break;
                    
                default:
                    NSLog(@"colour changed to BLACK, starting new path");
                    [[NSColor blackColor] setStroke];
                    break;
            }
        }
        
        lastColour      = colour;
        previousPoint   = p;
        firstPointOfLog = NO;
    }

    // Close out the path
    NSBezierPath *xfPath = [xf transformBezierPath:path];
    [xfPath stroke];
}

@end
