//
//  NYDlibWrapper.h
//  NYFaceRecognitionKit
//
//  Created by niyao on 7/23/18.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@interface NYDlibWrapper : NSObject

- (instancetype)init;
- (NSArray *)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;

@end
