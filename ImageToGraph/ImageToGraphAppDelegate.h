//
//  ImageToGraphAppDelegate.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/29/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/core/core.hpp>
#import "NSGraphView.h"
#import "NSImage+OpenCV.h"
#import "LayoutToImage.h"

typedef double (^weightFunction)(NSPoint, NSPoint, double, const void *);

@interface ImageToGraphAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *_image;
@property (weak) IBOutlet NSGraphView *_gView;
@property NSString *fileName;
@property (unsafe_unretained) IBOutlet NSWindow *gWindow;

- (IBAction)pressDebugButton:(id)sender;
- (IBAction)pressOtherDebugButton:(id)sender;

@end
