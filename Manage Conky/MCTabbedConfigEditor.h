//
//  MCTabbedConfigEditor.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 13/06/2019.
//  Copyright © 2019 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCTabbedConfigEditor : NSViewController
{
    NSArray *_configs;
}

- (instancetype)initWithConfigs:(NSArray *)configs;

@property (weak) IBOutlet NSTabView *tabView;

@end
