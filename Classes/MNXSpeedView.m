#import "MNXSpeedView.h"
#import "NSLocale+MNXExtension.h"
#import "NSColor+MNXExtension.h"

static CGEventRef MyEventTapCallBack (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

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
	NSRect drawingFrame = NSMakeRect(frameWidth, frameWidth, [self bounds].size.width - (frameWidth * 2) , [self bounds].size.height - (frameWidth * 2));
	return drawingFrame;
}
@end

@implementation MNXSpeedView

- (void)dealloc
{
	if (source) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
		CFRelease(source);
		source = NULL;
	}
	
	if (eventTapPortRef) {
		CGEventTapEnable(eventTapPortRef, NO);
		CFRelease(eventTapPortRef);
		eventTapPortRef = NULL;
	}
	[currentTrack release];
	[infoWindow release];
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		currentTrack = nil;
		infoWindow = [[MNXTransparentWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 100.0, 100.0) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:nil];
    }
    return self;
}

- (void)drawWithMetricUnit
{
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:12.0] forKey:NSFontAttributeName];
	[attr setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setAlignment:NSRightTextAlignment];
	[attr setObject:style forKey:NSParagraphStyleAttributeName];	
	
	CGFloat frameWidth = [self frameWidth];
	NSRect drawingFrame = [self drawingFrame];
	
	NSRect zeroFrame = NSMakeRect(0.0, NSMinY(drawingFrame) - 20.0, frameWidth - 10.0, 13.0);
	[@"0" drawInRect:zeroFrame withAttributes:attr];
	
	NSRect speedUnitFrame = NSMakeRect(0.0, NSMaxY(drawingFrame) + 20.0, frameWidth, 13.0);
	[@"km/h" drawInRect:speedUnitFrame withAttributes:attr];
	
	if ([self.currentTrack.points count] < 2) {
		return;
	}
	if (!self.currentTrack.totalDistanceKM) {
		return;
	}
	
	[style setAlignment:NSRightTextAlignment];
	
	CGFloat maxSpeed = 0.0;
	CGFloat maxElevation = 0.0;
	CGFloat minElevation = 0.0;
	NSInteger maxPointCount = 200;
	NSMutableArray *a = [NSMutableArray array];
	NSInteger pointPerSection = (NSInteger)([self.currentTrack.points count] / maxPointCount);
	if (pointPerSection < 1) {
		pointPerSection = 1;
	}
	NSUInteger count = 0;
	CGFloat aSpeed = 0.0;
	CGFloat anElevation = 0.0;
	
	for (MNXPoint *point in self.currentTrack.points) {
		if (point == [self.currentTrack.points objectAtIndex:0]) {
			CGFloat speed = (point.speedKM > 0.0) ? point.speedKM : 0.0;
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			[p setObject:[NSNumber numberWithFloat:point.elevation] forKey:@"elevation"];
			maxSpeed = speed;
			minElevation = point.elevation;
			maxElevation = point.elevation;
			[a addObject:p];
		}
		else {
			CGFloat speed = 0.0;
			CGFloat elevation = 0.0;
			if (count < pointPerSection) {
				if (point.speedKM > 0.0) {
					aSpeed += point.speedKM;
				}
				anElevation += point.elevation;
				count++;
				continue;
			}
			else {
				speed = aSpeed / count;
				elevation = anElevation / count;
				count = 0;
				aSpeed = 0.0;
				anElevation = 0.0;
			}
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			[p setObject:[NSNumber numberWithFloat:elevation] forKey:@"elevation"];
			if (speed > maxSpeed) {
				maxSpeed = speed;
			}
			if (elevation > maxElevation) {
				maxElevation = elevation;
			}
			if (elevation < minElevation) {
				minElevation = elevation;
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
	currentMaxSpeedKM = maxSpeed;
	maxElevation += 10.0;
	minElevation -= 10.0;
	
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
	
	
	NSInteger distanceInterval = (NSInteger)(self.currentTrack.totalDistanceKM / 5.0);
	
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
		CGFloat y = (CGFloat)(i * speedInterval) / maxSpeed * drawingFrame.size.height + NSMinY(drawingFrame);
		
		NSRect labelFrame = NSMakeRect(0.0, y - 5.0, frameWidth - 10.0, 13.0);
		NSString *labelText = [NSString stringWithFormat:@"%d", (i * speedInterval)];
		[labelText drawInRect:labelFrame withAttributes:attr];

		NSBezierPath *intervalLine = [NSBezierPath bezierPath];		
		[intervalLine moveToPoint:NSMakePoint(NSMinX(drawingFrame),  y)];
		[intervalLine lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		CGFloat dash[2] = {5.0, 2.0};
		[intervalLine setLineDash:dash count:2 phase:0.0];
		[[NSColor grayColor] setStroke];
		[intervalLine stroke];
	}
	
	[style setAlignment:NSCenterTextAlignment];
	
	if (distanceInterval) {
		for (NSUInteger i = 1; (CGFloat)(i * distanceInterval) < self.currentTrack.totalDistanceKM  ; i++) {
			CGFloat x = (CGFloat)(i * distanceInterval) / self.currentTrack.totalDistanceKM * drawingFrame.size.width + NSMinX(drawingFrame);
			NSBezierPath *intervalLine = [NSBezierPath bezierPath];
			[intervalLine moveToPoint:NSMakePoint(x, NSMinY(drawingFrame) - 5.0)];
			[intervalLine lineToPoint:NSMakePoint(x, NSMinY(drawingFrame) + 10.0)];
			[[NSColor blackColor] setStroke];
			[intervalLine stroke];
			
			NSRect labelFrame = NSMakeRect(x - (frameWidth / 2.0), NSMinY(drawingFrame) - 20.0, frameWidth, 13.0);
			NSString *labelText = [NSString stringWithFormat:@"%d %@", (i * distanceInterval),  NSLocalizedString(@"km", @"")];
			[labelText drawInRect:labelFrame withAttributes:attr];
			
		}
	}
	else {
		NSRect labelFrame = NSMakeRect(NSMaxX(drawingFrame) - frameWidth, NSMinY(drawingFrame) - 20.0, frameWidth, 13.0);
		[style setAlignment:NSRightTextAlignment];
		NSString *labelText = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.totalDistanceKM, NSLocalizedString(@"km", @"")];
		[labelText drawInRect:labelFrame withAttributes:attr];		
	}
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistanceKM) * drawingFrame.size.width;
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
	
	NSBezierPath *elevationPath = [NSBezierPath bezierPath];
	[elevationPath setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistanceKM) * drawingFrame.size.width;
		CGFloat y = frameWidth + ([[p objectForKey:@"elevation"] floatValue] - minElevation) / (maxElevation - minElevation) * drawingFrame.size.height * 0.5;
		if (p == [a objectAtIndex:0]) {
			[elevationPath moveToPoint:NSMakePoint(x, y)];
		}
		else {
			[elevationPath lineToPoint:NSMakePoint(x, y)];
		}
		if (p == [a lastObject]) {
			[elevationPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		}
	}
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSBezierPath bezierPathWithRect:[self drawingFrame]] setClip];
	
	NSColor *lineColor = [NSColor speedLineColor];
	NSColor *backgroundColor = [NSColor speedBackgroundColorColor];

