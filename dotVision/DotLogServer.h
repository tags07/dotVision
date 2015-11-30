//
//  DotLogServer.h
//  dotVision
//
//  Created by jjs on 29/11/2015.
//  Copyright (c) 2015 oroboto. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDotLogServerPort   "50607"

@protocol DotLogDisplayController

- (void)addDot:(CGPoint)dotPoint withTimestamp:(float)timestamp;

@end

@interface DotLogServer : NSObject

@property (weak) id <DotLogDisplayController>   displayController;
@property (assign, readonly) BOOL               running;

- (instancetype)init;
- (instancetype)initWithDisplayController:(id)displayController;

- (BOOL)start;
- (void)stop;

@end
