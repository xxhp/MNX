#import <Foundation/Foundation.h>
#import "MNXDownloadOperation.h"
#import "MNXDataParser.h"
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
- (void)downloadManagerCancelled:(MNXDataManager *)inManager;
- (void)downloadManager:(MNXDataManager *)inManager didFaileWithError:(NSError *)inError;

@end

@interface MNXDataManager : NSObject <MNXDownloadOperationDelegate, MNXDataParserDelegate>
{
	id <MNXDataManagerDelegate> delegate;
	NSMutableArray *tracks;
	NSOperationQueue *operationQueue;
	MNXDataParser *dataParser;
	
	NSTimeInterval totalDuration;
	CGFloat totalDistanceKM;
	CGFloat totalDistanceMile;
	NSTimeInterval averagePaceKM;
	NSTimeInterval averagePaceMile;
	CGFloat averageSpeedKM;
	CGFloat averageSpeedMile;
}

- (void)downloadDataFromPort:(AMSerialPort *)inPort;
- (void)cancelDownload;
- (NSString *)tempFilePathWithExtension:(NSString *)ext;
- (NSString *)savedDataPath;
- (void)saveData;
- (void)loadSavedData;

@property (assign, nonatomic) id <MNXDataManagerDelegate> delegate;
@property (readonly) NSArray *tracks;

@property (readonly) NSTimeInterval totalDuration;
@property (readonly) CGFloat totalDistanceKM;
@property (readonly) CGFloat totalDistanceMile;
@property (readonly) NSTimeInterval averagePaceKM;
@property (readonly) NSTimeInterval averagePaceMile;
@property (readonly) CGFloat averageSpeedKM;
@property (readonly) CGFloat averageSpeedMile;


@end
