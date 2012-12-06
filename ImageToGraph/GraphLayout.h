//
//  GraphLayout.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/30/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Eigen/Sparse>
#import <Eigen/Dense>
#import <Eigen/SparseCholesky>
#import <iostream>
#import <Foundation/Foundation.h>
#import <CHOLMOD/Include/cholmod.h>
#import "ImageToGraph.h"

using namespace Eigen;
using namespace std;

@interface GraphLayout : NSObject {
    SparseMatrix<double> adj;
    cholmod_sparse *adjCHOL;
    SparseMatrix<double> lap;
    cholmod_sparse *lapCHOL;
    SparseMatrix<double> Lx;
    cholmod_sparse *LxCHOL;
    SparseMatrix<double> Ly;
    cholmod_sparse *LyCHOL;
    VectorXd xCoords;
    cholmod_dense *xCoordsCHOL;
    VectorXd yCoords;
    cholmod_dense *yCoordsCHOL;
    BOOL computed;
    NSSize imageDimensions;
    int numUnknownX;
    int numUnknownY;
    vector<int> indicesNeededX;
    NSMutableData *indicesNeededXCHOL;
    vector<int> indicesNeededY;
    NSMutableData *indicesNeededYCHOL;
    ImageToGraph *tempITG;
}

-(id) initWithGraph: (cholmod_sparse *)graphRep andImageSize: (NSSize) size usingITG: (ImageToGraph *) temp;
-(VectorXd) getX;
-(VectorXd) getY;

@end
