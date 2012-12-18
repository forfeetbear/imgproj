//
//  MyOpenGLView.h
//  OpenGLTesting
//
//  Created by Matthew Bennett on 12/13/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CHOLMOD/Include/cholmod.h>

@interface ImageLayoutOpenGLView : NSOpenGLView {
    NSData *image;
    int height;
    int width;
    cholmod_dense *xcords;
    cholmod_dense *ycords;
}

- (void) drawImageFromData: (NSData *)im withSize:(NSSize) size xCoords: (cholmod_dense *) x yCoords: (cholmod_dense *) y;
- (void) drawRect:(NSRect) bounds;

@end
