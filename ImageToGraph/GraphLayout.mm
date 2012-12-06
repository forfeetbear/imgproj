//
//  GraphLayout.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "GraphLayout.h"
#define UPPER_SYMMETRICAL 1
#define MODE_NUMERICAL 1
#define UNSYMMETRIC 0
#define COORDINATE_UNKNOWN -1
#define NO_TRANSPOSE 0

@implementation GraphLayout

#pragma mark Constructor/Destructors

-(id) initWithGraph: (cholmod_sparse *) graphRep andImageSize: (NSSize) size usingITG:(ImageToGraph *)temp {
    cholmod_common common;
    cholmod_start(&common);
    
    if (self = [super init]) {
        //get basic values
        computed = NO;
        imageDimensions = NSMakeSize(size.width, size.height);
        numUnknownX = imageDimensions.width * imageDimensions.height;
        numUnknownY = numUnknownX;
        
        //copy in and allocate space for CHOLMOD structs
        adjCHOL = cholmod_copy(graphRep, UNSYMMETRIC, MODE_NUMERICAL, &common);
        xCoordsCHOL = cholmod_allocate_dense(adjCHOL->nrow, 1, adjCHOL->nrow, CHOLMOD_REAL, &common);
        yCoordsCHOL = cholmod_allocate_dense(adjCHOL->nrow, 1, adjCHOL->nrow, CHOLMOD_REAL, &common);
        
        //setting uninitialised variables to null
        lapCHOL = NULL;
        LxCHOL = NULL;
        LyCHOL = NULL;
        
        //set the coords to junk values (-1)
        for(int i = 0; i < numUnknownX; i++) {
            ((double *)xCoordsCHOL->x)[i] = COORDINATE_UNKNOWN;
            ((double *)yCoordsCHOL->x)[i] = COORDINATE_UNKNOWN;
        }
        
        /* this part is temporary (probably) until I can figure out some better way of getting the weights into Cx and Cy */
        tempITG = temp;
    }
    
    cholmod_finish(&common);
    return self;
}

-(void) dealloc {
    cholmod_common common;
    cholmod_start(&common);
    cholmod_free_dense(&xCoordsCHOL, &common);
    cholmod_free_dense(&yCoordsCHOL, &common);
    cholmod_free_sparse(&adjCHOL, &common);
    //next few may not be initialised so we have to check
    if (lapCHOL) {
        cholmod_free_sparse(&lapCHOL, &common);
    }
    if (LxCHOL) {
        cholmod_free_sparse(&LxCHOL, &common);
    }
    if (LyCHOL) {
        cholmod_free_sparse(&LyCHOL, &common);
    }
    cholmod_finish(&common);
}

#pragma mark CHOLMOD Utility Functions

-(void) insertIntoTriplet: (cholmod_triplet *) t WithRow: (int) r col: (int) c andValue: (double) x {
    size_t index = t->nnz++;
    ((int *)t->i)[index] = r;
    ((int *)t->j)[index] = c;
    ((double *)t->x)[index] = x;
}

#pragma mark Internal Functions

-(void) setupDefaultFixedPoints {
    size_t rows = adjCHOL->nrow;
    //Add fixed x points - left and right edges
    for (size_t i = 0; i < rows; i+=imageDimensions.width) {
        int farSide = i + imageDimensions.width - 1;
        ((double *)xCoordsCHOL->x)[i] = 0;
        ((double *)xCoordsCHOL->x)[farSide] = imageDimensions.width-1;
        numUnknownX -= 2;
    }
    //Add fixed y points - bottom and top edges
    for (int i = 0; i < imageDimensions.width; i++) {
        int topRow = (imageDimensions.height - 1) * imageDimensions.width + i;
        ((double *)yCoordsCHOL->x)[i] = 0;
        ((double *)yCoordsCHOL->x)[topRow] = imageDimensions.height - 1;
        numUnknownY -= 2;
    }
    //create the array of unknown indices
    indicesNeededXCHOL = [[NSMutableData alloc] initWithCapacity:numUnknownX * sizeof(int)];
    indicesNeededYCHOL = [[NSMutableData alloc] initWithCapacity:numUnknownY * sizeof(int)];
    int *indX = (int *)[indicesNeededXCHOL mutableBytes];
    int *indY = (int *)[indicesNeededYCHOL mutableBytes];
    
    int count = 0;
    for (int i = 0; i < xCoordsCHOL->nrow; i++) {
        if (((double *)xCoordsCHOL->x)[i] < 0) {
            indX[count++] = i;
        }
    }
    
    count = 0;
    for (int i = 0; i < yCoordsCHOL->nrow; i++) {
        if (((double *)yCoordsCHOL->x)[i] < 0) {
            indY[count++] = i;
        }
    }
}


