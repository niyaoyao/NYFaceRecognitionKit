#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NYDlibWrapper.h"
#import "NYFaceRecognition.h"

FOUNDATION_EXPORT double NYFaceRecognitionKitVersionNumber;
FOUNDATION_EXPORT const unsigned char NYFaceRecognitionKitVersionString[];

