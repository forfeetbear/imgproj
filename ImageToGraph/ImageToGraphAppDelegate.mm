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
    //cout << imRep << endl;
}

- (IBAction)pressedOtherOtherDebugButton:(id)sender {
    VectorXd x(5), y(5);
    x(0) = 5;
    x(1) = 10;
    x(2) = 15;
    x(3) = 20;
    x(4) = 25;
    
    
    y(0) = 5;
    y(1) = 10;
    y(2) = 15;
    y(3) = 20;
    y(4) = 25;

    [__gView drawPointsWithX:x andY:y];
}
@end
