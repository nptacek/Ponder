//
//  AppDelegate.h
//  Ponder
//
//  Created by nptacek.eth on 6/9/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

@property (assign) IBOutlet NSTextField *addContractPanelAddressField;
@property (assign) IBOutlet NSTextField *contractStatsOutputField;

@property (assign) IBOutlet NSTextField *contractAddressOutputField;
@property (assign) IBOutlet NSTextField *contractNameOutputField;
@property (assign) IBOutlet NSTextField *contractSymbolOutputField;
@property (assign) IBOutlet NSTextField *contractTotalSupplyOutputField;
@property (assign) IBOutlet NSTextField *contractOwnerCountOutputField;



@end

