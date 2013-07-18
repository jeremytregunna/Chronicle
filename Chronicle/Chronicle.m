//
//  Chronicle.m
//  Chronicle
//
//  Created by Jeremy Tregunna on 7/18/2013.
//  Copyright (c) 2013 Jeremy Tregunna. All rights reserved.
//

#import "Chronicle.h"
#import <asl.h>

static NSString* const ChronicleErrorDomain = @"ChronicleErrorDomain";
static NSString* const ChronicleFileURL = @"ChronicleFileURL";
static NSString* const ChronicleInternalInconsistencyException = @"ChronicleInternalInconsistencyException";
static NSInteger ChronicleInvalidClientCode = 1001;
static NSInteger ChronicleInvalidFileHandle = 1002;

static NSString* const ChronicleDefaultLogger = @"__ChronicleDefaultLogger";

@interface Chronicle ()
@property (nonatomic, assign) aslclient client;
@property (nonatomic, strong) NSMutableDictionary* files;
@end

@implementation Chronicle
{
    dispatch_queue_t _sourceQueue;
}

+ (instancetype)logger
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] initWithName:ChronicleDefaultLogger facility:NULL options:0];
    });
    return shared;
}

+ (instancetype)chronicleWithName:(NSString*)name facility:(NSString*)facility options:(uint32_t)options
{
    return [[self alloc] initWithName:name facility:facility options:options];
}

- (instancetype)initWithName:(NSString*)name facility:(NSString*)facility options:(uint32_t)options
{
    if((self = [super init]))
    {
        _files = [NSMutableDictionary dictionary];
        _client = asl_open([name UTF8String], facility ? [facility UTF8String] : NULL, options);
        _sourceQueue = dispatch_queue_create("ca.tregunna.libs.chronicle.sourceQueue", 0);
    }
    return self;
}

- (void)dealloc
{
    if(_client != NULL)
    {
        asl_close(_client);
        _client = NULL;
    }
}

#pragma mark - Files

- (void)addFileAtURL:(NSURL*)url error:(NSError* __autoreleasing*)error
{
    if(_client == NULL)
    {
        *error = [NSError errorWithDomain:ChronicleErrorDomain code:ChronicleInvalidClientCode userInfo:@{ ChronicleFileURL: url }];
        return;
    }

    @synchronized(_files)
    {
        NSString* path = url.path;
        if(_files[path] != nil)
            return;

        NSError* handleError = nil;
        NSFileHandle* handle = [NSFileHandle fileHandleForWritingToURL:url error:&handleError];
        if(handle == nil)
        {
            NSFileManager* fm = [[NSFileManager alloc] init];
            [fm createFileAtPath:url.path contents:nil attributes:nil];
            handle = [NSFileHandle fileHandleForWritingToURL:url error:error];
        }

        if(*error == nil)
        {
            _files[path] = handle;
            [self _sendAddFileTaskWithFileHandle:handle error:error];
        }
    }
}

- (void)closeFileAtURL:(NSURL*)url error:(NSError* __autoreleasing*)error
{
    if(_client == NULL)
    {
        *error = [NSError errorWithDomain:ChronicleErrorDomain code:ChronicleInvalidClientCode userInfo:@{ ChronicleFileURL: url }];
        return;
    }

    @synchronized(_files)
    {
        NSString* path = url.path;
        NSFileHandle* handle = _files[path];
        if(handle == nil)
        {
            @throw [NSException exceptionWithName:ChronicleInternalInconsistencyException reason:@"A corresponding file handle was not found in our dictionary of file handles" userInfo:@{ ChronicleFileURL: url }];
        }

        [self _sendRemoveFileTaskWithURL:url fileHandle:handle error:error];
    }
}

#pragma mark - Logging

- (void)logLevel:(int)level format:(NSString*)formatString, ...
{
    va_list args;
	va_start(args, formatString);
	NSString* msg = [[NSString alloc] initWithFormat:formatString arguments:args];
	va_end(args);
    [self _sendLogTaskWithMessage:msg level:level];
}

#pragma mark - Private helpers

- (void)_sendLogTaskWithMessage:(NSString*)formattedMessage level:(int)level
{
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_sourceQueue, ^{
        typeof(weakSelf) strongSelf = weakSelf;
        asl_log(strongSelf.client, NULL, level, [formattedMessage UTF8String], NULL);
    });
}

- (void)_sendAddFileTaskWithFileHandle:(NSFileHandle*)handle error:(NSError* __autoreleasing*)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_sourceQueue, ^{
        typeof(weakSelf) strongSelf = weakSelf;

        if(asl_add_log_file(strongSelf.client, handle.fileDescriptor) != 0)
        {
            *error = [NSError errorWithDomain:ChronicleErrorDomain code:ChronicleInvalidFileHandle userInfo:nil];
        }
    });
}

- (void)_sendRemoveFileTaskWithURL:(NSURL*)url fileHandle:(NSFileHandle*)handle error:(NSError* __autoreleasing*)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_sourceQueue, ^{
        typeof(weakSelf) strongSelf = weakSelf;

        @synchronized(strongSelf.files)
        {
            [strongSelf.files removeObjectForKey:url.path];
        }
        if(asl_remove_log_file(strongSelf.client, handle.fileDescriptor) != 0)
        {
            *error = [NSError errorWithDomain:ChronicleErrorDomain code:ChronicleInvalidFileHandle userInfo:nil];
        }
    });
}

@end
