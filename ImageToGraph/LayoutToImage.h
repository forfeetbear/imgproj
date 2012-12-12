//
//  LayoutToImage.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 12/12/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/core/core.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <CHOLMOD/Include/cholmod.h>
#import "CHOLMODUtil.h"
#import "NSImage+OpenCV.h"

@interface LayoutToImage : NSObject {
    cv::Mat image;
    cv::Mat mapX;
    cv::Mat mapY;
}

-(id) initWithImage: (NSImage *) im andLayoutWithXCoords: (cholmod_dense *) xcord andYCoords: (cholmod_dense *) ycord;
-(cv::Mat) interpolatedImage;

@end