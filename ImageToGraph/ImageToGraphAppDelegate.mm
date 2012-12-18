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
#import <iostream>

@implementation ImageToGraphAppDelegate

#pragma mark Weight Functions

//weightFunction WFBlueIntensity = ^double(NSPoint p1, NSPoint p2, double f, NSBitmapImageRep *rawImg) {
//    assert(f > 0);
//    NSColor *col1 = [rawImg colorAtX:p1.x y:p1.y];
//    NSColor *col2 = [rawImg colorAtX:p2.x y:p2.y];
//    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
//    
//    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
//    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
//    
//    return  1.0 - (b1 + b2) / 2 + f;
//    //quick workaround for if colours are black
//};

//weightFunction WFRedIntensity = ^double(NSPoint p1, NSPoint p2, double f, NSBitmapImageRep *rawImg) {
//    assert(f > 0);
//    NSColor *col1 = [rawImg colorAtX:p1.x y:p1.y];
//    NSColor *col2 = [rawImg colorAtX:p2.x y:p2.y];
//    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
//    
//    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
//    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
//    
//    return  1.0 - (r1 + r2) / 2 + f;
//};

- (weightFunction) WFRedIntensity {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        assert(f > 0);
        int offset1 = p1.x*4 + p1.y*__image.image.size.width*4;
        int offset2 = p2.x*4 + p2.y*__image.image.size.width*4;
        int r1, g1, b1, r2, g2, b2;
        
        r1 = ((unsigned char *)im)[offset1];
        g1 = ((unsigned char *)im)[offset1+1];
        b1 = ((unsigned char *)im)[offset1+2];
        
        r2 = ((unsigned char *)im)[offset2];
        g2 = ((unsigned char *)im)[offset2+1];
        b2 = ((unsigned char *)im)[offset2+2];
        
        return 255 - (r1 + r2) / 2 + f;
        //quick workaround for if colours are black
    };
}

- (weightFunction) WFGreenIntensity {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        assert(f > 0);
        int offset1 = p1.x*4 + p1.y*__image.image.size.width*4;
        int offset2 = p2.x*4 + p2.y*__image.image.size.width*4;
        int r1, g1, b1, r2, g2, b2;
        
        r1 = ((unsigned char *)im)[offset1];
        g1 = ((unsigned char *)im)[offset1+1];
        b1 = ((unsigned char *)im)[offset1+2];
        
        r2 = ((unsigned char *)im)[offset2];
        g2 = ((unsigned char *)im)[offset2+1];
        b2 = ((unsigned char *)im)[offset2+2];
        
        return (g1 + g2) / 2 + f;
        //quick workaround for if colours are black
    };
}

- (weightFunction) WFBlueIntensity {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        assert(f > 0);
        int offset1 = p1.x*4 + p1.y*__image.image.size.width*4;
        int offset2 = p2.x*4 + p2.y*__image.image.size.width*4;
        int r1, g1, b1, r2, g2, b2;
        
        r1 = ((unsigned char *)im)[offset1];
        g1 = ((unsigned char *)im)[offset1+1];
        b1 = ((unsigned char *)im)[offset1+2];
        
        r2 = ((unsigned char *)im)[offset2];
        g2 = ((unsigned char *)im)[offset2+1];
        b2 = ((unsigned char *)im)[offset2+2];
        
        return 255 - (b1 + b2) / 2 + f;
        //quick workaround for if colours are black
    };
}

- (weightFunction) WFInvertedIntensity {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        assert(f > 0);
        int offset1 = p1.x*4 + p1.y*__image.image.size.width*4;
        int offset2 = p2.x*4 + p2.y*__image.image.size.width*4;
        int r1, g1, b1, r2, g2, b2;
        
        r1 = ((unsigned char *)im)[offset1];
        g1 = ((unsigned char *)im)[offset1+1];
        b1 = ((unsigned char *)im)[offset1+2];
        
        r2 = ((unsigned char *)im)[offset2];
        g2 = ((unsigned char *)im)[offset2+1];
        b2 = ((unsigned char *)im)[offset2+2];
        
        return ((r1 + r2 + g1 + g2 + b1 + b2) / 6 + f);
        //quick workaround for if colours are black
    };
}

