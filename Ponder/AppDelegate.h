//
//  AppDelegate.h
//  Ponder
//
//  Created by Mistress Gallium on 6/9/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;


@end

