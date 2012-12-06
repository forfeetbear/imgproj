//
//  NSGraphView.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CHOLMOD/Include/cholmod.h>

@interface NSGraphView : NSView {
    cholmod_dense *xCoordsCHOL;
    cholmod_dense *yCoordsCHOL;
}

- (void)drawPointsWithX: (cholmod_dense *) xC andY: (cholmod_dense *) yC;

@end
