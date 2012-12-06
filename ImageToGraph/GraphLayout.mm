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

#pragma mark UPTOHERE:D

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
    return result;
}

-(VectorXd) getCy {
    VectorXd result = VectorXd::Zero(numUnknownY);
    int nodes = imgWidth * imgHeight;
    for (int i = 0; i < indicesNeededY.size(); i++) {
        if (indicesNeededY[i] < 2 * imgWidth) {
            result(i) += adj.coeffRef(indicesNeededY[i], indicesNeededY[i] - imgWidth) * yCoords(indicesNeededY[i]-imgWidth);
        }
        if (indicesNeededY[i] >= nodes - 2 * imgWidth) {
            result(i) += adj.coeffRef(indicesNeededY[i], indicesNeededY[i] + imgWidth) * yCoords(indicesNeededY[i]+imgWidth);
        }
    }
    return result;
}

-(VectorXd) getSolutionWith: (SparseMatrix<double>) Ltilde andRHS: (VectorXd)C {
    SimplicialLDLT<SparseMatrix<double>> solver;
    VectorXd sol;
    solver.compute(Ltilde);
    NSLog(@"rows: %i cols: %i", Ltilde.rows(), Ltilde.cols());
    if (solver.info() != Success) {
        NSLog(@"Something went wrong - decomposition");
        return C;
    }
    sol = solver.solve(C);
    if(solver.info() != Success) {
        NSLog(@"Something went wrong - solve");
        return C;
    }
    return sol;
}

-(void) fillXWith: (VectorXd) sol {
    for(int i = 0; i < sol.size(); i++) {
        xCoords(indicesNeededX[i]) = sol(i);
    }
}

-(void) fillYWith: (VectorXd) sol {
    for(int i = 0; i < sol.size(); i++) {
        yCoords(indicesNeededY[i]) = sol(i);
    }
}

#pragma mark Interface Functions

-(void) runLayout {
    NSLog(@"Fixing Points");
    [self setupDefaultFixedPoints];
    NSLog(@"Getting Ls");
    lap = [self getLap];
//    NSLog(@"Creating Lx~");
//    SparseMatrix<double> Lxtilde = [self getLxTilde];
//    NSLog(@"Creating Ly~");
//    SparseMatrix<double> Lytilde = [self getLyTilde];
    NSLog(@"Creating Cx");
    VectorXd Cx = [self getCx];
    NSLog(@"Creating Cy");
    VectorXd Cy = [self getCy];
    NSLog(@"Solving for x:");
    VectorXd solvedX = [self getSolutionWith:Lx andRHS:Cx];
    NSLog(@"Solving for y:");
    VectorXd solvedY = [self getSolutionWith:Ly andRHS:Cy];
    NSLog(@"Filling x");
    [self fillXWith: solvedX];
    NSLog(@"Filling y");
    [self fillYWith: solvedY];
    NSLog(@"Done");
    computed = YES;
}

#pragma mark Accessors

-(VectorXd) getX{
    if (!computed) {
        [self runLayout];
    }
    
    return xCoords;
}

-(VectorXd) getY{
    if (!computed) {
        [self runLayout];
    }
    
    return yCoords;
}

@end
