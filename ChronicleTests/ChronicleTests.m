//
//  ChronicleTests.m
//  ChronicleTests
//
//  Created by Jeremy Tregunna on 7/18/2013.
//  Copyright (c) 2013 Jeremy Tregunna. All rights reserved.
//

#import "ChronicleTests.h"
#import "Chronicle.h"

@implementation ChronicleTests
{
    Chronicle* logger;
}

- (void)setUp
{
    [super setUp];

    logger = [Chronicle logger];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testLoggerSingleton
{
    STAssertEqualObjects(logger, [Chronicle logger], @"Should be one object");
}

- (void)testLoggerFactory
{
    Chronicle* l = [Chronicle chronicleWithName:@"testLoggerFactory" facility:nil options:0];
    STAssertNotNil(l, @"Must be valid");
}

- (void)testAddLogFile
{
    NSURL* tempFile = [self randomTemporaryURL];
    NSError* error = nil;
    Chronicle* l = [Chronicle chronicleWithName:@"testAddLogFile" facility:nil options:0];
    [l addFileAtURL:tempFile error:&error];
    STAssertNil(error, @"Must not have been an error");
}

- (void)testRemoveLogFile
{
    NSURL* tempFile = [self randomTemporaryURL];
    NSError* error = nil;
    Chronicle* l = [Chronicle chronicleWithName:@"testAddLogFile" facility:nil options:0];
    [l addFileAtURL:tempFile error:&error];
    STAssertNil(error, @"Adding file should have succeeded");
    [l closeFileAtURL:tempFile error:&error];
    STAssertNil(error, @"Closing a file should succeed");
}

- (void)testLogToFile
{
    NSURL* tempFile = [self randomTemporaryURL];
    NSError* error = nil;
    [logger addFileAtURL:tempFile error:&error];
    STAssertNil(error, @"Adding file should have succeeded");
    CLogEmergency(@"foo");
    NSData* d = [NSData dataWithContentsOfURL:tempFile options:0 error:&error];
    STAssertNotNil(d, @"Must have data");
    STAssertTrue(d.length > 0, @"Should have some content");
    [logger closeFileAtURL:tempFile error:&error];
}

- (NSURL*)randomTemporaryURL
{
    NSString* path = NSTemporaryDirectory();
    return [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
}

@end
