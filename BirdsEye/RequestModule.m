//
//  RequestModule.m
//  BirdsEye
//
//  Created by Lee on 9/24/16.
//  Copyright © 2016 Shanelle's Marauders. All rights reserved.
//

#import "RequestModule.h"
#import "LocationModule.h"

@implementation RequestModule



- (void) connectBackEnd: (NSInteger) user_id andgroup_id: (NSInteger) group_id
{
    // configures NSURL session
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // creates NSURL request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL
                                                 URLWithString:@"to-be-filled-in-later.com"]];
    
    
    // initializes location module object
    LocationModule * module = [LocationModule sharedModule];
    
    // initializes NSDictionary object to use for creating a JSON
    NSMutableDictionary *dict= [@{
                                  @"user_ID" : @(user_id),
                                  @"group_ID" : @(group_id),
                                  @"latitude" : @(module.latitude),
                                  @"longitude" : @(module.longitude),
                                  @"uncertaintyRadius" : @(module.uncertaintyRadius),
                                  @"speed" : @(module.speed),
                                  @"direction": @(module.direction),
                                  @"location" : @(1)
                                  }mutableCopy];
    
    // creates JSON data object
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    // sets method type and body
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    // sends the data
    if (!error)
    {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                  fromData:jsonData completionHandler:^(NSData *responseData,NSURLResponse *response,NSError *error) {
                                                                      // Handle response here
                                                                  }];
        [uploadTask resume];
        
    }

    
}





@end
