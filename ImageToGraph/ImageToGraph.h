//
//  SizeToGraph.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Eigen/Sparse>

using namespace Eigen;
typedef enum {EASY, ACCORDINGTOPIXEL, RANDOM} weight_t;

@interface ImageToGraph : NSObject {
    //NSData *imData;
    NSBitmapImageRep *rawImg;
    NSImage *image;
    weight_t func;    
}

-(id) initWithImage: (NSImage *) im usingWeightFunction: (weight_t) f;
-(SparseMatrix<float>) getAdjWithWidth: (int) width andHeight: (int) height;
-(SparseMatrix<float>) getAdj;

@end
