#import <Foundation/Foundation.h>
#import "AMSerialPort.h"

@class MNXDownloadOperation;

@protocol MNXDownloadOperationDelegate

- (void)downloadOperationDidStartDownloadingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishDownloadingData:(NSData *)inData logSize:(NSUInteger)logSize;
- (void)downloadOperationCancelled:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailWithError:(NSError *)inError;

@end


@interface MNXDownloadOperation : NSOperation
{
	id <MNXDownloadOperationDelegate> delegate;
	AMSerialPort *port;
}

@property (assign, nonatomic) id <MNXDownloadOperationDelegate> delegate;
@property (retain, nonatomic) AMSerialPort *port;

@end

extern NSString *const MNXDownloadOperationErrorDomain;

enum {
	MNXDownloadOperationNoError = 0,
	MNXDownloadOperationUnknowError = 1,
	MNXDownloadOperationUnableToOpenDevice = 2,
	MNXDownloadOperationDataTransferError = 3,
	MNXDownloadOperationNoDataOnDevice = 4,
	MNXDownloadOperationInitFailed = 5
} MNXDownloadOperationErrorCode;
