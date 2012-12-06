//
//  SizeToGraph.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Eigen/Sparse>
#import <CHOLMOD/Include/cholmod.h>

using namespace Eigen;
typedef enum {EASY, ACCORDINGTOPIXEL, RANDOM} weight_t;

@interface ImageToGraph : NSObject {
    NSBitmapImageRep *rawImg;
    NSImage *image;
    weight_t func;    
}

-(id) initWithImage: (NSImage *) im usingWeightFunction: (weight_t) f;
-(cholmod_sparse *) getAdj;
-(double) getWeightBetween: (NSPoint) p1 andPixel: (NSPoint) p2 withFloor: (double) f;

@end
