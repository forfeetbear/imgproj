//
//  CHOLMODUtil.h
//  ImageToGraph
//
//  Created by Matthew Bennett on 12/12/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CHOLMOD/Include/cholmod.h>
#import <opencv2/core/core.hpp>

@interface CHOLMODUtil : NSObject

+(void) insertIntoTriplet: (cholmod_triplet *) t WithRow: (int) r col: (int) c andValue: (double) x;
+(cv::Mat) convertXCHOLMODDense: (cholmod_dense *) d withWidth: (int) w andHeight: (int) h;
+(cv::Mat) convertYCHOLMODDense: (cholmod_dense *) d withWidth: (int) w andHeight: (int) h;
+(cv::Mat) convertCHOLMODDense:(cholmod_dense *)d withWidth: (int) w andHeight: (int) h;

@end
