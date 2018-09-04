// https://gist.github.com/yfujiki/1664847

#import <Foundation/Foundation.h>

@protocol MutableDeepCopying <NSObject>
-(id) mutableDeepCopy;
@end
@interface NSDictionary (MutableDeepCopy) <MutableDeepCopying>
@end
@interface NSArray (MutableDeepCopy) <MutableDeepCopying>
@end

// Implementation
@implementation NSDictionary (MutableDeepCopy)
- (NSMutableDictionary *) mutableDeepCopy {
    NSMutableDictionary * returnDict = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    NSArray * keys = [self allKeys];
    for(id key in keys) {
        id aValue = [self objectForKey:key];
        id theCopy = nil;
        if([aValue conformsToProtocol:@protocol(MutableDeepCopying)]) {
            theCopy = [aValue mutableDeepCopy];
        } else if([aValue conformsToProtocol:@protocol(NSMutableCopying)]) {
            theCopy = [aValue mutableCopy];
        } else if([aValue conformsToProtocol:@protocol(NSCopying)]){
            theCopy = [aValue copy];
        } else {
            theCopy = aValue;
        }
        [returnDict setValue:theCopy forKey:key];
    }
    return returnDict;
}
@end

@implementation NSArray (MutableDeepCopy)
-(NSMutableArray *)mutableDeepCopy {
    NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:self.count];
    for(id aValue in self) {
        id theCopy = nil;
        if([aValue conformsToProtocol:@protocol(MutableDeepCopying)]) {
            theCopy = [aValue mutableDeepCopy];
        } else if([aValue conformsToProtocol:@protocol(NSMutableCopying)]) {
            theCopy = [aValue mutableCopy];
        } else if([aValue conformsToProtocol:@protocol(NSCopying)]){
            theCopy = [aValue copy];
        } else {
            theCopy = aValue;
        }
        [returnArray addObject:theCopy];
    }
    return returnArray;
}
@end
