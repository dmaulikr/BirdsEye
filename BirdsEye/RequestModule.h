//
//  RequestModule.h
//  BirdsEye
//
//  Created by Lee on 9/24/16.
//  Copyright © 2016 Shanelle's Marauders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestModule : NSObject

// designated initializer -hello
+ (RequestModule *)sharedModule;

// sends pingInfo to server and receives corresponding JSON obj
- (void) pingInfo: (NSInteger) userID andGroupID: (NSInteger) groupID andReturningData:(void(^)(NSDictionary*))callback;

// sends createGroupInfo to server and receives corresponding JSON obj
-(void) createGroupInfo: (NSString*) groupName andTeams: (NSInteger) teams andReturningData:(void(^)(NSDictionary*))callback;

// sends joinGroupInfo to server and receives corresponding JSON obj
-(void) joinGroupInfo: (NSInteger) groupID andTeam: (NSInteger) team andReturningData:(void(^)(NSDictionary*))callback;

- (void) getGroupInfoReturningData:(void(^)(NSDictionary*))callback;

// sends and receives JSON data from server - utilizes asynchronous callback (lambda function) that takes care of returning obj
- (void) sendServerInfo:(NSDictionary*) data andURL: (NSURL*) url andReturningData:(void(^)(NSDictionary*))callback;



@end
