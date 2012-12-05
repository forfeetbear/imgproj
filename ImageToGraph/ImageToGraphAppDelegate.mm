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
    NSLog(@"Starting:");
    NSLog(@"Converting image to graph");
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:EASY];
    if(creator) {
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
//        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:imRep andImageSize:__image.image.size];
//        VectorXd xcord = [gLayout getX];
//        VectorXd ycord = [gLayout getY];
//        [__gView drawPointsWithX:xcord andY:ycord];
//        _gWindow.isVisible = YES;
    } else {
        NSLog(@"Conversion failed");
    }
}

- (IBAction)pressOtherDebugButton:(id)sender {
    NSLog(@"Starting:");
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:ACCORDINGTOPIXEL];    
    if(creator) {        
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
//        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:imRep andImageSize:__image.image.size];
//        VectorXd xcord = [gLayout getX];
//        VectorXd ycord = [gLayout getY];
//        [__gView drawPointsWithX:xcord andY:ycord];
//        _gWindow.isVisible = YES;
//        NSLog(@"Done");
    } else {
        NSLog(@"wat");
    }
    
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
