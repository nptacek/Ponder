//
//  zoraAPIController.m
//  Ponder
//
//  Created by nptacek.eth on 6/9/22.
//

#import "zoraAPIController.h"
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

#define apiURL [NSURL URLWithString:@"https://api.zora.co/graphql"]

#pragma mark - NSDictionary and NSArray Null Replacement Code
@implementation NSDictionary (NullReplacement)

- (NSDictionary *)dictionaryByReplacingNullsWithBlanks {
    const NSMutableDictionary *replaced = [self mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";

    for (NSString *key in self) {
        id object = [self objectForKey:key];
        if (object == nul) [replaced setObject:blank forKey:key];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced setObject:[object dictionaryByReplacingNullsWithBlanks] forKey:key];
        else if ([object isKindOfClass:[NSArray class]]) [replaced setObject:[object arrayByReplacingNullsWithBlanks] forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:[replaced copy]];
}

@end

@implementation NSArray (NullReplacement)

- (NSArray *)arrayByReplacingNullsWithBlanks  {
    NSMutableArray *replaced = [self mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    for (int idx = 0; idx < [replaced count]; idx++) {
        id object = [replaced objectAtIndex:idx];
        if (object == nul) [replaced replaceObjectAtIndex:idx withObject:blank];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced replaceObjectAtIndex:idx withObject:[object dictionaryByReplacingNullsWithBlanks]];
        else if ([object isKindOfClass:[NSArray class]]) [replaced replaceObjectAtIndex:idx withObject:[object arrayByReplacingNullsWithBlanks]];
    }
    return [replaced copy];
}

@end

@implementation zoraAPIController

@synthesize mutTokenHolderArray, mutTokenContractCountedSet, mutTempTokenContractSet;

- (id)init
{
    self = [super init];
    if (self != nil) {
        mutTokenHolderArray = [[NSMutableArray alloc] initWithCapacity:0];
        mutTokenContractCountedSet = [[NSCountedSet alloc] initWithCapacity:0];
        mutTempTokenContractSet = [[NSMutableSet alloc] initWithCapacity:0];
    }
    return self;
}

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

#pragma mark - API Methods -

- (void)getStatsForContractAddress:(NSString *)contractAddressString withCompletionHandler:(void (^)(NSDictionary *statsDict))completionHandler
{
    //  graphql query to get the following data for a given contract address:
    //      • name
    //      • nftCount
    //      • ownerCount
    //      • total sales volume
    //      • sales volume (by day, week, month, year, in total)
    
    NSString *statsQueryString = [NSString stringWithFormat:@"query collectionStatsQuery ($contractAddress: String=\"%@\") { aggregateStat {ownersByCount(where:{collectionAddresses:[$contractAddress]}, pagination:{ limit: 20}){ nodes { count owner}} nftCount(where:{collectionAddresses:[$contractAddress]}) ownerCount(where:{collectionAddresses:[$contractAddress]}) totalSalesVolume: salesVolume(where:{collectionAddresses:[$contractAddress]}){ chainTokenPrice usdcPrice totalCount } lastDaySalesVolume: salesVolume(where:{collectionAddresses:[$contractAddress]}, timeFilter: {lookbackHours: 24}){ chainTokenPrice usdcPrice totalCount } lastWeekSalesVolume: salesVolume(where:{collectionAddresses:[$contractAddress]}, timeFilter: {lookbackHours: 168}){ chainTokenPrice usdcPrice totalCount } last30DaysSalesVolume: salesVolume(where:{collectionAddresses:[$contractAddress]}, timeFilter: {lookbackHours: 720}){ chainTokenPrice usdcPrice totalCount } lastYearSalesVolume: salesVolume(where:{collectionAddresses:[$contractAddress]}, timeFilter: {lookbackHours: 8760}){ chainTokenPrice usdcPrice totalCount } } collections(where:{collectionAddresses:[$contractAddress]}){nodes{address name symbol}} }", contractAddressString];
    
    [self getDataForQuery:statsQueryString withCompletionHandler:^(NSDictionary *statsDataDict) {
        if (statsDataDict != nil) {
            completionHandler(statsDataDict);
        }
        else {
            completionHandler(nil);
        }
    }];
}

- (void)getTokenHoldersForContractAddress:(NSString *)contractAddressString andOffset:(NSString *)offsetString withCompletionHandler:(void (^)(BOOL hasNextPage, NSArray *tokenHoldersArray))completionHandler
{
    NSString *tokenHoldersQueryString = [NSString stringWithFormat:@"query tokenHoldersQuery ($contractAddress: String=\"%@\") { aggregateStat {ownersByCount(where:{collectionAddresses:[$contractAddress]}, pagination:{ limit: 500, after: \"%@\"}){ nodes { count owner } pageInfo { hasNextPage endCursor}} } }", contractAddressString, offsetString];
    
    [self getDataForQuery:tokenHoldersQueryString withCompletionHandler:^(NSDictionary *tokenHoldersDataDict) {
        if (tokenHoldersDataDict != nil) {
            NSMutableArray *mutOwnerArray = [[NSMutableArray alloc] initWithCapacity:0];
            for(NSDictionary *nodeDict in [tokenHoldersDataDict valueForKeyPath:@"data.aggregateStat.ownersByCount.nodes"]){
                [mutOwnerArray addObject:[nodeDict objectForKey:@"owner"]];
            }

            //check if the next page flag is set or not
            if([[[tokenHoldersDataDict valueForKeyPath:@"data.aggregateStat.ownersByCount.pageInfo"] objectForKey:@"hasNextPage"] boolValue]){
                [self getTokenHoldersForContractAddress:contractAddressString andOffset:[tokenHoldersDataDict valueForKeyPath:@"data.aggregateStat.ownersByCount.pageInfo.endCursor"] withCompletionHandler:completionHandler];
                completionHandler(YES, [mutOwnerArray copy]);
            }
            else {
                NSLog(@"ALL DONE!");
                completionHandler(NO, [mutOwnerArray copy]);
            }
        }
        else {
            completionHandler(NO, nil);
        }
    }];
}

- (void)getTokensForWalletAddress:(NSString *)walletAddressString andOffset:(NSString *)offsetString withCompletionHandler:(void (^)(BOOL hasNextPage, NSArray *tokenContractsArray))completionHandler
{
    NSString *walletContentsQueryString = [NSString stringWithFormat:@"query walletContentsQuery ($walletAddress: String=\"%@\") { tokens(where:{ownerAddresses:[$walletAddress]}, pagination:{ limit: 500, after: \"%@\"}){ nodes { token { collectionAddress } } pageInfo { hasNextPage endCursor}} }", walletAddressString, offsetString];
    
    [self getDataForQuery:walletContentsQueryString withCompletionHandler:^(NSDictionary *walletContentsDataDict) {
        if (walletContentsDataDict != nil) {
            NSMutableArray *mutTokenArray = [[NSMutableArray alloc] initWithCapacity:0];
            for(NSDictionary *tokenDict in [walletContentsDataDict valueForKeyPath:@"data.tokens.nodes"]){
                [mutTokenArray addObject:[tokenDict valueForKeyPath:@"token.collectionAddress"]];
            }

            //check if the next page flag is set or not
            if([[[walletContentsDataDict valueForKeyPath:@"data.tokens.pageInfo"] objectForKey:@"hasNextPage"] boolValue]){
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self getTokensForWalletAddress:walletAddressString andOffset:[walletContentsDataDict valueForKeyPath:@"data.tokens.pageInfo.endCursor"] withCompletionHandler:completionHandler]; //to do: we need to put a rate limiter in here or something
                });
                completionHandler(YES, [mutTokenArray copy]);
            }
            else {
            //    NSLog(@"ALL DONE!");
                completionHandler(NO, [mutTokenArray copy]);
            }
        }
        else {
            completionHandler(NO, nil);
        }
    }];
}