- (weightFunction) WFIntensity {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        assert(f > 0);
        int offset1 = p1.x*4 + p1.y*__image.image.size.width*4;
        int offset2 = p2.x*4 + p2.y*__image.image.size.width*4;
        int r1, g1, b1, r2, g2, b2;
        
        r1 = ((unsigned char *)im)[offset1];
        g1 = ((unsigned char *)im)[offset1+1];
        b1 = ((unsigned char *)im)[offset1+2];
        
        r2 = ((unsigned char *)im)[offset2];
        g2 = ((unsigned char *)im)[offset2+1];
        b2 = ((unsigned char *)im)[offset2+2];
        
        return 255 - (r1 + r2 + g1 + g2 + b1 + b2) / 6 + f;
        //quick workaround for if colours are black
    };
}

weightFunction WFEasy = ^double(NSPoint p1, NSPoint p2, double f, const void *rawImg) {
    return 1;
};

- (weightFunction) makeCircleFunctionWithCentre: (NSPoint) c andRadius: (double) rad {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        NSPoint average = NSMakePoint((p1.x+p2.x)/2, (p1.y+p2.y)/2);
        double dist = sqrt((average.x-c.x)*(average.x-c.x) + (average.y-c.y)*(average.y-c.y));
        if (dist < rad) {
            return 0.1;
        } else {
            return 1;
        }
    };
}

- (weightFunction) makeRectangleFunctionWithCentre: (NSPoint) c withWidth: (double) w andHeight: (double) h {
    return ^double (NSPoint p1, NSPoint p2, double f, const void *im) {
        NSPoint average = NSMakePoint((p1.x+p2.x)/2, (p1.y+p2.y)/2);
        double maxX = c.x + w/2;
        double minX = c.x - w/2;
        double maxY = c.y + h/2;
        double minY = c.y - h/2;
        if (average.x > minX && average.x < maxX && average.y > minY && average.y < maxY) {
            return 1;
        }
        return 0.1;
    };
}

#pragma mark Initialisation

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

#pragma mark Buttons

- (IBAction)pressDebugButton:(id)sender {
    cholmod_common common;
    cholmod_start(&common);
    
    NSLog(@"Starting:");
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:[self makeCircleFunctionWithCentre:NSMakePoint(__image.image.size.width/2, __image.image.size.height/2) andRadius:__image.image.size.width/4]];
    if(creator) {
        NSLog(@"Converting image to graph");
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:adj andImageSize:__image.image.size];
        cholmod_dense *xcord = [gLayout getX];
        cholmod_dense *ycord = [gLayout getY];
        
        //interpolation
//        LayoutToImage *layout = [[LayoutToImage alloc] initWithImage:__image.image andLayoutWithXCoords:xcord andYCoords:ycord];
//        cv::Mat out = [layout interpolatedImage];
        [_oglView drawImageFromData:[__image.image data] withSize:__image.image.size xCoords:xcord yCoords:ycord];
        _glWindow.isVisible = YES;
        
        //draw points
        [__gView drawPointsWithX:xcord andY:ycord andPic:__image.image];
        _gWindow.isVisible = YES;
        
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
    ImageToGraph *creator = [[ImageToGraph alloc] initWithImage:__image.image usingWeightFunction:[self WFInvertedIntensity]];
    if(creator) {
        NSLog(@"Converting image to graph");
        cholmod_sparse *adj = [creator getAdj];
        NSLog(@"Starting Layout:");
        GraphLayout *gLayout = [[GraphLayout alloc] initWithGraph:adj andImageSize:__image.image.size];
        cholmod_dense *xcord = [gLayout getX];
        cholmod_dense *ycord = [gLayout getY];
        
        //interpolation
//        LayoutToImage *layout = [[LayoutToImage alloc] initWithImage:__image.image andLayoutWithXCoords:xcord andYCoords:ycord];
//        cv::Mat out = [layout interpolatedImage];
        [_oglView drawImageFromData:[__image.image data] withSize:__image.image.size xCoords:xcord yCoords:ycord];
        _glWindow.isVisible = YES;
        
//        [__gView drawPointsWithX:xcord andY:ycord  andPic:__image.image];
//        _gWindow.isVisible = YES;
        
        cholmod_free_sparse(&adj, &common);
    } else {
        NSLog(@"Conversion failed");
    }
    
    cholmod_finish(&common);
}
@end
