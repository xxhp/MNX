#import "MNXDownloadOperation.h"
#import "AMSerialPortAdditions.h"
#import "MNXPoint.h"
#import "MNXTrack.h"

NSString *const MNXDownloadOperationErrorDomain = @"MNXDownloadOperationErrorDomain";

static NSString *const kInitDownloadMainnavMG950DCommand=@"$1\r\n";
static NSString *const kInitDownloadQstartBTQ2000Command=@"$9\r\n";
static NSString *const kPurgeLogCommand = @"$2\r\n";
static NSString *const kCheckStatusCommand = @"$3\r\n";

static unichar kDwonloadChunkFirst = 0x15; //NAK
static unichar kDownloadChunkNext = 0x06; //ACK
static unichar kDownloadAbort = 0x18; // CAN
static unichar kInitStandard[2] = {0x0f, 0x06};

static NSString *const kOK = @"$OK!";
static NSString *const kFinish = @"$FINISH";
static NSString *const kAborted = @"\x06\x06\x06\x06";

@implementation MNXDownloadOperation

- (void)dealloc
{
	delegate = nil;
	[port release];
	[super dealloc];
}


- (NSData *)_communicate:(NSString *)command
{
	[port writeString:command usingEncoding:NSUTF8StringEncoding error:NULL];
	NSError *e = nil;
	NSData *d = [port readAndReturnError:&e];
	return d;
}

#pragma mark -

- (NSInteger)checkLogSizeWithError:(out NSInteger *)outErrorCode
{
	[port setSpeed:115200];
	[port setDataBits:8];
	[port setParity:kAMSerialParityNone];
	[port setStopBits:kAMSerialStopBitsOne];	
	[port setReadTimeout:0.3];
	
	NSInteger logSize = 0;
	if ([port isOpen]) {
		[port free];
	}
	if (![port open]) {
		*outErrorCode = MNXDownloadOperationUnableToOpenDevice;
		return 0;
	}
	
	if ([port isOpen]) {
		NSData *d = [self _communicate:kCheckStatusCommand];
		NSString *r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
		if (![r hasPrefix:kOK]) {
			*outErrorCode = MNXDownloadOperationUnableToOpenDevice;
			return 0;
		}
		Byte p[4];
		[d getBytes:&p range:NSMakeRange([d length] - 4, 4)];
		logSize = (p[0] << 24) + (p[1] << 16) + (p[2] << 8) + (p[3] << 0);
	}
	else {
		*outErrorCode = MNXDownloadOperationUnableToOpenDevice;
	}
	if (logSize <= 8192) {
		*outErrorCode = MNXDownloadOperationNoDataOnDevice;
	}
	return logSize;
}

- (NSData *)downloadDataWithError:(out NSInteger *)outErrorCode logSize:(out NSInteger *)outLogSize
{
	[delegate downloadOperationDidStartDownloadingData:self];
	NSInteger logSize = [self checkLogSizeWithError:outErrorCode];
	if (*outErrorCode != MNXDownloadOperationNoError) {
		return nil;
	}

	NSData *d = [self _communicate:kInitDownloadMainnavMG950DCommand];
	NSString *r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	if (![r hasPrefix:kOK]) {
		d = [self _communicate:kInitDownloadQstartBTQ2000Command];
		r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	}
	if (![r hasPrefix:kOK]) {
		*outErrorCode = MNXDownloadOperationInitFailed;
		return nil;
	}
	
	NSMutableData *data = [NSMutableData data];
	
	NSString *NAK = [NSString stringWithCharacters:&kDwonloadChunkFirst length:1];
	NSString *ACK = [NSString stringWithCharacters:&kDownloadChunkNext length:1];
	NSString *CAN = [NSString stringWithCharacters:&kDownloadAbort length:1];
	NSString *initStandard = [NSString stringWithCharacters:kInitStandard length:2];
	
	NSError *e = nil;
	[port writeString:NAK usingEncoding:NSUTF8StringEncoding error:NULL];	
	while ([data length] < logSize && ![self isCancelled]) {
		NSData *d = [port readBytes:132 error:&e];
		if ([d length] < 132) {
			[port writeString:CAN usingEncoding:NSUTF8StringEncoding error:&e];
			[port writeString:initStandard usingEncoding:NSUTF8StringEncoding error:&e];
			*outErrorCode = MNXDownloadOperationDataTransferError;
			return nil;
		}
		
		NSInteger *p = malloc([d length] - 4);
		[d getBytes:p range:NSMakeRange(3, [d length] - 4)];
		NSData *a = [NSData dataWithBytes:p length:[d length] - 4];
		[delegate downloadOperation:self didDownloadData:(CGFloat)[data length] / (CGFloat)logSize];
		[data appendData:a];
		[port writeString:ACK usingEncoding:NSUTF8StringEncoding error:&e];
	}
	if ([self isCancelled]) {
		[port writeString:CAN usingEncoding:NSUTF8StringEncoding error:&e];
		[port writeString:initStandard usingEncoding:NSUTF8StringEncoding error:&e];
		return nil;
	}

	[port writeString:initStandard usingEncoding:NSUTF8StringEncoding error:&e];
	*outLogSize = logSize;
	return data;
}

