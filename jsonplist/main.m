//
//  main.m
//  jsonplist
//
//  Copyright © 2017 Project V2Ray. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printf("Please provide at least one input file!\n");
            return 1;
        }
        NSString* imputFile = [NSString stringWithFormat:@"%s", argv[1]];
        NSInteger length = [imputFile length];
        if ([[[imputFile substringFromIndex:length - 4] lowercaseString] isEqualToString:@"json"]) {
            NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:
                                  [NSData dataWithContentsOfFile:imputFile] options:NSJSONReadingMutableLeaves error:nil];
            NSString* targetFile = [[imputFile substringToIndex:length - 4] stringByAppendingString:@"plist"];
            [dict writeToFile:targetFile  atomically:NO];
            printf("%s\n", [targetFile cStringUsingEncoding:NSUTF8StringEncoding]);
            return 0;
        } else if ([[[imputFile substringFromIndex:length - 5] lowercaseString] isEqualToString:@"plist"]) {
            NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:imputFile];
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
            NSString* targetFile = [[imputFile substringToIndex:length - 5] stringByAppendingString:@".plist"];
            [jsonData writeToFile:targetFile atomically:NO];
            printf("%s\n", [targetFile cStringUsingEncoding:NSUTF8StringEncoding]);
            return 0;
        } else {
            printf("Only json and plist are supported!\n");
            return 1;
        }
        
    }
    return 0;
}
