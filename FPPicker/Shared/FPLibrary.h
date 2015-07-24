//
//  FPLibrary.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Filepicker.io. All rights reserved.
//

#import "FPTypedefs.h"

@class FPSource;

@interface FPLibrary : NSObject

+ (void)requestObjectMediaInfo:(NSDictionary *)obj
                    withSource:(FPSource *)source
           usingOperationQueue:(NSOperationQueue *)operationQueue
                shouldDownload:(BOOL)shouldDownload
                       success:(FPFetchObjectSuccessBlock)success
                       failure:(FPFetchObjectFailureBlock)failure
                      progress:(FPFetchObjectProgressBlock)progress;

+ (void)     uploadData:(NSData *)filedata
                  named:(NSString *)filename
                 toPath:(NSString *)path
             ofMimetype:(NSString *)mimetype
    usingOperationQueue:(NSOperationQueue *)operationQueue
                success:(FPUploadAssetSuccessBlock)success
                failure:(FPUploadAssetFailureBlock)failure
               progress:(FPUploadAssetProgressBlock)progress;

+ (void)  uploadDataURL:(NSURL *)localURL
                  named:(NSString *)filename
                 toPath:(NSString *)path
             ofMimetype:(NSString *)mimetype
    usingOperationQueue:(NSOperationQueue *)operationQueue
                success:(FPUploadAssetSuccessBlock)success
                failure:(FPUploadAssetFailureBlock)failure
               progress:(FPUploadAssetProgressBlock)progress;

+ (NSURLRequest *)requestForLoadPath:(NSString *)loadpath
                          withFormat:(NSString *)type
                        andMimetypes:(NSArray *)mimetypes
                         cachePolicy:(NSURLRequestCachePolicy)policy;

+ (NSURLRequest *)requestForLoadPath:(NSString *)loadpath
                          withFormat:(NSString *)type
                        andMimetypes:(NSArray *)mimetypes
                         byAppending:(NSString *)additionalString
                         cachePolicy:(NSURLRequestCachePolicy)policy;

@end