//	NSColor *elevationLineColor = [NSColor elevationLineColor];
//	NSColor *elevationBackgroundColor = [NSColor elevationBackgroundColorColor];

//	NSBezierPath *elevationBackgroundPath = [[elevationPath copy] autorelease];
//	[elevationBackgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
//	[elevationBackgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
//	[elevationBackgroundPath closePath];
//	[elevationBackgroundColor setFill];
//	[elevationBackgroundPath fill];	
	
	NSBezierPath *backgroundPath = [[path copy] autorelease];
	[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath closePath];
	[backgroundColor setFill];
	[backgroundPath fill];
	
//	[elevationLineColor setStroke];
//	[elevationPath setLineWidth:3.0];
//	[elevationPath stroke];
	
	[lineColor setStroke];
	[path setLineWidth:3.0];
	[path stroke];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)drawWithUSUnit
{
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:12.0] forKey:NSFontAttributeName];
	[attr setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setAlignment:NSRightTextAlignment];
	[attr setObject:style forKey:NSParagraphStyleAttributeName];		
	
	CGFloat frameWidth = [self frameWidth];
	NSRect drawingFrame = [self drawingFrame];
	
	NSRect zeroFrame = NSMakeRect(0.0, NSMinY(drawingFrame) - 20.0, frameWidth - 10.0, 13.0);
	[@"0" drawInRect:zeroFrame withAttributes:attr];
	
	NSRect speedUnitFrame = NSMakeRect(0.0, NSMaxY(drawingFrame) + 20.0, frameWidth, 13.0);
	[@"ml/h" drawInRect:speedUnitFrame withAttributes:attr];
	
	if ([self.currentTrack.points count] < 2) {
		return;
	}
	if (!self.currentTrack.totalDistanceMile) {
		return;
	}
	
	CGFloat maxSpeed = 0.0;	
	CGFloat maxElevation = 0.0;
	CGFloat minElevation = 0.0;
	NSInteger maxPointCount = 200;
	NSMutableArray *a = [NSMutableArray array];
	NSInteger pointPerSection = (NSInteger)([self.currentTrack.points count] / maxPointCount);
	if (pointPerSection < 1) {
		pointPerSection = 1;
	}	
	NSUInteger count = 0;
	CGFloat aSpeed = 0.0;
	CGFloat anElevation = 0.0;
	
	for (MNXPoint *point in self.currentTrack.points) {
		if (point == [self.currentTrack.points objectAtIndex:0]) {
			CGFloat speed = (point.speedMile > 0.0) ? point.speedMile : 0.0;
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceMile] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			maxSpeed = speed;
			minElevation = point.elevation;
			maxElevation = point.elevation;
			[a addObject:p];
		}
		else {
			CGFloat speed = 0.0;
			CGFloat elevation = 0.0;
			if (count < pointPerSection) {
				if (point.speedMile > 0.0) {
					aSpeed += point.speedMile;
				}
				anElevation += point.elevation;
				count++;
				continue;
			}
			else {
				speed = aSpeed / count;
				elevation = anElevation / count;
				count = 0;
				aSpeed = 0.0;
				anElevation = 0.0;
			}
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceMile] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			[p setObject:[NSNumber numberWithFloat:elevation] forKey:@"elevation"];
			if (speed > maxSpeed) {
				maxSpeed = speed;
			}
			if (elevation > maxElevation) {
				maxElevation = elevation;
			}
			if (elevation < minElevation) {
				minElevation = elevation;
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
	currentMaxSpeedMile = maxSpeed;
	maxElevation += 10.0;
	minElevation -= 10.0;
	
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
	
	
	NSInteger distanceInterval = (NSInteger)(self.currentTrack.totalDistanceMile / 5.0);
	
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
		CGFloat y = (CGFloat)(i * speedInterval) / maxSpeed * drawingFrame.size.height + NSMinY(drawingFrame);
		
		NSRect labelFrame = NSMakeRect(0.0, y - 5.0, frameWidth - 10.0, 13.0);
		NSString *labelText = [NSString stringWithFormat:@"%d", (i * speedInterval)];
		[labelText drawInRect:labelFrame withAttributes:attr];

		NSBezierPath *intervalLine = [NSBezierPath bezierPath];
		[intervalLine moveToPoint:NSMakePoint(NSMinX(drawingFrame),  y)];
		[intervalLine lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		CGFloat dash[2] = {5.0, 2.0};
		[intervalLine setLineDash:dash count:2 phase:0.0];
		[[NSColor grayColor] setStroke];
		[intervalLine stroke];
	}
	
	[style setAlignment:NSCenterTextAlignment];
	
	if (distanceInterval) {
		for (NSUInteger i = 1; (CGFloat)(i * distanceInterval) < self.currentTrack.totalDistanceMile  ; i++) {
			CGFloat x = (CGFloat)(i * distanceInterval) / self.currentTrack.totalDistanceMile * drawingFrame.size.width + NSMinX(drawingFrame);
			NSBezierPath *intervalLine = [NSBezierPath bezierPath];
			[intervalLine moveToPoint:NSMakePoint(x, NSMinY(drawingFrame) - 5.0)];
			[intervalLine lineToPoint:NSMakePoint(x, NSMinY(drawingFrame) + 10.0)];
			[[NSColor blackColor] setStroke];
			[intervalLine stroke];
			
			NSRect labelFrame = NSMakeRect(x - (frameWidth / 2.0), NSMinY(drawingFrame) - 20.0, frameWidth, 13.0);
			NSString *labelText = [NSString stringWithFormat:@"%d %@", (i * distanceInterval),  NSLocalizedString(@"ml", @"")];
			[labelText drawInRect:labelFrame withAttributes:attr];
			
		}
	}
	else {
		NSRect labelFrame = NSMakeRect(NSMaxX(drawingFrame) - frameWidth, NSMinY(drawingFrame) - 20.0, frameWidth, 13.0);
		[style setAlignment:NSRightTextAlignment];
		NSString *labelText = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.totalDistanceMile, NSLocalizedString(@"ml", @"")];
		[labelText drawInRect:labelFrame withAttributes:attr];
	}
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistanceMile) * drawingFrame.size.width;
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
	
	NSBezierPath *elevationPath = [NSBezierPath bezierPath];
	[elevationPath setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistanceMile) * drawingFrame.size.width;
		CGFloat y = frameWidth + ([[p objectForKey:@"elevation"] floatValue] - minElevation) / (maxElevation - minElevation) * drawingFrame.size.height * 0.5;
		if (p == [a objectAtIndex:0]) {
			[elevationPath moveToPoint:NSMakePoint(x, y)];
		}
		else {
			[elevationPath lineToPoint:NSMakePoint(x, y)];
		}
		if (p == [a lastObject]) {
			[elevationPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), y)];
		}
	}	
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSBezierPath bezierPathWithRect:[self drawingFrame]] setClip];
	
	NSColor *lineColor = [NSColor speedLineColor];
	NSColor *backgroundColor = [NSColor speedBackgroundColorColor];
	