#pragma mark - graphql query code
- (void)getDataForQuery:(NSString *)queryString withCompletionHandler:(void (^)(NSDictionary *responseDataDict))completionHandler
{
    // serialize our graphql query string to json and store it as nsdata
    NSDictionary *jsonStringDict = @{
        @"query": queryString
    };
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonStringDict options:NSJSONWritingFragmentsAllowed error:&error];
 
    // create URL request, set up the headers, and set the body to our graphql query
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;

    // initiatialize the session and data task
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *taskError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response; //DEBUG CODE
    //    NSLog(@"response status code: %ld", (long)httpResponse.statusCode);   //DEBUG CODE
        if (taskError) {
          // data task encountered an error
            NSLog(@"getDataForQuery task error: %@", taskError);
            completionHandler(nil); //return nil so we can handle the error in ther UI
        }
        else if(httpResponse.statusCode == 502){
            NSLog(@"Status code 502");
            //we need to retry when we get 502's
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self getDataForQuery:queryString withCompletionHandler:completionHandler]; //to do: we need to put a rate limiter in here or something
            });
        }
        else if(httpResponse.statusCode == 429){
            NSLog(@"Status code 429, slow down!");
            //we need to retry when we get 502's
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self getDataForQuery:queryString withCompletionHandler:completionHandler]; //to do: we need to put a rate limiter in here or something
            });
        }
        else {
            //  we got data back, let's extract the json response from it
                NSError *jsonError;
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (jsonError) {
                    // encountered an error parsing json
                    NSLog(@"getDataFrom jsonError: %@", jsonError);
                    completionHandler(nil); //return nil so we can handle the error in ther UI
                } else {
                    // successfully parsed json response
                    NSDictionary *jsonResponseDict = [jsonResponse dictionaryByReplacingNullsWithBlanks]; //  strip NSNulls from the json output, otherwise it won't play well with obj-c later on for core data stuff
                    completionHandler(jsonResponseDict);    //  return the stripped json response dict for further parsing by app
                }
        }
      }];

    [dataTask resume];  //  start the data query task asynchronously
}

@end
