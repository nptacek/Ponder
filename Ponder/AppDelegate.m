//
//  AppDelegate.m
//  Ponder
//
//  Created by nptacek.eth on 6/9/22.
//

#import "AppDelegate.h"
#import "zoraAPIController.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)getCollectionStatsAction:(id)sender
{
    if([self didValidateContractAddress:self.addContractPanelAddressField.stringValue]){
        zoraAPIController *myZoraAPIController = [zoraAPIController sharedInstance];
        [myZoraAPIController getStatsForContractAddress:self.addContractPanelAddressField.stringValue withCompletionHandler:^(NSDictionary *statsDict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //update UI here
                [self.contractAddressOutputField setStringValue:[[[statsDict valueForKeyPath:@"data.collections.nodes"] objectAtIndex:0] objectForKey:@"address"]];
                [self.contractNameOutputField setStringValue:[[[statsDict valueForKeyPath:@"data.collections.nodes"] objectAtIndex:0] objectForKey:@"name"]];
                [self.contractSymbolOutputField setStringValue:[[[statsDict valueForKeyPath:@"data.collections.nodes"] objectAtIndex:0] objectForKey:@"symbol"]];
                [self.contractTotalSupplyOutputField setStringValue:[[statsDict valueForKeyPath:@"data.aggregateStat"] objectForKey:@"nftCount"]];
                [self.contractOwnerCountOutputField setStringValue:[[statsDict valueForKeyPath:@"data.aggregateStat"] objectForKey:@"ownerCount"]];
                
                NSString *ownerString = @"";
                for(NSDictionary *ownerDict in [statsDict valueForKeyPath:@"data.aggregateStat.ownersByCount.nodes"]){
                    ownerString = [ownerString stringByAppendingFormat:@"%@ (%@)\n", [ownerDict objectForKey:@"owner"], [ownerDict objectForKey:@"count"]];
                }
                
                [self.contractStatsOutputField setStringValue:ownerString];
            });
        }];
    }
    else{
        NSLog(@"please enter a valid hex address!");
    }
}

- (IBAction)getTopCollectionsAction:(id)sender
{
    if([self didValidateContractAddress:self.addContractPanelAddressField.stringValue]){
        __block NSMutableArray *mutOwnerArray = [[NSMutableArray alloc] initWithCapacity:0];
        zoraAPIController *myZoraAPIController = [zoraAPIController sharedInstance];
        [myZoraAPIController getTokenHoldersForContractAddress:self.addContractPanelAddressField.stringValue andOffset:@"" withCompletionHandler:^(BOOL hasNextPage, NSArray *tokenHoldersArray) {
            [mutOwnerArray addObjectsFromArray:tokenHoldersArray];
            if(hasNextPage){
            //    NSLog(@"hasNextPage");
            }
            else {
                NSLog(@"NO");
                NSLog(@"tokenHoldersArray: %lu", (unsigned long)[tokenHoldersArray count]);
                NSLog(@"mutOwnerArray count: %lu", (unsigned long)[mutOwnerArray count]);
                [self parseMultipleWallets:[mutOwnerArray copy]];
            }
        }];
    }
    else{
        NSLog(@"please enter a valid hex address!");
    }
}

- (void)parseMultipleWallets:(NSArray *)walletAddressArray
{
    NSMutableArray *arrayOfArrays = [NSMutableArray array];
    int batchSize = 10;

    for(int j = 0; j < [walletAddressArray count]; j += batchSize) {

        NSArray *subarray = [walletAddressArray subarrayWithRange:NSMakeRange(j, MIN(batchSize, [walletAddressArray count] - j))];
        [arrayOfArrays addObject:subarray];
    }
    
    NSLog(@"arrayOfArrays: %@", arrayOfArrays);
    [self parseMultipleWallets2:arrayOfArrays];
}

- (void)parseMultipleWallets2:(NSArray *)walletAddressArray
{
    NSLog(@"parsing multiple wallets!");
    
    zoraAPIController *myZoraAPIController = [zoraAPIController sharedInstance];
    
    __block NSCountedSet *aggregateContractCountedSet = [[NSCountedSet alloc] initWithCapacity:0];
    __block NSMutableArray *mutContractArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSTimeInterval delayInSeconds = -2.0;
    
    for(int n = 0; n < [walletAddressArray count]; n+=1){
        delayInSeconds += 2.0;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            for(NSString *walletAddressString in [walletAddressArray objectAtIndex:n]){
                NSLog(@"Analyzing wallet address: %@", walletAddressString);
                [myZoraAPIController getTokensForWalletAddress:walletAddressString andOffset:@"" withCompletionHandler:^(BOOL hasNextPage, NSArray *tokenContractsArray) {
                    [mutContractArray addObjectsFromArray:tokenContractsArray];
                    if(hasNextPage){
                     //   NSLog(@"hasNextPage");
                    }
                    else {
                        NSCountedSet *myCountedSet = [[NSCountedSet alloc] initWithCapacity:0];
                        [myCountedSet addObjectsFromArray:[mutContractArray copy]];
                        
                        [aggregateContractCountedSet addObjectsFromArray:[myCountedSet allObjects]];
                        
                        NSLog(@"aggregateContractCountedSet count: %lu", [aggregateContractCountedSet count]);

                            NSMutableArray *dictArray = [NSMutableArray array];
                            [aggregateContractCountedSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                [dictArray addObject:@{@"object": obj,
                                                       @"count": @([aggregateContractCountedSet countForObject:obj])}];
                            }];
                        
                        NSArray *sortedDictArray = [dictArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"count" ascending:NO]]];
                        
                        if([sortedDictArray count] >= 10){
                            NSLog(@"Top Communities\n\n");
                            for(int i = 0; i < 10; i++){
                                NSLog(@"#%i: %@ (%i holders)\n\n",i+1, [[sortedDictArray objectAtIndex:i] objectForKey:@"object"], [[[sortedDictArray objectAtIndex:i] objectForKey:@"count"] intValue]);
                            }
                        }
                        
                        [mutContractArray removeAllObjects];
                    }
                }];
            }
        });
    }
}



#pragma mark - validation code
- (BOOL)didValidateContractAddress:(NSString *)address_string
{
    //check to see if we have a valid contract address based on character length (accounting for the possibility they entered the 0x prefix)
    if(address_string.length < 40 || address_string.length > 42){
        return NO;  //address is either too short or too long
    }
    
    NSCharacterSet *hexCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFXabcdefx"] invertedSet];
    BOOL isValid = NO;
    
    if(address_string.length == 42){
        //check for the 0x prefix
        if([address_string hasPrefix:@"0x"] || [address_string hasPrefix:@"0X"]){
            isValid = (NSNotFound == [address_string rangeOfCharacterFromSet:hexCharSet].location);
        }
    }
    else if(address_string.length == 40){
        isValid = (NSNotFound == [address_string rangeOfCharacterFromSet:hexCharSet].location);
    }
    
    return isValid;
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"Ponder"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    NSManagedObjectContext *context = self.persistentContainer.viewContext;

    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if (context.hasChanges && ![context save:&error]) {
        // Customize this code block to include application-specific recovery steps.              
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return self.persistentContainer.viewContext.undoManager;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    NSManagedObjectContext *context = self.persistentContainer.viewContext;

    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!context.hasChanges) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![context save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
