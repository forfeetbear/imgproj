//
//  SizeToGraph.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "ImageToGraph.h"

#define UPPER_SYMMETRICAL 1

@implementation ImageToGraph

#pragma mark Constructor(s)

-(id) initWithImage:(NSImage *)im usingWeightFunction:(double (^)(NSPoint, NSPoint, double, NSBitmapImageRep *))getWeight {
    //consider having a block for the weight function here
    if ((self = [super init]) && im.size.width > 0 && im.size.height > 0) {        
        image = im;
        getWeightBetween = getWeight;
        rawImg = [NSBitmapImageRep imageRepWithData:[im TIFFRepresentation]];
    } else {
        NSLog(@"Something has gone horribly wrong.");
        return NULL;
    }
    return self;
}

#pragma mark Internal Functions

#pragma mark CHOLMOD Utility Functions

-(void) insertIntoTriplet: (cholmod_triplet *) t WithRow: (int) r col: (int) c andValue: (double) x {
    size_t index = t->nnz++;
    ((int *)t->i)[index] = r;
    ((int *)t->j)[index] = c;
    ((double *)t->x)[index] = x;
}

#pragma mark Interface Functions


/* adjacencyMatrix is still in memory after this method remember to free once used */
-(cholmod_sparse *) getAdj {
    //Some required values
    int height = image.size.height;
    int width = image.size.width;
    int x, y, nodes = height * width;
    //Cholmod stuff
    cholmod_common c;
    cholmod_start(&c);
    c.print = 5;
    cholmod_triplet *tempTrip = cholmod_allocate_triplet(nodes, nodes, nodes*4, UPPER_SYMMETRICAL, CHOLMOD_REAL, &c);
    cholmod_sparse *adjacencyMatrix;
    //Start creating
    int atNode = 0;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            if (y < height - 1) {
                double weight = getWeightBetween(NSMakePoint(x, y), NSMakePoint(x, y+1), 0.1, rawImg);
                [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+width andValue:weight];
            }
            if(x < width - 1) {                
                double weight = getWeightBetween(NSMakePoint(x, y), NSMakePoint(x, y+1), 0.1, rawImg);
                [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+1 andValue:weight];
            }
            atNode++;
        }
    }
    adjacencyMatrix = cholmod_triplet_to_sparse(tempTrip, tempTrip->nzmax, &c);
    cholmod_free_triplet(&tempTrip, &c);
    cholmod_finish(&c);
    return adjacencyMatrix;
}

@end
