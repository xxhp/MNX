#import "MNXSpeedView.h"

@interface MNXSpeedView (Private)
- (CGFloat)frameWidth;
- (NSRect)drawingFrame;
@end

@implementation MNXSpeedView (Private)
- (CGFloat)frameWidth
{
	return 50.0;
}
- (NSRect)drawingFrame
{
	CGFloat frameWidth = [self frameWidth];
	NSRect drawingFrame = CGRectMake(frameWidth, frameWidth, [self bounds].size.width - (frameWidth * 2) , [self bounds].size.height - (frameWidth * 2));
	return drawingFrame;
}
@end

@implementation MNXSpeedView

- (void) dealloc
{
	[currentTrack release];
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		currentTrack = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:[self bounds]];
	
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:12.0] forKey:NSFontAttributeName];
	[attr setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setAlignment:NSRightTextAlignment];
	[attr setObject:style forKey:NSParagraphStyleAttributeName];	
	
	if ([self bounds].size.width < 100.0) {
		return;
	}
	
	if ([self bounds].size.height < 100.0) {
		return;
	}
	
	CGFloat frameWidth = [self frameWidth];
	NSRect drawingFrame = [self drawingFrame];
	
	NSBezierPath *border = [NSBezierPath bezierPath];
	[border moveToPoint:NSMakePoint(NSMinX(drawingFrame), NSMaxY(drawingFrame))];
	[border lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[border lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[[NSColor grayColor] setStroke];
	[border stroke];
	
	CGRect zeroFrame = CGRectMake(0.0, NSMinY(drawingFrame) - 20.0, frameWidth - 10.0, 13.0);
	[@"0" drawInRect:zeroFrame withAttributes:attr];

	CGRect speedUnitFrame = CGRectMake(0.0, NSMaxY(drawingFrame) + 20.0, frameWidth, 13.0);
	[@"Km/H" drawInRect:speedUnitFrame withAttributes:attr];

	[style setAlignment:NSLeftTextAlignment];
	
	CGRect distanceUnitFrame = CGRectMake(NSMaxX(drawingFrame) + 10.0, NSMinY(drawingFrame) - 5.0, frameWidth, 13.0);
	[@"Km" drawInRect:distanceUnitFrame withAttributes:attr];	
	
	if ([self.currentTrack.points count] < 2) {
		return;
	}
	
	[style setAlignment:NSRightTextAlignment];
	
	CGFloat maxSpeed = 0.0;	
	NSInteger maxPointCount = 100.0;
	NSMutableArray *a = [NSMutableArray array];
	NSInteger pointPerSection = (NSInteger)([self.currentTrack.points count] / maxPointCount);
	NSUInteger count = 0;
	CGFloat aSpeed = 0.0;
	
	for (MNXPoint *point in self.currentTrack.points) {
		if (point == [self.currentTrack.points objectAtIndex:0]) {
			CGFloat speed = (point.speedKM > 0.0) ? point.speedKM : 0.0;
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			maxSpeed = speed;
			[a addObject:p];
		}
		else {
			CGFloat speed = 0.0;
			if (count < pointPerSection) {
				if (point.speedKM > 0.0) {
					aSpeed += point.speedKM;
				}
				count++;
				continue;
			}
			else {
				speed = aSpeed / count;
				count = 0;
				aSpeed = 0.0;
			}
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			if (speed > maxSpeed) {
				maxSpeed = speed;
			}
			[a addObject:p];
		}
	}
	
	if (maxSpeed < 5.0) {
		maxSpeed = 5.0;
	}
	else {
		maxSpeed = maxSpeed * 1.25;
	}
	
	NSInteger speedInterval = maxSpeed / 5;

	if (speedInterval < 1) {
		speedInterval = 1;
	}
	else if (speedInterval > 20 && (speedInterval % 20)) {
		speedInterval = speedInterval + (10 - (speedInterval % 10));
	}	
	else if (speedInterval > 10 && (speedInterval % 5)) {
		speedInterval = speedInterval + (5 - (speedInterval % 5));
	}	
	else if (speedInterval > 5 && (speedInterval % 5)) {
		speedInterval = speedInterval + (5 - (speedInterval % 5));
	}
	else if (speedInterval > 3 && speedInterval < 5) {
		speedInterval = 5;
	}
	
	
	NSInteger distanceInterval = (NSInteger)(self.currentTrack.totalDistance / 5.0);

	if (distanceInterval > 20 && (distanceInterval % 20)) {
		distanceInterval = distanceInterval + (10 - (distanceInterval % 10));
	}	
	else if (distanceInterval > 10 && (distanceInterval % 10)) {
		distanceInterval = distanceInterval + (5 - (distanceInterval % 5));
	}	
	else if (distanceInterval > 5 && (distanceInterval % 5)) {
		distanceInterval = distanceInterval + (5 - (distanceInterval % 5));
	}
	else if (distanceInterval > 3 && distanceInterval < 5) {
		distanceInterval = 5;
	}	
		
	for (NSUInteger i = 1; (CGFloat)(i * speedInterval) < maxSpeed ; i++) {
		NSBezierPath *intervalLine = [NSBezierPath bezierPath];		
		CGFloat y = (CGFloat)(i * speedInterval) / maxSpeed * drawingFrame.size.height + NSMinY(drawingFrame);
		
		CGRect labelFrame = CGRectMake(0.0, y - 5.0, frameWidth - 10.0, 13.0);
		NSString *labelText = [NSString stringWithFormat:@"%d", (i * speedInterval)];
		[labelText drawInRect:labelFrame withAttributes:attr];
		
		[intervalLine moveToPoint:NSMakePoint(NSMinX(drawingFrame),  y)];
		[intervalLine lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		CGFloat dash[2] = {5.0, 2.0};
		[intervalLine setLineDash:dash count:2 phase:0.0];
		[[NSColor grayColor] setStroke];
		[intervalLine stroke];
	}
		
	[style setAlignment:NSCenterTextAlignment];
	
	if (distanceInterval) {
		for (NSUInteger i = 1; (CGFloat)(i * distanceInterval) < self.currentTrack.totalDistance  ; i++) {
			CGFloat x = (CGFloat)(i * distanceInterval) / self.currentTrack.totalDistance * drawingFrame.size.width + NSMinX(drawingFrame);
			NSBezierPath *intervalLine = [NSBezierPath bezierPath];
			[intervalLine moveToPoint:NSMakePoint(x, NSMinY(drawingFrame) - 5.0)];
			[intervalLine lineToPoint:NSMakePoint(x, NSMinY(drawingFrame) + 10.0)];
			[[NSColor blackColor] setStroke];
			[intervalLine stroke];

			CGRect labelFrame = CGRectMake(x - (frameWidth / 2.0), NSMinY(drawingFrame) - 20.0, frameWidth, 13.0);
			NSString *labelText = [NSString stringWithFormat:@"%d", (i * distanceInterval)];
			[labelText drawInRect:labelFrame withAttributes:attr];
			
		}
	}
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistance) * drawingFrame.size.width;
		CGFloat y = frameWidth + [[p objectForKey:@"speed"] floatValue] / maxSpeed * drawingFrame.size.height;
		if (p == [a objectAtIndex:0]) {
			[path moveToPoint:NSMakePoint(x, y)];
		}
		else {
			[path lineToPoint:NSMakePoint(x, y)];
		}
		if (p == [a lastObject]) {
			[path lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		}
	}
			 
	
	NSColor *lineColor = [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:1.0];
	NSColor *backgroundColor = [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:0.6];
	
	NSBezierPath *backgroundPath = [[path copy] autorelease];
	[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath closePath];
	[backgroundColor setFill];
	[backgroundPath fill];
	
	[lineColor setStroke];
	[path setLineWidth:5.0];
	[path stroke];
}

- (void)setCurrentTrack:(MNXTrack *)inTrack
{
	id tmp = currentTrack;
	currentTrack = [inTrack retain];
	[tmp release];
	[self setNeedsDisplay:YES];
}

- (MNXTrack *)currentTrack
{
	return currentTrack;
}

@end

