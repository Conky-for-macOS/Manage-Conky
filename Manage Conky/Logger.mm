//
//  Logger.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 17/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Logger.h"

#import "ANSIEscapeHelper/AMR_ANSIEscapeHelper.h"
#import "Shared.h"

#include <list>
using namespace std;

@implementation LoggerEntity
@end

@implementation Logger

static list<LoggerEntity *> _loggerEntities;
static BOOL _isOpen = NO;   // a public _isOpen property
static int _id = 0;
static AMR_ANSIEscapeHelper *ansiEscapeHelper = nil;

//---------------------------------------------------------------------------------
//                            PRIVATE METHODS
//---------------------------------------------------------------------------------

- (void)loadAsWindow
{
    [super loadAsWindow];
    
    /*
     * This should keep focus to mainWindow, thus
     * speeding up development.
     */
    [[NSApp mainWindow] makeKeyAndOrderFront:nil];
}

- (id)initWithWidgetName:(NSString *)widgetName andUniqueID:(NSUInteger)uniqueID
{
    self = [super initWithWindowNibName:@"Logger"];
    if (self)
    {
        [self setWidgetUniqueID:uniqueID];
        [self setWidgetName:widgetName];
        [self loadAsWindow];
    }
    return self;
}

//---------------------------------------------------------------------------------
//                            PUBLIC METHODS
//---------------------------------------------------------------------------------

+ (id)logger
{
    static id res = nil;
    if (!res)
    {
        res = [[self alloc] init];
        ansiEscapeHelper = [[AMR_ANSIEscapeHelper alloc] init];
        
        // set colors & font to use to ansiEscapeHelper
        NSDictionary *colorPrefDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:AMR_SGRCodeFgBlack], kANSIColorPrefKey_FgBlack,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgWhite], kANSIColorPrefKey_FgWhite,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgRed], kANSIColorPrefKey_FgRed,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgGreen], kANSIColorPrefKey_FgGreen,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgYellow], kANSIColorPrefKey_FgYellow,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgBlue], kANSIColorPrefKey_FgBlue,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgMagenta], kANSIColorPrefKey_FgMagenta,
                                           [NSNumber numberWithInt:AMR_SGRCodeFgCyan], kANSIColorPrefKey_FgCyan,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgBlack], kANSIColorPrefKey_BgBlack,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgWhite], kANSIColorPrefKey_BgWhite,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgRed], kANSIColorPrefKey_BgRed,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgGreen], kANSIColorPrefKey_BgGreen,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgYellow], kANSIColorPrefKey_BgYellow,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgBlue], kANSIColorPrefKey_BgBlue,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgMagenta], kANSIColorPrefKey_BgMagenta,
                                           [NSNumber numberWithInt:AMR_SGRCodeBgCyan], kANSIColorPrefKey_BgCyan,
                                           nil];
        
        NSUInteger iColorPrefDefaultsKey;
        NSData *colorData;
        NSString *thisPrefName;
        for (iColorPrefDefaultsKey = 0; iColorPrefDefaultsKey < [[colorPrefDefaults allKeys] count]; iColorPrefDefaultsKey++)
        {
            thisPrefName = [[colorPrefDefaults allKeys] objectAtIndex:iColorPrefDefaultsKey];
            colorData = [[NSUserDefaults standardUserDefaults] dataForKey:thisPrefName];
            if (colorData != nil)
            {
                NSColor *thisColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
                [[ansiEscapeHelper ansiColors] setObject:thisColor forKey:[colorPrefDefaults objectForKey:thisPrefName]];
            }
        }
    }
    return res;
}

+ (id)loggerForWidget:(NSString *)widgetName andUniqueID:(NSUInteger)uniqueID
{
    return [[super alloc] initWithWidgetName:widgetName andUniqueID:uniqueID];
}

- (void)windowDidLoad
{
    [[super window] setTitle:[[super window].title stringByAppendingFormat:@" window %i (%@)", ++_id, _widgetName]];
    [_textView setFont:[NSFont fontWithName:@"Monaco" size:12.0]];
    [_textView setBackgroundColor:[NSColor whiteColor]];
    
    /* create logger_entity */
    LoggerEntity *le = [[LoggerEntity alloc] init];
    le.widgetName = self.widgetName;
    le.textView = self.textView;
    le.uniqueID = self.widgetUniqueID;
    
    _loggerEntities.push_back(le);

    _isOpen = YES;
}

- (void)showString:(NSString*)string toView:(NSTextView *)_textView
{
    [_textView setBaseWritingDirection:NSWritingDirectionLeftToRight];
    
    [ansiEscapeHelper setFont:[_textView font]];
    
    if (string == nil)
        return;
    
    // get attributed string and display it
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedString];
    [attrStr appendAttributedString:[ansiEscapeHelper attributedStringWithANSIEscapedString:string]];
    
    [[_textView textStorage] setAttributedString:attrStr];
}

- (void)addFilehandleForReading:(NSFileHandle *)fh forWidgetWithUniqueID:(NSUInteger)uniqueID
{
    /*
     * Setup Readibility Handler
     */
    [fh setReadabilityHandler:^(NSFileHandle *fileHandle) {
        NSData *data = [fileHandle availableData];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        for (LoggerEntity *le : _loggerEntities)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (le.uniqueID == uniqueID)
                    [self showString:str toView:le.textView];
            });
        }
    }];
    
    [fh acceptConnectionInBackgroundAndNotify];
}

- (BOOL)isOpen { return _isOpen; }

@end
