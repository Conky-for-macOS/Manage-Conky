//
//  PreferencesController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    return self;
}

- (IBAction)close:(id)sender
{
    [self.window close];
}

@end
