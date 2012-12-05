//
//  NSGraphView.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Eigen/Dense>
#import <Cocoa/Cocoa.h>

using namespace Eigen;

@interface NSGraphView : NSView {
    VectorXd xCoords;
    VectorXd yCoords;
}

- (void)drawPointsWithX: (VectorXd) xC andY: (VectorXd) yC;

@end
