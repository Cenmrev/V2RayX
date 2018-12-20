//
//  utilities.m
//  V2RayX
//
//

#import "utilities.h"

NSUInteger searchInArray(NSString* str, NSArray* array) {
    if ([str isKindOfClass:[NSString class]]) {
        NSUInteger index = 0;
        for (NSString* s in array) {
            if ([s isKindOfClass:[NSString class]] && [s isEqualToString:str]) {
                return index;
            }
            index += 1;
        }
    }
    return 0;
}
