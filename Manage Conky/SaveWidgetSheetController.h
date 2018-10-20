//
//  SaveWidgetSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Fragaria/Fragaria.h>
#import "GeneralSheetController.h"

@protocol SaveWidgetSheetControllerDelegate<NSObject>
@optional
- (void)didSaveWidget;
- (void)didNotSaveWidget;
@end

@interface SaveWidgetSheetController : GeneralSheetController
{
    NSURL                       *previewLocation;
    NSMutableArray<NSURL *>     *resourcesLocations;
}

@property (nonatomic, weak) id<SaveWidgetSheetControllerDelegate> delegate;

@property (strong) IBOutlet MGSFragariaView *scriptView;

@property (weak) IBOutlet NSTextField *widgetSourceField;
@property (weak) IBOutlet NSTextField *widgetCreatorField;

@end