//	NSColor *elevationLineColor = [NSColor elevationLineColor];
//	NSColor *elevationBackgroundColor = [NSColor elevationBackgroundColorColor];
	
//	NSBezierPath *elevationBackgroundPath = [[elevationPath copy] autorelease];
//	[elevationBackgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
//	[elevationBackgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
//	[elevationBackgroundPath closePath];
//	[elevationBackgroundColor setFill];
//	[elevationBackgroundPath fill];	
//	
	NSBezierPath *backgroundPath = [[path copy] autorelease];
	[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath closePath];
	[backgroundColor setFill];
	[backgroundPath fill];

//	[elevationLineColor setStroke];
//	[elevationPath setLineWidth:3.0];
//	[elevationPath stroke];
	
	[lineColor setStroke];
	[path setLineWidth:3.0];
	[path stroke];

	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:[self bounds]];
		
	if ([self bounds].size.width < 100.0) {
		return;
	}
	
	if ([self bounds].size.height < 100.0) {
		return;
	}
	
	NSRect drawingFrame = [self drawingFrame];
	
	NSBezierPath *border = [NSBezierPath bezierPath];
	[border moveToPoint:NSMakePoint(NSMinX(drawingFrame), NSMaxY(drawingFrame))];
	[border lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[border lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[border lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMaxY(drawingFrame))];
	[[NSColor grayColor] setStroke];
	[border stroke];
	
	if ([NSLocale usingUSMeasurementUnit]) {
		[self drawWithUSUnit];
	}
	else {
		[self drawWithMetricUnit];
	}
}

