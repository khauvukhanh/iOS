//
//  ContentManager.m
//  Food
//
//  Created by TNKHANH on 12/11/17.
//  Copyright © 2017 TNKHANH. All rights reserved.
//

#import "ContentManager.h"
#import "Reachability.h"

@implementation ContentManager

+ (ContentManager *)shareManager
{
    static ContentManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ContentManager alloc] init];
    });
    
    return manager;
}

- (void)getFoodListWithCompletion:(void(^)(BOOL success, NSArray *foodList, NSString *errorMessage))callBack
{
    
    [self sendRequestWithUrl:URL_GET_ALL_RECIPE header:nil parameter:nil method:@"GET" completion:^(BOOL success, NSDictionary *responseDict, NSString *errorMessage) {
        
        if (success)
        {
            NSMutableArray *foodList = [[NSMutableArray alloc] init];
            
            for (NSDictionary *temp in [responseDict objectForKey:@"recipes"])
            {
                [foodList addObject:[FoodModel foodModelFromDict:temp]];
            }
            
            callBack(YES,foodList,nil);
            
        }
        else
        {
            callBack(NO,nil,errorMessage);
        }
        
        
    }];
}

- (void)sendRequestWithUrl:(NSString *)urlString header:(NSDictionary *)header parameter:(NSDictionary *)param method:(NSString *)method completion:(void(^)(BOOL success, NSDictionary *responseDict, NSString *errorMessage))callBack
{
    Reachability *networkChecking = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [networkChecking currentReachabilityStatus];
    
    if (status == NotReachable)
    {
        callBack(NO,nil,@"There's not internet connection");
    }
    else
    {
         NSURLRequest *request = [self createRequestWithUrl:urlString header:header parameter:param method:method];
         
         NSURLSession *session = [NSURLSession sharedSession];
         NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         
         BOOL success;
         NSDictionary *json;
         NSString *errorString;
         
         if (error != nil)
         {
         success = NO;
         errorString = [error description];
         }
         else
         {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         NSLog(@"Header code: %ld", [httpResponse statusCode]);
         
         if ([httpResponse statusCode] == 200 ||[httpResponse statusCode] == 201 )
         {
         NSError *newError = nil;
         
         json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&newError];
         
         if (newError == nil)
         {
         success = YES;
         errorString = nil;
         
         }
         else
         {
         success = NO;
         errorString = @"Error parse data";
         }
         }
         else
         {
         success = NO;
         errorString = @"Error in server";
         }
         }
         
         
         dispatch_async(dispatch_get_main_queue(), ^{
         callBack(success, json, errorString);
         });
         
         }];
         
         [dataTask resume];
    }
}


- (NSURLRequest *)createRequestWithUrl:(NSString *)urlString header:(NSDictionary *)header parameter:(NSDictionary *)param method:(NSString *)method
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:30];
    
    [request setHTTPMethod:method];
    
    
    if (header != nil)
    {
        for (NSString *key in [header allKeys])
        {
            [request setValue:[header objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    if (param != nil)
    {
        NSMutableData *data = [[NSMutableData alloc] init];
        for (int i = 0; i < [param allKeys].count; i++)
        {
            NSString *key = [[param allKeys] objectAtIndex:i];
            
            id value = [param objectForKey:key];
            
            [data appendData:[[NSString stringWithFormat:@"%@=",key] dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:[[NSString stringWithFormat:@"%@&",value] dataUsingEncoding:NSUTF8StringEncoding]];
            
        }
        
        [request setHTTPBody:data];
    }
    
    return request;
}


@end
