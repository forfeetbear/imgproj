//
//  SizeToGraph.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "ImageToGraph.h"

@implementation ImageToGraph

-(id) initWithImage:(NSImage *)im usingWeightFunction:(weight_t)f {
    if ((self = [super init]) && im.size.width > 0 && im.size.height > 0) {
        image = [im copy];
        func = f;        
        rawImg = [NSBitmapImageRep imageRepWithData:[im TIFFRepresentation]];       
    } else {
        NSLog(@"Something has gone horribly wrong.");
        return NULL;
    }
    return self;
}

-(SparseMatrix<float>) getAdj {
    return [self getAdjWithWidth:image.size.width andHeight:image.size.width];
}

-(SparseMatrix<float>) getAdjWithWidth:(int)width andHeight:(int)height {
    int x, y, nodes = width * height;
    
    //Start creating
    SparseMatrix<double> imRep(nodes, nodes);
    imRep.reserve(VectorXi::Constant(nodes, 4));
    int atNode = 0;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            if (func == EASY) {
                if (y < height - 1) {
                    imRep.insert(atNode, atNode+width) = 1;
                    imRep.insert(atNode+width, atNode) = 1;
                }
                if(x < width - 1) {
                    imRep.insert(atNode, atNode+1) = 1;
                    imRep.insert(atNode+1, atNode) = 1;
                }
                atNode++;
            } else {
                if (y < height - 1) {
                    float weight = [self getWeightAtBetween:NSMakePoint(x, y) andPixel:NSMakePoint(x, y+1)];
                    imRep.insert(atNode, atNode+width) = weight;
                    imRep.insert(atNode+width, atNode) = weight;
                }
                if(x < width - 1) {
                    float weight = [self getWeightAtBetween:NSMakePoint(x, y) andPixel:NSMakePoint(x+1, y)];
                    imRep.insert(atNode, atNode+1) = weight;
                    imRep.insert(atNode+1, atNode) = weight;
                }
                atNode++;
            }
        }
    }
    
    imRep.makeCompressed();
    return imRep;
}

-(float) getWeightAtBetween: (NSPoint) p1 andPixel: (NSPoint) p2 {
    NSColor *col1 = [rawImg colorAtX:p1.x y:p1.y];
    NSColor *col2 = [rawImg colorAtX:p2.x y:p2.y];    
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    
    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    return (r1 + r2 + g1 + g2 + b1 + b2) / 6 + 1.0/255;
    //quick workaround for if colours are black
}

@end
