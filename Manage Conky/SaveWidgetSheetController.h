//
//  SaveWidgetSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Fragaria/Fragaria.h>
#import "GeneralSheetController.h"

@interface SaveWidgetSheetController : GeneralSheetController0
{
    NSURL                       *previewLocation;
    NSMutableArray<NSURL *>     *resourcesLocations;
}

@property (strong) IBOutlet MGSFragariaView *scriptView;

@property (weak) IBOutlet NSTextField *widgetSourceField;
@property (weak) IBOutlet NSTextField *widgetCreatorField;

@end
