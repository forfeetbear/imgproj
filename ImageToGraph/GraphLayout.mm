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

-(id) initWithGraph: (cholmod_sparse *) graphRep andImageSize: (NSSize) size usingMaxIterations:(int)maxIt{
    cholmod_common common;
    cholmod_start(&common);
    
    if (self = [super init]) {
        //get basic values
        computed = NO;
        imageDimensions = NSMakeSize(size.width, size.height);
        numUnknownX = (imageDimensions.width+1) * (imageDimensions.height+1);
        numUnknownY = numUnknownX;
        
        //copy in and allocate space for CHOLMOD structs
        adjCHOL = cholmod_copy(graphRep, UNSYMMETRIC, MODE_NUMERICAL, &common);
        xCoordsCHOL = cholmod_allocate_dense(adjCHOL->nrow, 1, adjCHOL->nrow, CHOLMOD_REAL, &common);
        yCoordsCHOL = cholmod_allocate_dense(adjCHOL->nrow, 1, adjCHOL->nrow, CHOLMOD_REAL, &common);
        
        //setting uninitialised variables to null
        lapCHOL = NULL;
        LxCHOL = NULL;
        LyCHOL = NULL;
        solvedX = NULL;
        solvedY = NULL;
        max = maxIt;
        
        //set the coords to junk values (-1)
        for(int i = 0; i < numUnknownX; i++) {
            ((double *)xCoordsCHOL->x)[i] = COORDINATE_UNKNOWN;
            ((double *)yCoordsCHOL->x)[i] = COORDINATE_UNKNOWN;
        }
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
    if (solvedX) {
        cholmod_free_dense(&solvedX, &common);
    }
    if (solvedY) {
        cholmod_free_dense(&solvedY, &common);
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

-(cholmod_dense *) doConjugateGradientWithA: (cholmod_sparse *) A andB: (cholmod_dense *) b withInitialGuess: (cholmod_dense *) x0 andMaxIterations: (int) maxIt andPreconditioner: (cholmod_sparse *) precond {
    cholmod_common common;
    cholmod_dense *z0, *zk, *zk1;
    cholmod_dense *res0, *resk, *resk1;
    cholmod_dense *pdir0, *pdirk, *pdirk1;
    cholmod_dense *xk, *xk1;
    cholmod_dense *tempApk;
    resk1 = NULL;
    zk1 = NULL;
    double alpha, beta;
    double scale[2] = {1, 0};
    double zeroScale[2] = {0, 0};
    double negScale[2] = {-1, 0};
    BOOL didAllocateX0 = NO;
    int k;
    cholmod_start(&common);
    tempApk = cholmod_allocate_dense(A->nrow, 1, A->nrow, CHOLMOD_REAL, &common);
    z0 = cholmod_allocate_dense(A->nrow, 1, A->nrow, CHOLMOD_REAL, &common);
    zk1 = cholmod_allocate_dense(A->nrow, 1, A->nrow, CHOLMOD_REAL, &common);
               
    if(!x0) {
        x0 = cholmod_zeros(A->nrow, 1, CHOLMOD_REAL, &common);
        didAllocateX0 = YES;
    }
    
    //calculate initial residual
    cholmod_sdmult(A, NO_TRANSPOSE, negScale, scale, x0, b, &common);
    res0 = b;
    cholmod_sdmult(precond, NO_TRANSPOSE, scale, zeroScale, res0, z0, &common);
    pdir0 = z0;
    resk = cholmod_copy_dense(res0, &common);
    pdirk = cholmod_copy_dense(pdir0, &common);
    xk = cholmod_copy_dense(x0, &common);
    zk = cholmod_copy_dense(z0, &common);
    k = 0;
    
    //start iterating
    for (int i = 0; i < maxIt; i++) {
        cholmod_sdmult(A, NO_TRANSPOSE, scale, zeroScale, pdirk, tempApk, &common);
        alpha = [CHOLMODUtil cholmodDotProductOfX:zk andY:resk] / [CHOLMODUtil cholmodDotProductOfX:tempApk andY:pdirk];
        xk1 = [CHOLMODUtil cholmodAddDenseA:xk andB:pdirk withScalesA:1.0 andB:alpha];
        resk1 = [CHOLMODUtil cholmodAddDenseA:resk andB:tempApk withScalesA:1.0 andB:-alpha];
        if([CHOLMODUtil cholmodMagnitudeOf:resk1] < 1) {
            NSLog(@"Exited with %d iterations.", i);
            return xk1;
        };
        cholmod_sdmult(precond, NO_TRANSPOSE, scale, zeroScale, resk1, zk1, &common);
        beta = [CHOLMODUtil cholmodDotProductOfX:zk1 andY:resk1] / [CHOLMODUtil cholmodDotProductOfX:zk andY:resk];
        pdirk1 = [CHOLMODUtil cholmodAddDenseA:zk1 andB:pdirk withScalesA:1.0 andB:beta];
        k++;
        
        cholmod_free_dense(&pdirk, &common);
        cholmod_free_dense(&resk, &common);
        cholmod_free_dense(&xk, &common);
        cholmod_free_dense(&zk, &common);
        pdirk = pdirk1;
        xk = xk1;
        resk = resk1;
        zk = cholmod_copy_dense(zk1, &common);
    }
    
    if(didAllocateX0) {
        cholmod_free_dense(&x0, &common);
    }
    NSLog(@"Exited with %d iterations (max). res was %f", maxIt, [CHOLMODUtil cholmodMagnitudeOf:resk1]);
    cholmod_free_dense(&tempApk, &common);
    cholmod_free_dense(&pdirk1, &common);
    if (resk1) {
    cholmod_free_dense(&resk1, &common);
    }
    if (zk1) {
    cholmod_free_dense(&zk1, &common);
    }
    cholmod_finish(&common);
    
    return xk1;
}

-(void) setupDefaultFixedPoints {
    size_t rows = adjCHOL->nrow;
    //Add fixed x points - left and right edges
    for (size_t i = 0; i < rows; i+=imageDimensions.width+1) {
        int farSide = i + imageDimensions.width;
        ((double *)xCoordsCHOL->x)[i] = 0;
        ((double *)xCoordsCHOL->x)[farSide] = imageDimensions.width;
        numUnknownX -= 2;
    }
    //Add fixed y points - bottom and top edges
    for (int i = 0; i < imageDimensions.width+1; i++) {
        int topRow = (imageDimensions.height) * (imageDimensions.width+1) + i;
        ((double *)yCoordsCHOL->x)[i] = 0;
        ((double *)yCoordsCHOL->x)[topRow] = imageDimensions.height;
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
    common.print = 5;
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
    cholmod_free_dense(&sums, &common);
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
    cholmod_sparse *subL;
    int rowNeeded = 0, colNeeded = 0;
    common.print = 5;
    
    cholmod_dense *result = cholmod_zeros(LxCHOL->nrow, 1,LxCHOL->xtype, &common);
    int *indX = (int *)[indicesNeededXCHOL mutableBytes];
    for (int i = 0; i < numUnknownX; i++) {
        int pixX;//, pixY;
        pixX = indX[i] % (int)(imageDimensions.width+1);
        if (pixX == 1) {
            rowNeeded = indX[i];
            colNeeded = indX[i]-1;
            
            subL = cholmod_submatrix(adjCHOL, &rowNeeded, 1, &colNeeded, 1, TRUE, TRUE, &common);
            
            ((double *)result->x)[i] += ((double *)subL->x)[0] * ((double *)xCoordsCHOL->x)[indX[i]-1];
            
            cholmod_free_sparse(&subL, &common);
        }
        if (pixX == (int)imageDimensions.width - 1) {
            rowNeeded = indX[i];
            colNeeded = indX[i]+1;
            
            subL = cholmod_submatrix(adjCHOL, &rowNeeded, 1, &colNeeded, 1, TRUE, TRUE, &common);
            
            ((double *)result->x)[i] += ((double *)subL->x)[0] * ((double *)xCoordsCHOL->x)[indX[i]+1];
            
            cholmod_free_sparse(&subL, &common);
        }
    }
    cholmod_finish(&common);
    return result;
}

-(cholmod_dense *) getCy {
    cholmod_common common;
    cholmod_start(&common);
    cholmod_sparse *subL;
    int rowNeeded = 0, colNeeded = 0;
    common.print = 5;
    
    int nodes = (imageDimensions.height+1) * (imageDimensions.width+1);
    int *indY = (int *)[indicesNeededYCHOL mutableBytes];
    cholmod_dense *result = cholmod_zeros(LyCHOL->nrow, 1, LyCHOL->xtype, &common);
    for (int i = 0; i < numUnknownY; i++) {        
        if (indY[i] < 2 * (imageDimensions.width+1)) {
            rowNeeded = indY[i];
            colNeeded = indY[i]-(imageDimensions.width+1);
            
            subL = cholmod_submatrix(adjCHOL, &rowNeeded, 1, &colNeeded, 1, TRUE, TRUE, &common);
            
            ((double *)result->x)[i] += ((double *)subL->x)[0] * ((double *)yCoordsCHOL->x)[indY[i] - (int)(imageDimensions.width+1)];
            
            cholmod_free_sparse(&subL, &common);
        }
        if (indY[i] >= nodes - 2 * (imageDimensions.width+1)) {
            rowNeeded = indY[i];
            colNeeded = indY[i]+(imageDimensions.width+1);
            
            subL = cholmod_submatrix(adjCHOL, &rowNeeded, 1, &colNeeded, 1, TRUE, TRUE, &common);
            
            ((double *)result->x)[i] += ((double *)subL->x)[0] * ((double *)yCoordsCHOL->x)[indY[i] + (int)(imageDimensions.width+1)];
            
            cholmod_free_sparse(&subL, &common);
        }
    }
    cholmod_finish(&common);
    return result;
}

-(void) getSolutionXWith: (cholmod_sparse *) Ltilde andRHS: (cholmod_dense *)C {
    cholmod_common common;
    cholmod_start(&common);
    
    cholmod_dense *guess;
    cholmod_sparse *precond;
    
    guess = cholmod_allocate_dense(numUnknownX, 1, numUnknownX, CHOLMOD_REAL, &common);
    precond = cholmod_band(Ltilde, 0, 0, MODE_NUMERICAL, &common);
    
    long nonzero = cholmod_nnz(precond, &common);
    for (int i = 0; i < nonzero; i++) {
        ((double *)precond->x)[i] = 1.0 / ((double *)precond->x)[i];
    }
    
    int *ind = (int *)[indicesNeededXCHOL bytes];
    for (int i = 0; i < numUnknownX; i++) {
        ((double *)guess->x)[i] = ind[i] % ((int)imageDimensions.width+1);
    }
    solvedX = [self doConjugateGradientWithA:Ltilde andB:C withInitialGuess:guess andMaxIterations:max andPreconditioner:precond]; //result
    
    cholmod_free_dense(&guess, &common);
    cholmod_free_sparse(&precond, &common);

    cholmod_finish(&common);
}

-(void) getSolutionYWith: (cholmod_sparse *) Ltilde andRHS: (cholmod_dense *)C {
    cholmod_common common;
    cholmod_start(&common);
    
    cholmod_dense *guess;
    cholmod_sparse *precond;
    
    guess = cholmod_allocate_dense(numUnknownY, 1, numUnknownY, CHOLMOD_REAL, &common);
    precond = cholmod_band(Ltilde, 0, 0, MODE_NUMERICAL, &common);
    
    long nonzero = cholmod_nnz(precond, &common);
    for (int i = 0; i < nonzero; i++) {
        ((double *)precond->x)[i] = 1.0 / ((double *)precond->x)[i];
    }
    
    int *ind = (int *)[indicesNeededYCHOL bytes];
    for (int i = 0; i < numUnknownY; i++) {
        ((double *)guess->x)[i] = ind[i] / ((int)imageDimensions.width+1);
    }
    
    solvedY = [self doConjugateGradientWithA:Ltilde andB:C withInitialGuess:guess andMaxIterations:max andPreconditioner:precond]; //result
    
    cholmod_free_dense(&guess, &common);
    cholmod_free_sparse(&precond, &common);
    
    cholmod_finish(&common);
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
    
    NSLog(@"Solving for X");
    [self getSolutionXWith:LxCHOL andRHS:Cx];
    NSLog(@"Solving for Y");
    [self getSolutionYWith:LyCHOL andRHS:Cy];
    
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
