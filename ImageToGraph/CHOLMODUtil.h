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
+(double) cholmodDotProductOfX: (cholmod_dense *) x andY: (cholmod_dense *) y;
+(cholmod_dense *) cholmodAddDenseA: (cholmod_dense *) a andB: (cholmod_dense *) b withScalesA: (double) A andB: (double) B;
+(cv::Mat) convertXCHOLMODDense: (cholmod_dense *) d withWidth: (int) w andHeight: (int) h;
+(cv::Mat) convertYCHOLMODDense: (cholmod_dense *) d withWidth: (int) w andHeight: (int) h;
+(cv::Mat) convertCHOLMODDense:(cholmod_dense *)d withWidth: (int) w andHeight: (int) h;

@end
