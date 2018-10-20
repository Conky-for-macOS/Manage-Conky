//
//  AboutSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AboutSheetController.h"
#include "Shared.h"

@implementation AboutSheetController

- (IBAction)openGitHubRepo:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/npyl/Manage-Conky"]];
}

- (IBAction)openConkyManagersGitHubRepo:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/teejee2008/conky-manager"]];
}

- (IBAction)openGithubIssues:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Conky-for-macOS/Manage-Conky/issues"]];
}

- (NSString *)getCryptocoinKeys
{
    return [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://npyl.github.io/Projects/donate.html"]
                                    encoding:NSUTF8StringEncoding
                                       error:nil];
}

- (IBAction)donatePayPal:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=NSV636CUWX754"]];
}

- (IBAction)donateBitcoin:(id)sender
{
    NSString *keys = [self getCryptocoinKeys];
    NSString *str = keys ? [NSString stringWithFormat:@"Thank you for supporting! \n\n%@", keys] :  @"I am really really sorry! \nSomething went wrong! \nPlease open an issue to ManageConky's Github Repo if the problem persists! \nThank you very much!";
    static NSPopover *donatePopover = nil;

    NSTextField *field = [NSTextField textFieldWithString:str];
    [field setAlignment:NSTextAlignmentCenter];
    [field setEditable:NO];
    NSViewController *controller = [[NSViewController alloc] init];
    [controller setView:field];
    
    if (!donatePopover)
    {
        donatePopover = [[NSPopover alloc] init];
        [donatePopover setBehavior:NSPopoverBehaviorSemitransient];
        [donatePopover setAnimates:YES];
    }
    
    /*
     * close any previously created popover
     */
    [donatePopover setAnimates:NO];  /* close without animation */
    [donatePopover close];
    [donatePopover setAnimates:YES]; /* show with animation */
    
    /*
     * setup a new popover preview
     */
    [donatePopover setContentViewController:controller];
    [donatePopover setContentSize:field.frame.size];
    
    /*
     * show the preview
     */
    [donatePopover showRelativeToRect:[sender bounds]
                               ofView:sender
                        preferredEdge:NSMaxYEdge];
}

- (IBAction)openCredits:(id)sender
{
    [NSApp orderFrontStandardAboutPanel:nil];
}

@end
