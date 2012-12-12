//
//  LayoutToImage.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 12/12/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "LayoutToImage.h"

@implementation LayoutToImage

-(id) initWithImage:(NSImage *)im andLayoutWithXCoords:(cholmod_dense *)xcord andYCoords:(cholmod_dense *)ycord {
    self = [super init];
    
    if (self) {
        image = [im CVMat];
        mapX = [CHOLMODUtil convertCHOLMODDense:xcord withWidth:im.size.width andHeight:im.size.height];
        mapY = [CHOLMODUtil convertCHOLMODDense:ycord withWidth:im.size.width andHeight:im.size.height];
    }
    
    return self;
}

-(cv::Mat) interpolatedImage {
    cv::Mat result(image.size(), image.type());
    
    cv::remap(image, result, mapX, mapY, CV_INTER_CUBIC);
    
    cv::namedWindow("Tester");
    cv::imshow("Tester", result);
    
    cv::waitKey(-1);
    
    return result;
}

@end