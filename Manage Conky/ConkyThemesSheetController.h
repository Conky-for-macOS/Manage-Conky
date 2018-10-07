//
//  ConkyThemesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"
#import "LzmaSDKObjCReader.h"

@interface ConkyThemesSheetController : GeneralSheetController<LzmaSDKObjCReaderDelegate>
{
    /**
     The theme-pack items
     */
    NSMutableArray * items;
}

/**
 * Exists in this class to us with a handle to the table
 *  shown in main-window.
 */
@property (weak) IBOutlet NSTableView *themesOrWidgetsTable;

@end
