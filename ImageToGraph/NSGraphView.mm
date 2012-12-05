//
//  NSGraphView.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "NSGraphView.h"

@implementation NSGraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawPointsWithX: (VectorXd) xC andY: (VectorXd) yC {
    xCoords = xC;
    yCoords = yC;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    int topY = self.frame.size.height;
    for (int i = 0; i < xCoords.size(); i++) {
        [NSBezierPath fillRect:NSMakeRect(xCoords(i)*6+10, topY - (yCoords(i)*6+10), 2, 2)];
    }
}

@end