-(cholmod_sparse *) getLap {
    cholmod_common common;
    cholmod_start(&common);
    double multAlpha[] = {1, 0};
    double multBeta[] = {0, 0};
    double subAlpha[] = {1, 0};
    double subBeta[] = {-1, 0};
    //First find the sum of all the rows in A using A*ones
    cholmod_dense *ones = cholmod_ones(adjCHOL->nrow, 1, CHOLMOD_REAL, &common);
    cholmod_dense *sums = cholmod_allocate_dense(ones->nrow, ones->ncol, ones->nrow, CHOLMOD_REAL, &common);
    cholmod_sdmult(adjCHOL, NO_TRANSPOSE, multAlpha, multBeta, ones, sums, &common);
    
    //now sums has the values of the diagonal of the Laplacian so read them in
    cholmod_triplet *tempTrip = cholmod_allocate_triplet(adjCHOL->nrow, adjCHOL->ncol, 5*adjCHOL->nrow, UNSYMMETRIC, CHOLMOD_REAL, &common);
    for (int i = 0; i < sums->nrow; i++) {
        double val = ((double *)sums->x)[i];
        [self insertIntoTriplet:tempTrip WithRow:i col:i andValue:val];
    }
    
    //convert the constructed diagonal to sparse and then subtract adj from it
    cholmod_sparse *diag = cholmod_triplet_to_sparse(tempTrip, tempTrip->nzmax, &common);
    cholmod_sparse *res = cholmod_add(diag, adjCHOL, subAlpha, subBeta, TRUE, TRUE, &common);
    
    //free leftover stuff
    cholmod_free_dense(&ones, &common);
    cholmod_free_dense(&ones, &common);
    cholmod_free_triplet(&tempTrip, &common);
    cholmod_free_sparse(&diag, &common);
    cholmod_finish(&common);
    return res;
}

-(cholmod_sparse *) getLxTilde {
    cholmod_common common;
    cholmod_start(&common);
    
    int *indX = (int *)[indicesNeededXCHOL mutableBytes];
    cholmod_sparse *result = cholmod_submatrix(lapCHOL, indX, numUnknownX, indX, numUnknownX, TRUE, TRUE, &common);
    
    cholmod_finish(&common);
    return result;
}

-(cholmod_sparse *) getLyTilde {
    cholmod_common common;
    cholmod_start(&common);
    
    int *indY = (int *)[indicesNeededYCHOL mutableBytes];
    cholmod_sparse *result = cholmod_submatrix(lapCHOL, indY, numUnknownY, indY, numUnknownY, TRUE, TRUE, &common);
    
    cholmod_finish(&common);
    return result;
}

-(cholmod_dense *) getCx {
    cholmod_common common;
    cholmod_start(&common);
    
    cholmod_dense *result = cholmod_zeros(LxCHOL->nrow, 1,LxCHOL->xtype, &common);
    int *indX = (int *)[indicesNeededXCHOL mutableBytes];
    for (int i = 0; i < numUnknownX; i++) {
        int pixX, pixY;
        pixX = indX[i] % (int)imageDimensions.width;
        pixY = indX[i] / (int)imageDimensions.width;
        if (pixX == 1) {
            ((double *)result->x)[i] += [tempITG getWeightBetween: NSMakePoint(pixX, pixY) andPixel:NSMakePoint(pixX-1, pixY) withFloor:1.0/255] * ((double *)xCoordsCHOL->x)[indX[i]-1];
        }
        if (pixX == (int)imageDimensions.width - 2) {
            ((double *)result->x)[i] += [tempITG getWeightBetween: NSMakePoint(pixX, pixY) andPixel:NSMakePoint(pixX+1, pixY) withFloor:1.0/255] * ((double *)xCoordsCHOL->x)[indX[i]+1];
        }
    }
    cholmod_finish(&common);
    return result;
}

