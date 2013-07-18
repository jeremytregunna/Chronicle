//
//  Chronicle.h
//  Chronicle
//
//  Created by Jeremy Tregunna on 7/18/2013.
//  Copyright (c) 2013 Jeremy Tregunna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Chronicle : NSObject

/// logger will return a different logger for each thread you're on.
+ (instancetype)logger;

/// You probably won't need to explicitly create one of these, but if you do, do not let it cross thread boundaries.
+ (instancetype)chronicleWithName:(NSString*)name facility:(NSString*)facility options:(uint32_t)options;

/// url is expected to be a local file url. We're only interested in the path component
- (void)addFileAtURL:(NSURL*)url failureBlock:(void (^)(NSError*))failureBlock;
- (void)closeFileAtURL:(NSURL*)url failureBlock:(void (^)(NSError*))failureBlock;

- (void)logLevel:(int)level format:(NSString*)formatString, ...;

@end

// Helpful macros
#define CLog(level, format, ...) [[Chronicle logger] logLevel:(level) format:(format), ## __VA_ARGS__ ]

#define CLogDebug(format, ...) CLog(ASL_LEVEL_DEBUG, format, ## __VA_ARGS__)
#define CLogInfo(format, ...) CLog(ASL_LEVEL_INFO, format, ## __VA_ARGS__)
#define CLogNotice(format, ...) CLog(ASL_LEVEL_NOTICE, format, ## __VA_ARGS__)
#define CLogWarning(format, ...) CLog(ASL_LEVEL_WARNING, format, ## __VA_ARGS__)
#define CLogError(format, ...) CLog(ASL_LEVEL_ERROR, format, ## __VA_ARGS__)
#define CLogAlert(format, ...) CLog(ASL_LEVEL_ALERT, format, ## __VA_ARGS__)
#define CLogEmergency(format, ...) CLog(ASL_LEVEL_EMERGENCY, format, ## __VA_ARGS__)