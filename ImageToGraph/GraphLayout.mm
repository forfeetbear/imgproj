//
//  GraphLayout.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "GraphLayout.h"

@implementation GraphLayout

-(id) initWithGraph: (SparseMatrix<double>) graphRep andImageSize: (NSSize) size {
    if (self = [super init]) {
        adj = graphRep;
        computed = NO;
        xCoords = VectorXd::Constant(adj.rows(), -1);
        yCoords = VectorXd::Constant(adj.rows(), -1);
        imgHeight = size.height;
        imgWidth = size.width;
        numUnknownX = imgWidth * imgHeight;
        numUnknownY = imgHeight * imgWidth;
    }
    
    return self;
}

#pragma mark Internal Functions

-(void) setupFixedPoints {
    int rows = adj.rows();
    //Add fixed x points - left and right edges
    for (int i = 0; i < rows; i+=imgWidth) {
        xCoords(i) = 0;
        xCoords(i+imgWidth-1) = imgWidth-1;
        numUnknownX -= 2;
    }
    //Add fixed y points - bottom and top edges
    for (int i = 0; i < imgWidth; i++) {
        yCoords(i) = 0;
        yCoords((imgHeight-1)*imgWidth+i) = imgHeight - 1;
        numUnknownY -= 2;
    }
    //create the array of unknown indices
    int index = 1;
    indicesNeededX2.resize(xCoords.size());
    indicesNeededY2.resize(xCoords.size());
    
    for (int i = 0; i < xCoords.size(); i++) {
        if (xCoords(i) < 0) {
            indicesNeededX.push_back(i);
            indicesNeededX2[i] = index++;
        }
    }
    index = 1;
    for (int i = 0; i < yCoords.size(); i++) {
        if (yCoords(i) < 0) {
            indicesNeededY.push_back(i);
            indicesNeededY2[i] = index++;
        }
    }
}

-(SparseMatrix<double>) getLap {
    int dim = adj.rows();
    SparseMatrix<double> res(dim, dim);
    SparseMatrix<double> Lx1(numUnknownX, numUnknownX);
    Lx1.reserve(VectorXi::Constant(numUnknownX, 5));
    SparseMatrix<double> Ly1(numUnknownX, numUnknownX);
    Ly1.reserve(VectorXi::Constant(numUnknownY, 5));
    for (int k=0; k<adj.outerSize(); ++k) { //THIS IS THE SLOW PART
        NSLog(@"%i out of %i", k, adj.outerSize());
        int xColumn = indicesNeededX2[k] - 1;
        int yColumn = indicesNeededY2[k] - 1;
        int xRow = -1;
        int yRow = -1;
        for (SparseMatrix<double>::InnerIterator it(adj,k); it; ++it) {
            res.coeffRef(it.row(), it.row()) += it.value();
            if ((xRow = indicesNeededX2[it.row()] - 1) >= 0) {
                Lx1.coeffRef(xRow, xRow) += it.value();
            }
            if ((yRow = indicesNeededY2[it.row()] - 1) >= 0) {
                Ly1.coeffRef(yRow, yRow) += it.value();
            }
            if (xColumn >= 0) {
                if((xRow = indicesNeededX2[it.row()] - 1) >= 0 && xRow != xColumn) {
                    Lx1.coeffRef(xRow, xColumn) -= it.value();
                }
            }
            if (yColumn >= 0) {
                if((yRow = indicesNeededY2[it.row()] - 1) >= 0 && yRow != yColumn) {
                    Ly1.coeffRef(yRow, yColumn) -= it.value();
                }
            }
        }
    }
    Lx1.makeCompressed();
    Ly1.makeCompressed();
    Lx = Lx1;
    Ly = Ly1;
    return res - adj;
}

-(void) printVector: (vector<int>) v {
    cout << "{";
    for(int i = 0; i < v.size(); i++) {
        cout << v[i];
        if (i < v.size() - 1) {
            cout << ", ";
        } else {
            cout << "}" << endl;
        }
    }
}

-(SparseMatrix<double>) getLTildeBruteForceWith: (vector<int>) indices {
    SparseMatrix<double> result(numUnknownX, numUnknownX);
    result.reserve(VectorXi::Constant(numUnknownX, 5));
    for (int i = 0; i < indices.size(); i++) {
        for (int j = 0; j < indices.size(); j++) {       
            if (double temp = lap.coeffRef(indices[i], indices[j])) {
                result.insert(i, j) = temp;
            }
        }
    }
    result.makeCompressed();
    return result;
}

-(SparseMatrix<double>) getLxTilde {
    SparseMatrix<double> result = [self getLTildeBruteForceWith: indicesNeededX];
    return result;
}

-(SparseMatrix<double>) getLyTilde {
    SparseMatrix<double> result = [self getLTildeBruteForceWith: indicesNeededY];
    return result;
}

-(VectorXd) getCx {
    VectorXd result = VectorXd::Zero(numUnknownX);
    for (int i = 0; i < indicesNeededX.size(); i++) {
        if (indicesNeededX[i] % imgWidth == 1) {
            result(i) += adj.coeffRef(indicesNeededX[i], indicesNeededX[i] - 1) * xCoords(indicesNeededX[i]-1);
        }
        if (indicesNeededX[i] % imgWidth == imgWidth - 2) {
            result(i) += adj.coeffRef(indicesNeededX[i], indicesNeededX[i] + 1) * xCoords(indicesNeededX[i]+1);
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
    [self setupFixedPoints];
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
