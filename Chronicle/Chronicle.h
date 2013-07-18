//
//  Chronicle.h
//  Chronicle
//
//  Created by Jeremy Tregunna on 7/18/2013.
//  Copyright (c) 2013 Jeremy Tregunna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>

@interface Chronicle : NSObject

/// logger will return a single instance protected by a serial queue. This has some consequences. For starters, if you are logging a lot from a bunch of different threads, we wait until one log statement is done somewhere in the app before we'll process the next one.
+ (instancetype)logger;

/// You probably won't need to explicitly create one of these, but if you do, do not let it cross thread boundaries.
+ (instancetype)chronicleWithName:(NSString*)name facility:(NSString*)facility options:(uint32_t)options;

/// url is expected to be a local file url. We're only interested in the path component
- (void)addFileAtURL:(NSURL*)url error:(NSError* __autoreleasing*)error;
- (void)closeFileAtURL:(NSURL*)url error:(NSError* __autoreleasing*)error;

- (void)logLevel:(int)level format:(NSString*)formatString, ...;

@end

// Helpful macros
#define CLog(level, fmt, ...) [[Chronicle logger] logLevel:level format:fmt, ##__VA_ARGS__]

#define CLogDebug(format, ...) CLog(ASL_LEVEL_DEBUG, format, ## __VA_ARGS__)
#define CLogInfo(format, ...) CLog(ASL_LEVEL_INFO, format, ## __VA_ARGS__)
#define CLogNotice(format, ...) CLog(ASL_LEVEL_NOTICE, format, ## __VA_ARGS__)
#define CLogWarning(format, ...) CLog(ASL_LEVEL_WARNING, format, ## __VA_ARGS__)
#define CLogError(format, ...) CLog(ASL_LEVEL_ERR, format, ## __VA_ARGS__)
#define CLogCritical(format, ...) CLog(ASL_LEVEL_CRIT, format, ## __VA_ARGS__)
#define CLogAlert(format, ...) CLog(ASL_LEVEL_ALERT, format, ## __VA_ARGS__)
#define CLogEmergency(format, ...) CLog(ASL_LEVEL_EMERG, format, ## __VA_ARGS__)