- (void)purgeDataWithError:(out NSInteger *)outErrorCode logSize:(out NSInteger *)outLogSize
{
	[delegate downloadOperationDidStartPurgingData:self];
	[self checkLogSizeWithError:outErrorCode];
	if (*outErrorCode != MNXDownloadOperationNoError) {
		return;
	}
	
	[port setReadTimeout:1.0];
	NSData *d = [self _communicate:kPurgeLogCommand];
	NSString *r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	while (![r hasPrefix:kFinish] && ![self isCancelled]) {
		NSError *e = nil;
		d = [port readAndReturnError:&e];
		r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
//		NSLog(@"r:%@", r);
//		if (![r hasPrefix:kOK]) {
//			*outErrorCode = MNXDownloadOperationFailToPurgeData;
//			break;
//		}
	}
}

#pragma mark -

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSInteger logSize = 0;
	NSInteger errorCode = MNXDownloadOperationNoError;
	if (action == MNXDownloadOperationActionDownload) {
		NSData *data = [self downloadDataWithError:&errorCode logSize:&logSize];
		if ([data length]) {
			[delegate downloadOperation:self didFinishDownloadingData:data logSize:logSize];
		}
	}
	else {
		[self purgeDataWithError:&errorCode logSize:&logSize];
		if (errorCode == MNXDownloadOperationNoError) {
			[delegate downloadOperationDidFinishPurgingData:self];
		}
	}
	if ([self isCancelled]) {
		[delegate downloadOperationCancelled:self];
	}	
	else if (errorCode) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		NSString *message = nil;
		NSString *reason = nil;
		switch (errorCode) {
			case MNXDownloadOperationUnknowError:
				message = NSLocalizedString(@"Unknow error happened.", @"MNXDownloadOperationUnknowError");
				reason = NSLocalizedString(@"Please  try again.", @"");
				break;
			case MNXDownloadOperationUnableToOpenDevice:
				message = NSLocalizedString(@"Unable to communicate with the device.", @"MNXDownloadOperationUnableToOpenDevice");
				reason = NSLocalizedString(@"The device might be turned off, or you are trying to downlaod data from a non-MainNav GPS device.", @"");
				break;
			case MNXDownloadOperationDataTransferError:
				message = NSLocalizedString(@"Unable to read data from the device.", @"MNXDownloadOperationDataTransferError");
				reason = NSLocalizedString(@"The connection between the device and your Mac is lost.", @"");
				break;
			case MNXDownloadOperationNoDataOnDevice:
				message = NSLocalizedString(@"There is no data stored on the device..", @"MNXDownloadOperationNoDataOnDevice");
				reason = NSLocalizedString(@"There is nothing to download.", @"");
				break;
			case MNXDownloadOperationInitFailed:
				message = NSLocalizedString(@"Unable to initiate the download.", @"MNXDownloadOperationNoDataOnDevice");
				reason = NSLocalizedString(@"The device might be turned off, or you are trying to downlaod data from a none MainNav GPS device.", @"");
				break;
			default:
				break;
		}
		if (message) {
			[userInfo setObject:message forKey:NSLocalizedDescriptionKey];
		}
		if (reason) {
			[userInfo setObject:reason forKey:NSLocalizedRecoverySuggestionErrorKey];
		}
		
		NSError *error = [NSError errorWithDomain:MNXDownloadOperationErrorDomain code:errorCode userInfo:userInfo];
		[delegate downloadOperation:self didFailWithError:error];
	}
	
	[pool drain];	
}

- (void)cancel
{
	[super cancel];
}

@synthesize delegate;
@synthesize port;
@synthesize action;

@end
