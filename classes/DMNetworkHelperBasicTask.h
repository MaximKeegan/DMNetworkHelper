//
//  DMNetworkHelperBasicTask.h
//  DMNetworkHelper
//
//  Created by Avvakumov Dmitry on 15.12.15.
//  Copyright © 2015 Dmitry Avvakumov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;

typedef enum {
    DMNetworkHelperTaskMethod_GET,
    DMNetworkHelperTaskMethod_PUT,
    DMNetworkHelperTaskMethod_POST
} DMNetworkHelperTaskMethod;

/**
 Defines "options" for parse response in a bitmask.
 
 */
typedef NS_ENUM (NSUInteger, DMNetworkHelperResponseOptions)
{
    /** Empty response avaliability */
    DMNetworkHelperResponseOptionJsonEmptyAvaliable = 1 << 0,
    
    /** Check result as array */
    DMNetworkHelperResponseOptionResultIsArray = 1 << 1,
    
    /** Check result as dictionary */
    DMNetworkHelperResponseOptionResultIsDictionary = 1 << 2,

};

@interface DMNetworkHelperBasicTask : NSOperation

@property (strong, nonatomic) id params;

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/**
 * Request params
 *
 */
- (NSString *)absolutePath;
- (NSString *)relativePath;
- (DMNetworkHelperTaskMethod) method;

/**
 * Response params
 *
 */
@property (strong, nonatomic) id responseObject;

@property (strong, nonatomic) NSArray *allItems;
@property (strong, nonatomic) NSDictionary *oneItem;

- (DMNetworkHelperResponseOptions)responseOptions;

- (NSString *)findByKey;

- (void)parseResponseWithFinishBlock:(void(^)(id result, NSError *error))finishParseBlock;


@end
