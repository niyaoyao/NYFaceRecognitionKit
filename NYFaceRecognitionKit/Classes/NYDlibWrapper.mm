//
//  NYDlibWrapper.m
//  NYFaceRecognitionKit
//
//  Created by niyao on 7/23/18.
//

#import "NYDlibWrapper.h"

#import <UIKit/UIKit.h>
#import "image_processing.h"
#import "image_io.h"

@interface NYDlibWrapper ()

@property (assign) BOOL prepared;

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end

@implementation NYDlibWrapper
{
    dlib::shape_predictor sp;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    //    NSString *modelFileName = [[NSBundle mainBundle] URLForResource:@"shape_predictor_68_face_landmarks" withExtension:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

- (NSArray *)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    
    NSMutableArray *landmarks = [NSMutableArray array];
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // set_size expects rows, cols format
    img.set_size(height, width);
    NSLog(@"h,w: %zu, %zu", height, width);
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];
    
    // for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            
            //            printf("[%d]x:%ld, y:%ld, z:%ld\n", k, p.x(), p.y(), p.z());
            NSDictionary *landmark = @{@"x": @(p.x()),@"y": @(p.y()),@"z": @(p.z())};
            [landmarks addObject:landmark];
            draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
        }
    }
    
    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return landmarks;
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);
        
        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}
@end
