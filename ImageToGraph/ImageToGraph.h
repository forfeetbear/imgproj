//
//  SizeToGraph.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CHOLMOD/Include/cholmod.h>
#import "CHOLMODUtil.h"

typedef enum {EASY, ACCORDINGTOPIXEL, RANDOM} weight_t;
typedef double (^weightFunction)(NSPoint, NSPoint, double, const void *);

@interface ImageToGraph : NSObject {
    NSImage *image;
    weightFunction getWeightBetween;
    NSData *imData;
    int averageR;
    int averageG;
    int averageB;
}

-(id) initWithImage: (NSImage *) im usingWeightFunction: (weightFunction)getWeight;
-(cholmod_sparse *) getAdj;

@end
