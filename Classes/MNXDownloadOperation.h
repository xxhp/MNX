#import <Foundation/Foundation.h>
#import "AMSerialPort.h"

@class MNXDownloadOperation;

@protocol MNXDownloadOperationDelegate

- (void)downloadOperationDidStartDownloadingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishDownloadingData:(NSData *)inData logSize:(NSUInteger)logSize;

- (void)downloadOperationDidStartPurgingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperationDidFinishPurgingData:(MNXDownloadOperation *)inOperation;

- (void)downloadOperationCancelled:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailWithError:(NSError *)inError;

@end

typedef enum {
	MNXDownloadOperationNoError = 0,
	MNXDownloadOperationUnknowError = 1,
	MNXDownloadOperationUnableToOpenDevice = 2,
	MNXDownloadOperationDataTransferError = 3,
	MNXDownloadOperationNoDataOnDevice = 4,
	MNXDownloadOperationInitFailed = 5,
	MNXDownloadOperationFailToPurgeData = 6
} MNXDownloadOperationErrorCode;

typedef enum {
	MNXDownloadOperationActionDownload = 0,
	MNXDownloadOperationActionPurge = 1
} MNXDownloadOperationAction;

@interface MNXDownloadOperation : NSOperation
{
	id <MNXDownloadOperationDelegate> delegate;
	AMSerialPort *port;
	MNXDownloadOperationAction action;
}

@property (assign) MNXDownloadOperationAction action;
@property (assign, nonatomic) id <MNXDownloadOperationDelegate> delegate;
@property (retain, nonatomic) AMSerialPort *port;

@end

extern NSString *const MNXDownloadOperationErrorDomain;
