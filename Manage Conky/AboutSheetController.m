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

- (IBAction)donateBitcoin:(id)sender
{
    const NSString *kMyBCHKey = @"i haven't set it up yet!";
    
    static NSPopover *previewPopover = nil;

    NSTextField *field = [NSTextField textFieldWithString:[NSString stringWithFormat:@"Thank you for supporting! My BCH key is: \n\n%@", kMyBCHKey]];
    NSViewController *controller = [[NSViewController alloc] init];
    [controller setView:field];
    
    if (!previewPopover)
    {
        previewPopover = [[NSPopover alloc] init];
        [previewPopover setBehavior:NSPopoverBehaviorSemitransient];
        [previewPopover setAnimates:YES];
    }
    
    /*
     * close any previously created popover
     */
    [previewPopover setAnimates:NO];  /* close without animation */
    [previewPopover close];
    [previewPopover setAnimates:YES]; /* show with animation */
    
    /*
     * setup a new popover preview
     */
    [previewPopover setContentViewController:controller];
    [previewPopover setContentSize:field.frame.size];
    
    /*
     * show the preview
     */
    [previewPopover showRelativeToRect:[sender bounds]
                                ofView:sender
                         preferredEdge:NSMaxYEdge];
}

- (IBAction)openCredits:(id)sender
{

}

- (IBAction)activateAboutSheet:(id)sender
{
    [super activateSheet:@"About"];
}

@end
