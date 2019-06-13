//
//  MCTabbedConfigEditor.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 13/06/2019.
//  Copyright © 2019 Nickolas Pylarinos. All rights reserved.
//

#import "MCTabbedConfigEditor.h"

#import "MCConfigEditor.h"

@implementation MCTabbedConfigEditor

- (instancetype)initWithConfigs:(NSArray *)configs
{
    self = [super init];
    
    if (self)
    {
        _configs = [NSArray arrayWithArray:configs];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    /*
     * Create an MCConfigEditor for-each config
     */
    for (NSString *config in _configs)
    {
        NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:[[MCConfigEditor alloc] initWithConfig:config]];
        [item setLabel:config.lastPathComponent];
        [_tabView addTabViewItem:item];
    }
}

@end
