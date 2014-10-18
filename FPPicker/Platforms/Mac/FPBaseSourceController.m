//
//  FPBaseSourceController.m
//  FPPicker
//
//  Created by Ruben on 9/25/14.
//  Copyright (c) 2014 Filepicker.io. All rights reserved.
//

#import "FPBaseSourceController.h"
#import "FPInternalHeaders.h"

@interface FPBaseSourceController ()

@end

@implementation FPBaseSourceController

#pragma mark - Accessors

- (void)setRepresentedSource:(FPRepresentedSource *)representedSource
{
    [representedSource cancelAllOperations];

    _representedSource = representedSource;
}

#pragma mark - Public Methods

- (void)fpLoadContentAtPath:(BOOL)force
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
}

- (void)requestObjectMediaInfo:(NSDictionary *)obj
                shouldDownload:(BOOL)shouldDownload
                       success:(FPFetchObjectSuccessBlock)success
                       failure:(FPFetchObjectFailureBlock)failure
                      progress:(FPFetchObjectProgressBlock)progress
{
    if (shouldDownload)
    {
        [self getObjectInfoAndData:obj
                           success:success
                           failure:failure
                          progress:progress];
    }
    else
    {
        [self getObjectInfo:obj
                    success:success
                    failure:failure
                   progress:progress];
    }
}

- (void)cancelAllOperations
{
    [self.representedSource cancelAllOperations];
}

#pragma mark - Private Methods

- (void)getObjectInfo:(NSDictionary *)obj
              success:(FPFetchObjectSuccessBlock)success
              failure:(FPFetchObjectFailureBlock)failure
             progress:(FPFetchObjectProgressBlock)progress
{
    NSURLRequest *request = [self requestForLoadPath:obj[@"link_path"]
                                          withFormat:@"fpurl"
                                         cachePolicy:NSURLRequestReloadRevalidatingCacheData];

    AFRequestOperationSuccessBlock successOperationBlock = ^(AFHTTPRequestOperation *operation,
                                                             id responseObject) {
        FPMediaInfo *mediaInfo = [FPMediaInfo new];

        mediaInfo.remoteURL = [NSURL URLWithString:responseObject[@"url"]];
        mediaInfo.filename = responseObject[@"filename"];
        mediaInfo.key = responseObject[@"key"];
        mediaInfo.source = self.representedSource.source;

        success(mediaInfo);
    };

    AFRequestOperationFailureBlock failureOperationBlock = ^(AFHTTPRequestOperation *operation,
                                                             NSError *error) {
        failure(error);
    };

    AFHTTPRequestOperation *operation;

    operation = [[FPAPIClient sharedClient] HTTPRequestOperationWithRequest:request
                                                                    success:successOperationBlock
                                                                    failure:failureOperationBlock];

    [operation setDownloadProgressBlock: ^(NSUInteger bytesRead,
                                           long long totalBytesRead,
                                           long long totalBytesExpectedToRead) {
        if (progress && totalBytesExpectedToRead > 0)
        {
            progress(1.0f * totalBytesRead / totalBytesExpectedToRead);
        }
    }];

    [self.representedSource.parallelOperationQueue addOperation:operation];
}

- (void)getObjectInfoAndData:(NSDictionary *)obj
                     success:(FPFetchObjectSuccessBlock)success
                     failure:(FPFetchObjectFailureBlock)failure
                    progress:(FPFetchObjectProgressBlock)progress
{
    NSURLRequest *request = [self requestForLoadPath:obj[@"link_path"]
                                          withFormat:@"data"
                                         cachePolicy:NSURLRequestReloadRevalidatingCacheData];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[FPUtils genRandStringLength:20]];

    NSURL *tempURL = [NSURL fileURLWithPath:tempPath
                                isDirectory:NO];

    AFRequestOperationSuccessBlock successOperationBlock = ^(AFHTTPRequestOperation *operation,
                                                             id responseObject) {
        NSDictionary *headers = [operation.response allHeaderFields];
        NSString *mimetype = headers[@"Content-Type"];

        if ([mimetype rangeOfString:@";"].location != NSNotFound)
        {
            mimetype = [mimetype componentsSeparatedByString:@";"][0];
        }

        FPMediaInfo *mediaInfo = [FPMediaInfo new];

        mediaInfo.remoteURL = [NSURL URLWithString:headers[@"X-Data-Url"]];
        mediaInfo.filename = headers[@"X-File-Name"];
        mediaInfo.mediaURL = tempURL;
        mediaInfo.mediaType = [FPUtils UTIForMimetype:mimetype];
        mediaInfo.source = self.representedSource.source;

        if (headers[@"X-Data-Key"])
        {
            mediaInfo.key = headers[@"X-Data-Key"];
        }

        success(mediaInfo);
    };

    AFRequestOperationFailureBlock failureOperationBlock = ^(AFHTTPRequestOperation *operation,
                                                             NSError *error) {
        failure(error);
    };

    AFHTTPRequestOperation *operation;

    operation = [[FPAPIClient sharedClient] HTTPRequestOperationWithRequest:request
                                                                    success:successOperationBlock
                                                                    failure:failureOperationBlock];

    operation.outputStream = [NSOutputStream outputStreamWithURL:tempURL
                                                          append:NO];

    [operation setDownloadProgressBlock: ^(NSUInteger bytesRead,
                                           long long totalBytesRead,
                                           long long totalBytesExpectedToRead) {
        if (progress && totalBytesExpectedToRead > 0)
        {
            progress(1.0f * totalBytesRead / totalBytesExpectedToRead);
        }
    }];

    [self.representedSource.parallelOperationQueue addOperation:operation];
}

- (NSURLRequest *)requestForLoadPath:(NSString *)loadpath
                          withFormat:(NSString *)type
                         cachePolicy:(NSURLRequestCachePolicy)policy
{
    return [self requestForLoadPath:loadpath
                         withFormat:type
                        byAppending:@""
                        cachePolicy:policy];
}

- (NSURLRequest *)requestForLoadPath:(NSString *)loadpath
                          withFormat:(NSString *)type
                         byAppending:(NSString *)additionalString
                         cachePolicy:(NSURLRequestCachePolicy)policy
{
    FPSession *fpSession = [FPSession new];

    fpSession.APIKey = fpAPIKEY;
    fpSession.mimetypes = self.representedSource.source.mimetypes;

    NSString *escapedSessionString = [FPUtils urlEncodeString:[fpSession JSONSessionString]];

    NSMutableString *urlString = [NSMutableString stringWithString:[fpBASE_URL stringByAppendingString:[@"/api/path" stringByAppendingString : loadpath]]];

    if ([urlString rangeOfString:@"?"].location == NSNotFound)
    {
        [urlString appendFormat:@"?format=%@&%@=%@", type, @"js_session", escapedSessionString];
    }
    else
    {
        [urlString appendFormat:@"&format=%@&%@=%@", type, @"js_session", escapedSessionString];
    }

    [urlString appendString:additionalString];

    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:policy
                                                        timeoutInterval:240];

    [mRequest setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:fpCOOKIES]];

    return mRequest;
}

@end