- (void)setCurrentTrack:(MNXTrack *)inTrack
{
	[self endTracking];
	id tmp = currentTrack;
	currentTrack = [inTrack retain];
	[tmp release];
	[self setNeedsDisplay:YES];

	if (currentTrack) {
		[self startTracking];
	}
}

- (MNXTrack *)currentTrack
{
	return currentTrack;
}

#pragma mark -

- (void)startTracking
{
	if (!eventTapPortRef) {
		eventTapPortRef = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, 0, CGEventMaskBit(kCGEventMouseMoved), MyEventTapCallBack, self);
	}
	if (!source) {
		source = CFMachPortCreateRunLoopSource(NULL, eventTapPortRef, 0);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
	}
	if (!CGEventTapIsEnabled(eventTapPortRef)) {
		CGEventTapEnable(eventTapPortRef, YES);
	}
}

- (void)endTracking
{
	if (eventTapPortRef) {
		CGEventTapEnable(eventTapPortRef, NO);
	}
}

- (MNXPoint *)pointFromPoint:(NSPoint)inPoint
{
	NSRect aFrame = [self drawingFrame];
	if (!NSPointInRect(inPoint, aFrame)) {
		return nil;
	}
	if ([self.currentTrack.points count] < 2) {
		return nil;
	}
	CGFloat distance = (inPoint.x - NSMinX(aFrame)) / aFrame.size.width * self.currentTrack.totalDistanceKM;
	MNXPoint *aPoint = nil;
	for (MNXPoint *enumPoint in self.currentTrack.points) {
		if (enumPoint.distanceKM >= distance) {
			aPoint = enumPoint;
			break;
		}
	}	
	return aPoint;
}

- (void)showInfoWindowWithPoint:(MNXPoint *)inPoint atLocation:(NSPoint)inLocation
{	
	inLocation = [self convertPoint:inLocation toView:nil];
	inLocation.y += 5.0;
	inLocation.x += [[self window] frame].origin.x;
	inLocation.y += [[self window] frame].origin.y;
	
	[infoWindow setPoint:inPoint];
	NSRect frame = [infoWindow frame];
	[infoWindow setFrameOrigin:NSMakePoint(inLocation.x - frame.size.width / 2.0, inLocation.y)];
	[[self window] addChildWindow:infoWindow ordered:NSWindowAbove];
	[infoWindow orderFront:self];
}

- (void)showInfoWindowWithEvent:(CGEventRef)inEvent
{
	if (CGEventGetType(inEvent) == kCGEventMouseMoved) {
		CGPoint p = CGEventGetLocation(inEvent);
		p.y = [[NSScreen mainScreen] frame].size.height - p.y;
		
		NSPoint np = NSPointFromCGPoint(p);
		NSPoint wp = [[self window] convertScreenToBase:np];
		NSPoint localPoint = [self convertPoint:wp fromView:nil];
		MNXPoint *point = [self pointFromPoint:localPoint];
		if (point) {
			[self showInfoWindowWithPoint:point atLocation:localPoint];
			return;
		}
		[[self window] removeChildWindow:infoWindow];
		[infoWindow orderOut:self];
	}	
}

@end


CGEventRef MyEventTapCallBack (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	MNXSpeedView *view = (MNXSpeedView *)refcon;
	[view showInfoWindowWithEvent:event];
	[pool drain];
	return event;
}
