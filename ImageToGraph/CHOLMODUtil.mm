//
//  CHOLMODUtil.m
//  ImageToGraph
//
//  Created by Matthew Bennett on 12/12/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "CHOLMODUtil.h"

@implementation CHOLMODUtil

+(double) cholmodDotProductOfX: (cholmod_dense *) x andY: (cholmod_dense *) y {
    double sum = 0.0;
    if(x->nrow != y->nrow) {
        NSLog(@"cannot dot these");
        return -1;
    }
    for (int i = 0; i < x->nrow; i++) {
        sum += ((double *)x->x)[i] * ((double *)y->x)[i];
    }
    return sum;
}

+(cholmod_dense *) cholmodAddDenseA: (cholmod_dense *) a andB: (cholmod_dense *) b withScalesA: (double) A andB: (double)B{
    cholmod_common common;
    cholmod_dense *result = cholmod_allocate_dense(a->nrow, 1, a->nrow, CHOLMOD_REAL, &common);
    for (int i = 0; i < a->nrow; i++) {
        ((double *)result->x)[i] = A*((double *)a->x)[i] + B*((double *)b->x)[i];
    }
    return result;
}

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


+(cv::Mat) convertYCHOLMODDense:(cholmod_dense *)d withWidth: (int) w andHeight: (int) h {
    cv::Mat result(h, w, CV_32FC1);
    for (int i = 0; i < d->nzmax; i++) {
        int pixX = i % w;
        int pixY = i / w;
        
        double diff = ((double *)d->x)[i] - pixY;
        
        result.at<float>(pixY, pixX) = pixY - diff;
    }
    return result;
}

+(cv::Mat) convertXCHOLMODDense:(cholmod_dense *)d withWidth: (int) w andHeight: (int) h {
    cv::Mat result(h, w, CV_32FC1);
    for (int i = 0; i < d->nzmax; i++) {
        int pixX = i % w;
        int pixY = i / w;
        
        double diff = ((double *)d->x)[i] - pixX;
        
        result.at<float>(pixY, pixX) = pixX - diff;
    }
    return result;
}

@end
