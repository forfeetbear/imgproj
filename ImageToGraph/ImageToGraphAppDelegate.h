//
//  ImageToGraphAppDelegate.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/29/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSGraphView.h"
#import "NSImage+OpenCV.h"
#import "ImageLayoutOpenGLView.h"

typedef double (^weightFunction)(NSPoint, NSSize, double, const void *);

@interface ImageToGraphAppDelegate : NSObject <NSApplicationDelegate> {
    int currentMax;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *_image;
@property (weak) IBOutlet NSGraphView *_gView;
@property (unsafe_unretained) IBOutlet NSWindow *gWindow;
@property (unsafe_unretained) IBOutlet NSWindow *glWindow;
@property (weak) IBOutlet ImageLayoutOpenGLView *oglView;

@property NSString *fileName;

- (IBAction)pressDebugButton:(id)sender;
- (IBAction)pressOtherDebugButton:(id)sender;

@end
