//
//  ConkyThemesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"

@interface ConkyThemesSheetController : GeneralSheetController

@property (weak) IBOutlet NSBrowser *themesBrowser;

- (IBAction)activateThemesSheet:(id)sender;

@end
