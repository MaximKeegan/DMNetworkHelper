//
//  DMNetworkHelperRequestTask.m
//  DMNetworkHelper
//
//  Created by Avvakumov Dmitry on 15.12.15.
//  Copyright © 2015 Dmitry Avvakumov. All rights reserved.
//

// frameworks
#import <StandardPaths/StandardPaths.h>
#import <AFNetworking/AFNetworking.h>

#import "DMNetworkHelperRequestTask.h"

#import "DMNetworkHelperBasicTaskProtected.h"

#import "DMNetworkHelperManager.h"

@interface DMNetworkHelperRequestTask ()

@property (copy, nonatomic) DMNetworkHelperRequestTaskFinishBlock finishBlock;

@end

@implementation DMNetworkHelperRequestTask

#pragma mark - Start execution

- (void)executeWithCompletitionBlock:(DMNetworkHelperRequestTaskFinishBlock)finishBlock {
    self.finishBlock = finishBlock;
    
    [DM_NHM_SharedInstance addOperation:self];
}

#pragma mark - Implementation

- (void)start {
    if ([self isCancelled]) {
        [self finish];
        
        return;
    }
    
    // performing request
    AFHTTPSessionManager *manager = [DMNetworkHelperManager sharedInstance].sessionManager;
    
    // result queue
    manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // request serializer
    AFHTTPRequestSerializer *requestSerializer = manager.requestSerializer;
    if (requestSerializer == nil) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
        
        manager.requestSerializer = requestSerializer;
    }
    
    NSString *requestURL = [self absolutePath];
    if (requestURL == nil) {
        requestURL = [DM_NHM_SharedInstance requestURLByAppendPath:[self relativePath]];
    }
    
    NSString *method = [self methodString];
    
    // weak self
    __weak typeof (self) weakSelf = self;
    
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:method URLString:requestURL parameters:self.params error:nil];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        typeof (weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf afterExecutionWithResponse:(NSHTTPURLResponse *) response object:responseObject error:error];
    }];
    
    [dataTask resume];
}

- (void)afterExecutionWithResponse:(NSHTTPURLResponse *)response object:(id)responseObject error:(NSError *)error {
    
    void(^beforeParseBlock)(NSHTTPURLResponse *response, NSError *error, BOOL *shouldContinue) = [DMNetworkHelperManager sharedInstance].beforeParseResponseBlock;
    
    if (beforeParseBlock) {
        BOOL shouldContinue = YES;
        
        beforeParseBlock(response, error, &shouldContinue);
        
        if (shouldContinue == NO) {
            
            [self finish];
            
            return;
        }
    }
    
    // competition queue
    dispatch_queue_t queue = self.completionQueue;
    if (queue == NULL) {
        queue = dispatch_get_main_queue();
    }
    
    // check for error
    if (error) {
        if (_finishBlock) {
            dispatch_async(queue, ^{
                _finishBlock(nil, error);
            });
        }
        
        [self finish];
        
        return;
    }
    
    // parse response
    NSUInteger options = [self responseOptions];
    NSString *key = [self findByKey];
    
    // store response
    self.responseObject = responseObject;
    
    // check if empty not avaliable
    if (!(options & DMNetworkHelperResponseOptionJsonEmptyAvaliable)) {
        if (responseObject == nil) {
            [self finishWithErrorCode:-1 message:@"Empty server response"];
            
            return;
        }
    }
    
    // check result as dictionary
    if (options & DMNetworkHelperResponseOptionResultIsArray) {
        
        NSArray *rawItems = [self findInJson:responseObject byKey:key];
        if (rawItems && [rawItems isKindOfClass:[NSArray class]]) {
            self.allItems = rawItems;
        }
        
    } else {
        
        NSDictionary *rawItem = [self findInJson:responseObject byKey:key];
        if (rawItem && [rawItem isKindOfClass:[NSDictionary class]]) {
            self.oneItem = rawItem;
        }
    }
    
    // weak self
    __weak typeof (self) weakSelf = self;
    
    // middle processing
    [self parseResponseWithFinishBlock:^(id result, NSError *error) {
        typeof (weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) return ;
        
        [strongSelf afterParsingResponseWithResult:result orError:error];
    }];
    
}

- (void)afterParsingResponseWithResult:(id)result orError:(NSError *)error {
    
    // competition queue
    dispatch_queue_t queue = self.completionQueue;
    if (queue == NULL) {
        queue = dispatch_get_main_queue();
    }
    
    if (_finishBlock) {
        dispatch_async(queue, ^{
            _finishBlock(result, error);
        });
    }
    
    [self finish];
}


- (void)finishWithErrorCode:(NSInteger)code message:(NSString *)message {
    // competition queue
    dispatch_queue_t queue = self.completionQueue;
    if (queue == NULL) {
        queue = dispatch_get_main_queue();
    }
    
    // error
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message, @"from": @"DMNetworkHelper" };
    NSError *error = [NSError errorWithDomain:DM_NHM_SharedInstance.url code:code userInfo:userInfo];
    
    if (_finishBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            _finishBlock(nil, error);
        });
    }
    
    [self finish];
}

@end
