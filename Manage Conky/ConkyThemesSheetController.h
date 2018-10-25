//
//  ConkyThemesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "LzmaSDKObjCReader.h"
#import "GeneralSheetController.h"

@interface ConkyThemesSheetController : GeneralSheetController<LzmaSDKObjCReaderDelegate>
{
    /**
     The theme-pack items
     */
    NSMutableArray * items;
}

@end
