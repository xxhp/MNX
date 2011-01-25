#import <Foundation/Foundation.h>
#import "AMSerialPort.h"

@class MNXDownloadOperation;

@protocol MNXDownloadOperationDelegate

- (void)downloadOperationDidStartDownloadingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress;
- (void)downloadOperationDidFinishDownloadingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperationDidStartParsingData:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishParsingData:(NSArray *)inTracks;
- (void)downloadOperationCanceled:(MNXDownloadOperation *)inOperation;
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailedWithMessage:(NSString *)message;

@end


@interface MNXDownloadOperation : NSOperation
{
	id <MNXDownloadOperationDelegate> delegate;
	NSCalendar *calendar;
	AMSerialPort *port;
}

- (void)parseData:(NSData *)inData logSize:(NSUInteger)logSize;

@property (assign, nonatomic) id <MNXDownloadOperationDelegate> delegate;
@property (retain, nonatomic) AMSerialPort *port;

@end
