#import <Foundation/Foundation.h>
#import "MNXDownloadOperation.h"
#import "MNXDataParser.h"
#import "MNXPoint.h"
#import "MNXTrack.h"
#import "AMSerialPort.h"

@class MNXDataManager;

@protocol MNXDataManagerDelegate <NSObject>;

- (void)dataManagerDidStartDownloadingData:(MNXDataManager *)inManager;
- (void)dataManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress;
- (void)dataManagerDidFinishDownloadingData:(MNXDataManager *)inManager;
- (void)dataManagerDidStartParsingData:(MNXDataManager *)inManager;
- (void)dataManager:(MNXDataManager *)inManager didFinishParsingData:(NSArray *)inTracks;
- (void)dataManagerCancelled:(MNXDataManager *)inManager;
- (void)dataManagerDidStartPurgineData:(MNXDataManager *)inManager;
- (void)dataManagerDidFinishPurgineData:(MNXDataManager *)inManager;
- (void)dataManager:(MNXDataManager *)inManager didFaileWithError:(NSError *)inError;
- (void)dataManagerUpdated:(MNXDataManager *)inManager;
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
	
	NSUndoManager *undoManager;
}

- (void)downloadDataFromPort:(AMSerialPort *)inPort;
- (void)cancelDownload;

- (void)purgeDataWithPort:(AMSerialPort *)inPort;

- (NSString *)tempFilePathWithExtension:(NSString *)ext;
- (NSString *)savedDataPath;
- (void)saveData;
- (void)loadSavedData;
- (void)appendTracks:(NSArray *)inTracks;
- (void)deleteTrack:(MNXTrack *)inTrack;
- (NSData *)GPXData;
- (NSData *)KMLData;
- (NSData *)TCXData;

@property (assign, nonatomic) id <MNXDataManagerDelegate> delegate;
@property (readonly) NSArray *tracks;

@property (readonly) NSTimeInterval totalDuration;
@property (readonly) CGFloat totalDistanceKM;
@property (readonly) CGFloat totalDistanceMile;
@property (readonly) NSTimeInterval averagePaceKM;
@property (readonly) NSTimeInterval averagePaceMile;
@property (readonly) CGFloat averageSpeedKM;
@property (readonly) CGFloat averageSpeedMile;
@property (assign) NSUndoManager *undoManager;

@end
