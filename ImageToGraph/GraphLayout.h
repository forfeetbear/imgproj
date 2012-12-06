//
//  GraphLayout.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CHOLMOD/Include/cholmod.h>
#import "ImageToGraph.h"

@interface GraphLayout : NSObject {
    cholmod_sparse *adjCHOL;
    cholmod_sparse *lapCHOL;
    cholmod_sparse *LxCHOL;
    cholmod_sparse *LyCHOL;
    cholmod_dense *xCoordsCHOL;
    cholmod_dense *yCoordsCHOL;
    BOOL computed;
    NSSize imageDimensions;
    int numUnknownX;
    int numUnknownY;
    NSMutableData *indicesNeededXCHOL;
    NSMutableData *indicesNeededYCHOL;
    ImageToGraph *tempITG;
}

-(id) initWithGraph: (cholmod_sparse *)graphRep andImageSize: (NSSize) size usingITG: (ImageToGraph *) temp;
-(cholmod_dense *) getX;
-(cholmod_dense *) getY;

@end
