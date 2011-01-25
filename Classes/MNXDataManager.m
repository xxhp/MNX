#import "MNXDataManager.h"

@implementation MNXDataManager

- (void)dealloc
{
	[operationQueue release];
	[tracks release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		tracks = [[NSMutableArray alloc] init];
		operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue setName:@"Download Operation"];
		[operationQueue setMaxConcurrentOperationCount:1];
	}
	return self;
}

- (void)downloadDataFromPort:(AMSerialPort *)inPort
{
	if ([[operationQueue operations] count]) {
		return;
	}	
	MNXDownloadOperation *o = [[[MNXDownloadOperation alloc] init] autorelease];
	o.port = inPort;
	o.delegate = self;
	[operationQueue addOperation:o];
}

#pragma mark -

- (void)downloadOperationDidStartDownloadingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidStartDownloadingData:) withObject:self waitUntilDone:NO];
}
- (void)_didDownloadData:(NSNumber *)inProgress
{
	[delegate downloadManager:self didDownloadData:[inProgress floatValue]];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress
{
	[self performSelectorOnMainThread:@selector(_didDownloadData:) withObject:[NSNumber numberWithFloat:inProgress] waitUntilDone:NO];
}
- (void)downloadOperationDidFinishDownloadingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidFinishDownloadingData:) withObject:self waitUntilDone:NO];
}
- (void)downloadOperationDidStartParsingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidStartParsingData:) withObject:self waitUntilDone:NO];
}
- (void)_didFinishParsingData:(NSArray *)inTracks
{
	[delegate downloadManager:self didFinishParsingData:inTracks];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishParsingData:(NSArray *)inTracks
{
	[tracks setArray:inTracks];
	[self performSelectorOnMainThread:@selector(_didFinishParsingData:) withObject:inTracks waitUntilDone:NO];
}
- (void)downloadOperationCanceled:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidStartParsingData:) withObject:self waitUntilDone:NO];
}
- (void)_didFailedWithMessage:(NSString *)message
{
	[delegate downloadManager:self didFailedWithMessage:message];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailedWithMessage:(NSString *)message
{
	[self performSelectorOnMainThread:@selector(_didFailedWithMessage:) withObject:message waitUntilDone:NO];
}

#pragma mark -

- (NSArray *)tracks
{
	return [NSArray arrayWithArray:tracks];
}

@synthesize delegate;

@end
