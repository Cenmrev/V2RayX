//
//  NSData+AES256Encryption.m
//  V2RayX
//
//

#import "NSData+AES256Encryption.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AES256Encryption)

- (NSData *)encryptedDataWithKey:(NSString*)key {
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );
    //NSLog(@"%@, %@", key);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          [key cStringUsingEncoding:NSUTF8StringEncoding], kCCKeySizeAES256,
                                          NULL /* initialization vector */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if(cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

-(NSData* )decryptedDataWithKey:(NSString*)key {
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          [key cStringUsingEncoding:NSUTF8StringEncoding], kCCKeySizeAES256,
                                          NULL /* initialization vector */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    if(cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    return nil;
}

@end
