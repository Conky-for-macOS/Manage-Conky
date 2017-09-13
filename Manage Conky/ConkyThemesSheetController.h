//
//  ConkyThemesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"
#import <LzmaSDKObjCReader.h>

@interface ConkyThemesSheetController : GeneralSheetController <LzmaSDKObjCReaderDelegate>

@property (weak) IBOutlet NSBrowser *themesBrowser;

- (IBAction)activateThemesSheet:(id)sender;

@end
