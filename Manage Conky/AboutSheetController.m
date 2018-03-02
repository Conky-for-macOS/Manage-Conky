//
//  AboutSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AboutSheetController.h"

@implementation AboutSheetController

- (IBAction)openGitHubRepo:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/npyl/Manage-Conky"]];
}

- (IBAction)openConkyManagersGitHubRepo:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/teejee2008/conky-manager"]];
}

- (IBAction)activateAboutSheet:(id)sender
{
    [super activateSheet:@"About"];
}

@end
