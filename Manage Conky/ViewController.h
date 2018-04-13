//
//  ViewController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <unistd.h>

typedef enum {
    widgetsThemesTableShowWidgets,
    widgetsThemesTableShowThemes,
} MCWidgetThemesTableShow;

/**
 * MCTheme
 *
 * A core-representation of a ManageConky Theme.
 * Used for reducing memory footprint of an MCThemeOrWidget object,
 *  when playing the role of a widget, by making themeRepresentation nil.
 *
 * Used also for representing legacy conky-manager themes as there is
 *  full backwards compatibility.
 */
@interface MCTheme : NSObject

@property NSInteger startupDelay;   /* startup delay */
@property NSString *conkyConfig;    /* conky config to be executed */
@property NSArray *arguments;   /* arguments for conky */
@property NSString *wallpaper;  /* wallpaper used by theme */

@property NSString *creator;    /* creator of theme */
@property NSString *source;     /* source of theme */

@property pid_t pid;    // XXX not sure if gonna be used

+ (instancetype)themeWithConkyConfig:(NSString *)path
                           arguments:(NSArray *)args
                        startupDelay:(NSInteger)startupDelay
                           wallpaper:(NSString *)wallpaperPath
                             creator:(NSString *)creator
                           andSource:(NSString *)source;

@end

/**
 * MCWidget
 *
 * A ManageConky Widget representation.  Pretty simple, I know.
 */
@interface MCWidget : NSObject

@property pid_t pid;
@property NSString *itemPath;

+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path;
@end

@interface ViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>
{
    NSPopover *widgetPreviewPopover;
    
    NSMutableArray<MCTheme*> *themesArray;
    NSMutableArray<MCWidget*> *widgetsArray;
    MCWidgetThemesTableShow whatToShow;
}

@property (weak) IBOutlet NSImageView *themeOrWidgetPreviewImage;
@property (weak) IBOutlet NSTableView *widgetsThemesTable;

/**
 * Function used to fill widgetsArray and themesArray
 * Also used by ThemesSheet by getting the pointer to the ViewController instance
 *  to fill the table after loading a themepack.
 */
- (void)fillWidgetsThemesArrays;
- (void)emptyWidgetsThemesArrays;

@end
