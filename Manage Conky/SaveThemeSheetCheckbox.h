//
//  SaveThemeSheetCheckbox.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 20/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#ifndef SaveThemeSheetCheckbox_h
#define SaveThemeSheetCheckbox_h

/*
 * Our checkbox class that maintains a self-registry of checkboxes!
 * These checkboxes are used in the TableView
 */
@interface Checkbox : NSObject
@property BOOL state;           /* ON/OFF */
@property NSString *widgetID;   /* Widget Identifier -- the widget's path */
@end

@interface CheckboxEventListener : NSButtonCell
@end

#endif /* SaveThemeSheetCheckbox_h */
