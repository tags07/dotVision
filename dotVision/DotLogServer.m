//
//  DotLogServer.m
//  dotVision
//
//  Created by jjs on 29/11/2015.
//  Copyright (c) 2015 oroboto. All rights reserved.
//

#import "DotLogServer.h"
#import "AppDelegate.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <errno.h>
#import <stdio.h>
#import <netdb.h>
#import <unistd.h>
#import <fcntl.h>
#import <arpa/inet.h>

@interface DotLogServer ()
{
    int                 _socket;
    dispatch_source_t   _socketSource;
}

@end

@implementation DotLogServer

- (instancetype)init
{
    return [self initWithDisplayController:nil];
}

- (instancetype)initWithDisplayController:(id)displayController
{
    if (self = [super init])
    {
        if ( ! displayController)
        {
            [NSException raise:@"init" format:@"A displayController must be specified"];
        }
        
        _running = NO;

        NSLog(@"DotLogServer initialised ...");
        self.displayController = displayController;
    }
    
    return self;
}

- (BOOL)start
{
    struct addrinfo hints, *res = NULL;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_INET;
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags    = AI_PASSIVE;
    
    @try
    {
        int     ret;
        
        NSLog(@"Starting DotLogServer ...");

        if ((ret = getaddrinfo(NULL, kDotLogServerPort, &hints, &res)) != 0)
        {
            NSException *e = [NSException exceptionWithName:@"GetAddrInfoException" reason:[NSString stringWithFormat:@"Could not lookup local address: %s", gai_strerror(ret)] userInfo:nil];
            @throw e;
        }
        
        if ((_socket = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) < 0)
        {
            NSException *e = [NSException exceptionWithName:@"SocketException" reason:[NSString stringWithFormat:@"Could not create socket: %s", strerror(errno)] userInfo:nil];
            @throw e;
        }

        // Do non-blocking reads so we don't block the task that runs on the queue (ie. allow the queue to run other tasks too)
        fcntl(_socket, F_SETFL, O_NONBLOCK);
        
        if (bind(_socket, res->ai_addr, res->ai_addrlen) < 0)
        {
            NSException *e = [NSException exceptionWithName:@"BindException" reason:[NSString stringWithFormat:@"Could not bind socket: %s", strerror(errno)] userInfo:nil];
            @throw e;
        }
        
        NSLog(@"DotLogServer listening on port %s", kDotLogServerPort);

        // Create a dispatch source that will schedule our block when there is data to read from the socket
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _socketSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _socket, 0, queue);
        
        if ( ! _socketSource)
        {
            NSException *e = [NSException exceptionWithName:@"GetAddrInfoException" reason:@"Could not create GCD dispatch source" userInfo:nil];
            @throw e;
        }
        
        // Install the read handler. This block is scheduled whenever there is data available to read.
        dispatch_source_set_event_handler(_socketSource, ^{
            size_t          approxBytesAvailable = dispatch_source_get_data(_socketSource);
            int             bytesRead;
            struct sockaddr remoteAddr;
            socklen_t       remoteAddrLen = sizeof(remoteAddr);
            
            NSLog(@"GCD ready to read approximately %lu bytes", approxBytesAvailable);

            if (approxBytesAvailable)
            {
                char *buffer = malloc(approxBytesAvailable+1);
                
                if (buffer)
                {
                    if ((bytesRead = recvfrom(_socket, buffer, approxBytesAvailable, 0, (struct sockaddr *)&remoteAddr, &remoteAddrLen)) < 0)
                    {
                        NSLog(@"Unable to read from UDP socket");
                    }
                    else
                    {
                        buffer[bytesRead] = '\0';
                        NSString *line    = [NSString stringWithUTF8String:buffer];

                        NSLog(@"Read %d bytes: %s", bytesRead, buffer);

                        // Schedule this block back onto the main UI thread
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSArray *tokens = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                            // @todo: support colour and waypoint marker
                            if ([tokens count] < 3)
                            {
                                NSLog(@"Ignoring invalid line: %@", line);
                                return;
                            }
                            
                            float timestamp = [[tokens objectAtIndex:0] floatValue];

                            CGPoint p;
                            p.x = [[tokens objectAtIndex:1] floatValue];
                            p.y = [[tokens objectAtIndex:2] floatValue];
                            
                            [self.displayController addDot:p withTimestamp:timestamp];
                        });
                    }

                    free(buffer);
                }
            }
        });
        
        dispatch_source_set_cancel_handler(_socketSource, ^{
            NSLog(@"GCD dispatch source has been cancelled");

            close(_socket);

            _socket  = 0;
            _running = NO;
        });
        
        NSLog(@"Starting DotLogServer dispatch source ...");
        
        // Start waiting for data
        dispatch_resume(_socketSource);
        
        _running = YES;
    }
    @catch (NSException *e)
    {
        NSLog(@"Exception [%@]: %@", e.name, e.reason);

        if (_socket >= 0)
        {
            close(_socket);
            _socket = 0;
        }

        return NO;
    }
    @finally
    {
        if (res)
        {
            freeaddrinfo(res);
        }
    }

    return YES;
}

- (void)stop
{
    NSLog(@"Cancelling GCD dispatch source");
    dispatch_source_cancel(_socketSource);
}

@end
