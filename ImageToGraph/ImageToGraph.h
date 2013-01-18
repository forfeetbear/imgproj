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
typedef double (^weightFunction)(NSPoint, NSSize, double, const void *);

@interface ImageToGraph : NSObject {
    NSImage *image;
    NSData *imData;
    int averageR;
    int averageG;
    int averageB;
    weightFunction wf;
}

-(id) initWithImage: (NSImage *) im useWeightFunction: (weightFunction) f;
-(cholmod_sparse *) getAdj;

@end
