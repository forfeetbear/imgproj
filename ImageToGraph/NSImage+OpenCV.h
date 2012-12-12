//
//  NSImage+OpenCV.h
//

#import <Cocoa/Cocoa.h>
#import <opencv2/core/core.hpp>
#import <opencv2/imgproc/imgproc.hpp>

@interface NSImage (NSImage_OpenCV) {
    
}

+(NSImage*)imageWithCVMat:(const cv::Mat&)cvMat;
-(id)initWithCVMat:(const cv::Mat&)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end