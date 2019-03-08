//
//  NSData+AES256Encryption.h
//  V2RayX
//
//


#import <Cocoa/Cocoa.h>

@interface NSData (AES256Encryption)
- (NSData *)encryptedDataWithKey:(NSString*)key;
- (NSData* )decryptedDataWithKey:(NSString*)key;
@end

