//
//  SizeToGraph.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CHOLMOD/Include/cholmod.h>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/core/core.hpp>
#import "CHOLMODUtil.h"

typedef enum {EASY, ACCORDINGTOPIXEL, RANDOM} weight_t;
typedef double (^weightFunction)(NSPoint, NSPoint, double, const void *);

@interface ImageToGraph : NSObject {
    NSImage *image;
    weightFunction getWeightBetween;
    NSData *imData;
}

-(id) initWithImage: (NSImage *) im usingWeightFunction: (weightFunction)getWeight;
-(cholmod_sparse *) getAdj;

@end
