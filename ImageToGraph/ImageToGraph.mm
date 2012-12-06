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

-(id) initWithImage:(NSImage *)im usingWeightFunction:(weight_t)f {
    //consider having a block for the weight function here
    if ((self = [super init]) && im.size.width > 0 && im.size.height > 0) {
        image = im;
        func = f;        
        rawImg = [NSBitmapImageRep imageRepWithData:[im TIFFRepresentation]];       
    } else {
        NSLog(@"Something has gone horribly wrong.");
        return NULL;
    }
    return self;
}

#pragma mark Internal Functions

-(double) getWeightBetween: (NSPoint) p1 andPixel: (NSPoint) p2 withFloor: (double) f {
    if (func == EASY) {
        return 1.0;
    } else {
    assert(f > 0);
    NSColor *col1 = [rawImg colorAtX:p1.x y:p1.y];
    NSColor *col2 = [rawImg colorAtX:p2.x y:p2.y];
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    
    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    return (r1 + r2 + g1 + g2 + b1 + b2) / 6 + f;
    }
    //quick workaround for if colours are black
}

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
            if (func == EASY) {
                if (y < height - 1) {
                    [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+width andValue:1];
                }
                if(x < width - 1) {
                    [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+1 andValue:1];
                }
                atNode++;
            } else {
                if (y < height - 1) {
                    double weight = [self getWeightBetween:NSMakePoint(x, y) andPixel:NSMakePoint(x, y+1) withFloor:1.0/255];
                    [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+width andValue:weight];
                }
                if(x < width - 1) {
                    double weight = [self getWeightBetween:NSMakePoint(x, y) andPixel:NSMakePoint(x+1, y) withFloor:1.0/255];
                    [self insertIntoTriplet:tempTrip WithRow:atNode col:atNode+1 andValue:weight];
                }
                atNode++;
            }
        }
    }
    adjacencyMatrix = cholmod_triplet_to_sparse(tempTrip, tempTrip->nzmax, &c);
    cholmod_free_triplet(&tempTrip, &c);
    cholmod_finish(&c);
    return adjacencyMatrix;
}

@end
