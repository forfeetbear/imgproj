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

using namespace Eigen;
using namespace std;

@interface GraphLayout : NSObject {
    SparseMatrix<double> adj;
    SparseMatrix<double> lap;
    SparseMatrix<double> Lx;
    SparseMatrix<double> Ly;
    VectorXd xCoords;
    VectorXd yCoords;
    BOOL computed;
    int imgHeight;
    int imgWidth;
    int numUnknownX;
    int numUnknownY;
    vector<int> indicesNeededX;
    vector<int> indicesNeededY;
    vector<int> indicesNeededX2;
    vector<int> indicesNeededY2;
}

-(id) initWithGraph: (SparseMatrix<double>)graphRep andImageSize: (NSSize) size;
-(VectorXd) getX;
-(VectorXd) getY;

@end
