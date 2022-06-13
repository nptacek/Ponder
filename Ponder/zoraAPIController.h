//
//  zoraAPIController.h
//  Ponder
//
//  Created by nptacek.eth on 6/9/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSDictionary (NullReplacement)

- (NSDictionary *)dictionaryByReplacingNullsWithBlanks;

@end

@interface NSArray (NullReplacement)

- (NSArray *)arrayByReplacingNullsWithBlanks;

@end

NS_ASSUME_NONNULL_BEGIN

@interface zoraAPIController : NSObject

@property (strong) NSMutableArray *mutTokenHolderArray;
@property (strong) NSCountedSet *mutTokenContractCountedSet;
@property (strong) NSMutableSet *mutTempTokenContractSet;

+ (id)sharedInstance;

- (void)getStatsForContractAddress:(NSString *)contractAddressString withCompletionHandler:(void (^)(NSDictionary *statsDict))completionHandler;
- (void)getTokenHoldersForContractAddress:(NSString *)contractAddressString andOffset:(NSString *)offsetString withCompletionHandler:(void (^)(BOOL hasNextPage, NSArray *tokenHoldersArray))completionHandler;
- (void)getTokensForWalletAddress:(NSString *)walletAddressString andOffset:(NSString *)offsetString withCompletionHandler:(void (^)(BOOL hasNextPage, NSArray *tokenContractsArray))completionHandler;
- (void)getTokensForAddress:(NSString *)addressString andOffset:(NSString *)offsetString withCompletionHandler:(void (^)(BOOL hasNextPage, NSString *nextOffsetString, NSArray *tokenContractsArray))completionHandler;

@end

NS_ASSUME_NONNULL_END
