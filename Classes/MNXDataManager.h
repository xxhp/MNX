#import <Foundation/Foundation.h>
#import "MNXDownloadOperation.h"
#import "MNXPoint.h"
#import "MNXTrack.h"
#import "AMSerialPort.h"

@class MNXDataManager;

@protocol MNXDataManagerDelegate <NSObject>;

- (void)downloadManagerDidStartDownloadingData:(MNXDataManager *)inManager;
- (void)downloadManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress;
- (void)downloadManagerDidFinishDownloadingData:(MNXDataManager *)inManager;
- (void)downloadManagerDidStartParsingData:(MNXDataManager *)inManager;
- (void)downloadManager:(MNXDataManager *)inManager didFinishParsingData:(NSArray *)inTracks;
- (void)downloadManagerCanceled:(MNXDataManager *)inManager;
- (void)downloadManager:(MNXDataManager *)inManager didFailedWithMessage:(NSString *)message;

@end

@interface MNXDataManager : NSObject <MNXDownloadOperationDelegate>
{
	id <MNXDataManagerDelegate> delegate;
	NSMutableArray *tracks;
	NSOperationQueue *operationQueue;
}

- (void)downloadDataFromPort:(AMSerialPort *)inPort;

@property (assign, nonatomic) id <MNXDataManagerDelegate> delegate;
@property (readonly) NSArray *tracks;

@end
