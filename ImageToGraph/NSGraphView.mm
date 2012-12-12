//
//  NSGraphView.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "NSGraphView.h"
#import "NSImage+OpenCV.h"

@implementation NSGraphView

#pragma mark Initialisation

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        xCoordsCHOL = NULL;
        yCoordsCHOL = NULL;
    }
    
    return self;
}

#pragma mark Interface Functions

- (void)drawPointsWithX: (cholmod_dense *) xC andY: (cholmod_dense *) yC andPic: (NSImage *) im {
    cholmod_common common;
    cholmod_start(&common);
    if (xCoordsCHOL) {
        cholmod_free_dense(&xCoordsCHOL, &common);
    }
    if (yCoordsCHOL) {
        cholmod_free_dense(&yCoordsCHOL, &common);
    }
    xCoordsCHOL = cholmod_copy_dense(xC, &common);
    yCoordsCHOL = cholmod_copy_dense(yC, &common);
    image = [NSBitmapImageRep imageRepWithData:[im TIFFRepresentation]];
    self.needsDisplay = YES;
}

#pragma mark Drawing Functions

- (void)drawRect:(NSRect)dirtyRect
{
    int topY = self.frame.size.height;
    double offset = 10; //Get the graph away from the corner;
    double scale = 2; //How much to stretch the graph
    double size = 1; //How big each point is;
    for (int i = 0; i < xCoordsCHOL->nzmax; i++) {
        double xC = ((double *)xCoordsCHOL->x)[i] * scale + offset;
        double yC = topY - (((double *)yCoordsCHOL->x)[i] * scale + offset);
        [NSBezierPath fillRect:NSMakeRect(xC, yC, size, size)];
    }
}

-(void) dealloc {
    cholmod_common common;
    cholmod_start(&common);
    if (xCoordsCHOL) {
        cholmod_free_dense(&xCoordsCHOL, &common);
    }
    if (yCoordsCHOL) {
        cholmod_free_dense(&yCoordsCHOL, &common);
    }
    cholmod_finish(&common);
}

@end
