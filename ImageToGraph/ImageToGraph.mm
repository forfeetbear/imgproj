//
//  SizeToGraph.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "ImageToGraph.h"
#import "NSImage+OpenCV.h"

#define UPPER_SYMMETRICAL 1

@implementation ImageToGraph

#pragma mark Constructor(s)

-(id) initWithImage:(NSImage *)im useWeightFunction:(weightFunction)f{
    //consider having a block for the weight function here
    if ((self = [super init]) && im.size.width > 0 && im.size.height > 0) {
        int index;
        image = im;
        wf = f;
        
        //New code for raw image buffer
        imData = [im data];
        unsigned char *pixels = (unsigned char *)[imData bytes];
        
        //Calculate average r, g and b values accross the whole picture
        for (int i = 0; i<im.size.height*im.size.width; i++) {
            index = i*4;
            averageR += pixels[index];
            averageG += pixels[index+1];
            averageB += pixels[index+2];
        }
        
        averageR /= im.size.height*im.size.width;
        averageG /= im.size.height*im.size.width;
        averageB /= im.size.height*im.size.width;
        
//        NSLog(@"Average colour is (%f, %f, %f)", r, g, b);
    } else {
        NSLog(@"Something has gone horribly wrong.");
        return NULL;
    }
    return self;
}

#pragma mark Temporary Weight Function

static double getColorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    int dr = r2 - r1;
    int dg = g2 - g1;
    int db = b2 - b1;
    return sqrt(dr*dr + dg*dg + db*db);
}

-(double) getWeightForPixel: (NSPoint) pix withSize: (NSSize) imgSize andFloor: (double) floor andImage: (const void *) img {
//------------SIMPLE (working)------------------//
    return 1;
//----------------------------------------------//
    
//------------COLOURBYDIFFERENCE----------------//
//    int index = 4*(pix.x + imgSize.width * pix.y);
//    int r, g, b;
//    r = ((unsigned char *)img)[index];
//    g = ((unsigned char *)img)[index+1];
//    b = ((unsigned char *)img)[index+2];
//    
//    return getColorDistance(r, g, b, averageR, averageG, averageB) + floor;
//----------------------------------------------//
    
//------------COLOURBYDIFFERENCE----------------//
//    int index = 4*(pix.x + imgSize.width * pix.y);
//    int r, g, b;
//    r = ((unsigned char *)img)[index];
//    g = ((unsigned char *)img)[index+1];
//    b = ((unsigned char *)img)[index+2];
//    
//    return 442 - (getColorDistance(r, g, b, averageR, averageG, averageB));
//----------------------------------------------//

    
//------------EXPAND BLACK (working)------------//
//---------------------------------------------//
    
//------------EXPAND GREEN/WHITE (sort of working)-------//
//    int index = 4*(pix.x + imgSize.width * pix.y);
//    int r, g, b;
//    
//    r = ((unsigned char *)img)[index];
//    g = ((unsigned char *)img)[index+1];
//    b = ((unsigned char *)img)[index+2];
//    return 255 - (g) + floor;
//---------------------------------------------//

    
//-----------CIRCLE (working) -----------------//
//    NSPoint c = NSMakePoint(image.size.width/2, image.size.height/2);
//    float rad = image.size.width/8;
//    
//    double dist = sqrt((pix.x-c.x)*(pix.x-c.x) + (pix.y-c.y)*(pix.y-c.y));
//    double diff = rad-dist;
//    if (diff > 0) {
//        return rad/diff;
//    } else {
//        return rad;
//    }
//--------------------------------------------//
}

#pragma mark Interface Functions

/* adjacencyMatrix is still in memory after this method remember to free once used */
-(cholmod_sparse *) getAdj {
    //Some required values
    const void *imgData = [imData bytes];
    int height = image.size.height+1;
    int width = image.size.width+1;
    int x, y, nodes = height * width;
    //Cholmod stuff
    cholmod_common c;
    cholmod_start(&c);
    c.print = 5;
    cholmod_triplet *tempTrip = cholmod_allocate_triplet(nodes, nodes, nodes*4, UPPER_SYMMETRICAL, CHOLMOD_REAL, &c);
    cholmod_sparse *adjacencyMatrix;
    
    //Start creating  
    for (y = 0; y < height-1; y++) {
        for(x = 0; x < width-1; x++){
            int botLeft = x + y *width;
            int topRight = botLeft + 1 + width;
            double weightForPixel = wf(NSMakePoint(x, y), image.size, 50, imgData);
            [CHOLMODUtil insertIntoTriplet:tempTrip WithRow:botLeft col:botLeft+1 andValue:weightForPixel];
            [CHOLMODUtil insertIntoTriplet:tempTrip WithRow:botLeft col:botLeft+width andValue:weightForPixel];
            [CHOLMODUtil insertIntoTriplet:tempTrip WithRow:botLeft+1 col:topRight andValue:weightForPixel];
            [CHOLMODUtil insertIntoTriplet:tempTrip WithRow:botLeft+width col:topRight andValue:weightForPixel];
        }
    }
    adjacencyMatrix = cholmod_triplet_to_sparse(tempTrip, tempTrip->nzmax, &c);
    
    cholmod_free_triplet(&tempTrip, &c);
    cholmod_finish(&c);
    return adjacencyMatrix;
}

@end
