//
//  CHOLMODUtil.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 12/12/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "CHOLMODUtil.h"

@implementation CHOLMODUtil

+(void) insertIntoTriplet: (cholmod_triplet *) t WithRow: (int) r col: (int) c andValue: (double) x {
    size_t index = t->nnz++;
    ((int *)t->i)[index] = r;
    ((int *)t->j)[index] = c;
    ((double *)t->x)[index] = x;
}

+(cv::Mat) convertCHOLMODDense:(cholmod_dense *)d withWidth: (int) w andHeight: (int) h {
    cv::Mat result(h, w, CV_32FC1);
    for (int i = 0; i < d->nzmax; i++) {
        int pixX = i % w;
        int pixY = i / w;
        
        result.at<float>(pixY, pixX) = ((double *)d->x)[i];
    }
    return result;
}

@end
