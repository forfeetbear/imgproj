//
//  ImageToGraphAppDelegate.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 11/29/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "ImageToGraphAppDelegate.h"
#import "ImageToGraph.h"
#import "GraphLayout.h"
#import <Eigen/Sparse>
#import <iostream>

using namespace Eigen;
using namespace std;

@implementation ImageToGraphAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)pressDebugButton:(id)sender {
    cholmod_common common;
    cholmod_start(&common);
    NSLog(@"Starting:");
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:EASY];
    if(creator) {
        NSLog(@"Converting image to graph");
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
//        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:imRep andImageSize:__image.image.size];
//        VectorXd xcord = [gLayout getX];
//        VectorXd ycord = [gLayout getY];
//        [__gView drawPointsWithX:xcord andY:ycord];
//        _gWindow.isVisible = YES;
        cholmod_free_sparse(&adj, &common);
    } else {
        NSLog(@"Conversion failed");
    }
    
    cholmod_finish(&common);
}

- (IBAction)pressOtherDebugButton:(id)sender {
    cholmod_common common;
    cholmod_start(&common);
    NSLog(@"Starting:");
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:ACCORDINGTOPIXEL];    
    if(creator) {
        NSLog(@"Converting image to graph");
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
//        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:imRep andImageSize:__image.image.size];
//        VectorXd xcord = [gLayout getX];
//        VectorXd ycord = [gLayout getY];
//        [__gView drawPointsWithX:xcord andY:ycord];
//        _gWindow.isVisible = YES;
//        NSLog(@"Done");
        //deallocate the adjacency matrix
        cholmod_free_sparse(&adj, &common);
    } else {
        NSLog(@"wat");
    }
    
    cholmod_finish(&common);
}

- (IBAction)pressedOtherOtherDebugButton:(id)sender {
    cholmod_common common;
    cholmod_dense *x, *y;
    cholmod_start(&common);
    
    x = cholmod_allocate_dense(6, 1, 6, CHOLMOD_REAL, &common);
    y = cholmod_allocate_dense(6, 1, 6, CHOLMOD_REAL, &common);
    ((double *)x->x)[0] = 5;
    ((double *)x->x)[1] = 10;
    ((double *)x->x)[2] = 15;
    ((double *)x->x)[3] = 20;
    ((double *)x->x)[4] = 25;
    ((double *)x->x)[5] = 0;
    
    ((double *)y->x)[0] = 5;
    ((double *)y->x)[1] = 10;
    ((double *)y->x)[2] = 15;
    ((double *)y->x)[3] = 20;
    ((double *)y->x)[4] = 25;    
    ((double *)y->x)[5] = 0;

    [__gView drawPointsWithX:x andY:y];
    _gWindow.isVisible = YES;
}
@end