-(cholmod_dense *) getCy {
    cholmod_common common;
    cholmod_start(&common);
    
    int nodes = imageDimensions.height * imageDimensions.width;
    int *indY = (int *)[indicesNeededYCHOL mutableBytes];
    cholmod_dense *result = cholmod_zeros(LyCHOL->nrow, 1, LyCHOL->xtype, &common);
    for (int i = 0; i < numUnknownY; i++) {        
        int pixX, pixY;
        pixX = indY[i] % (int)imageDimensions.width;
        pixY = indY[i] / (int)imageDimensions.width;
        if (indY[i] < 2 * imageDimensions.width) {
            ((double *)result->x)[i] += [tempITG getWeightBetween:NSMakePoint(pixX, pixY) andPixel:NSMakePoint(pixX, pixY - 1) withFloor:1.0/255] * ((double *)yCoordsCHOL->x)[indY[i] - (int)imageDimensions.width];
        }
        if (indY[i] >= nodes - 2 * imageDimensions.width) {
            ((double *)result->x)[i] += [tempITG getWeightBetween:NSMakePoint(pixX, pixY) andPixel:NSMakePoint(pixX, pixY + 1) withFloor:1.0/255] * ((double *)yCoordsCHOL->x)[indY[i] + (int)imageDimensions.width];
        }
    }
    cholmod_finish(&common);
    return result;
}

-(cholmod_dense *) getSolutionWith: (cholmod_sparse *) Ltilde andRHS: (cholmod_dense *)C {
    cholmod_common common;
    cholmod_start(&common);
    common.print = 5;
    
    cholmod_factor *factor;
    cholmod_dense *result;
    cholmod_sparse *symmetricLtilde;
    symmetricLtilde = cholmod_copy(Ltilde, UPPER_SYMMETRICAL, MODE_NUMERICAL, &common);
    factor = cholmod_analyze(symmetricLtilde, &common);
    cholmod_factorize(symmetricLtilde, factor, &common);
    result = cholmod_solve(CHOLMOD_A, factor, C, &common);
    
    cholmod_free_factor(&factor, &common);
    cholmod_free_sparse(&symmetricLtilde, &common);
    cholmod_finish(&common);
    return result;
}

-(void) fillXWith: (cholmod_dense *) sol {
    int *indX = (int *)[indicesNeededXCHOL mutableBytes];
    for(int i = 0; i < sol->nrow; i++) {
        ((double *)xCoordsCHOL->x)[indX[i]] = ((double *)sol->x)[i];
    }
}

-(void) fillYWith: (cholmod_dense *) sol {
    int *indY = (int *)[indicesNeededYCHOL mutableBytes];
    for(int i = 0; i < sol->nrow; i++) {
        ((double *)yCoordsCHOL->x)[indY[i]] = ((double *)sol->x)[i];
    }
}

#pragma mark Interface Functions

-(void) runLayout {
    cholmod_common common;
    cholmod_start(&common);
    common.print = 5;
    
    NSLog(@"Fixing Points");
    [self setupDefaultFixedPoints];
    NSLog(@"Getting L");    
    lapCHOL = [self getLap];
    NSLog(@"Getting Lx~");
    LxCHOL = [self getLxTilde];
    NSLog(@"Getting Ly~");
    LyCHOL = [self getLyTilde];
    NSLog(@"Creating Cx");
    cholmod_dense *Cx = [self getCx];
    NSLog(@"Creating Cy");
    cholmod_dense *Cy = [self getCy];
    NSLog(@"Solving for x:");
    cholmod_dense *solvedX = [self getSolutionWith:LxCHOL andRHS:Cx];
    NSLog(@"Solving for y:");
    cholmod_dense *solvedY = [self getSolutionWith:LyCHOL andRHS:Cy];
    NSLog(@"Filling x");
    [self fillXWith: solvedX];
    NSLog(@"Filling y");
    [self fillYWith: solvedY];
    
    NSLog(@"Freeing stuff");
    cholmod_free_dense(&Cx, &common);
    cholmod_free_dense(&Cy, &common);
    cholmod_free_dense(&solvedX, &common);
    cholmod_free_dense(&solvedY, &common);
    cholmod_finish(&common);
    NSLog(@"Done");
    computed = YES;
}

#pragma mark Accessors

-(cholmod_dense *) getX{
    if (!computed) {
        [self runLayout];
    }
    
    return xCoordsCHOL;
}

-(cholmod_dense *) getY{
    if (!computed) {
        [self runLayout];
    }
    
    return yCoordsCHOL;
}

@end
