//
//  ImageToGraphAppDelegate.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/29/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSGraphView.h"

@interface ImageToGraphAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *_image;
@property (weak) IBOutlet NSGraphView *_gView;
@property NSString *fileName;
@property (unsafe_unretained) IBOutlet NSWindow *gWindow;

- (IBAction)pressDebugButton:(id)sender;
- (IBAction)pressOtherDebugButton:(id)sender;
- (IBAction)pressedOtherOtherDebugButton:(id)sender;

@end
