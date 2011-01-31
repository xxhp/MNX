#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MNXDataManager.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "MNXSpeedView.h"
#import "MNXPreferenceController.h"
#import "MNXSelectionController.h"

@interface MNXAppDelegate : NSObject
	<NSApplicationDelegate,
	MNXDataManagerDelegate> 
{
	NSSplitView *mainSplitView;
	NSSplitView *contentSplitView;
	NSSplitView *sourceListSplitView;
	
	MNXDataManager *dataManager;
	MNXTrack *currentTrack;
	
	NSDateFormatter *dateFormatter;
    
	NSWindow *window;
	NSTableView *tracksTableView;
	NSTableView *pointsTableView;
	NSTableView *paceTableView;
	MNXSpeedView *speedView;
	WebView *webView;
	
	NSImageView *infoImageView;
	NSTextField *trackTotalDistanceLabel;
	NSTextField *trackDurationLabel;
	NSTextField *trackPaceLabel;
	NSTextField *trackSpeedLabel;
	
	NSTextField *totalDistanceLabel;
	NSTextField *totalDurationLabel;
	NSTextField *totalPaceLabel;
	NSTextField *totalSpeedLabel;
	
	NSButton *cancelButton;
	
	NSWindow *sheetWindow;
	NSTextField *messageLabel;
	NSProgressIndicator *progressIndicator;
	
	NSArrayController *portListArrayController;
	NSPopUpButton *portPopUpButton;	
	NSMenuItem *deviceListMenuItem;
	
	MNXPreferenceController *preferenceController;
	MNXSelectionController *selectionController;
	
	NSView *filetypeView;
	NSPopUpButton *filetypePopUpButton;
}

- (IBAction)download:(id)sender;
- (IBAction)cancelDownload:(id)sender;
- (IBAction)purgeData:(id)sender;
- (IBAction)selectDevice:(id)sender;
- (IBAction)deleteTrack:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)googleEarth:(id)sender;
- (IBAction)viewHTML:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)showPreference:(id)sender;
- (IBAction)changeExportFileType:(id)sender;
- (IBAction)openHomepage:(id)sender;
- (IBAction)feedback:(id)sender;

- (void)refresh;

#pragma mark -
#pragma mark Properties

@property (retain, nonatomic) MNXTrack *currentTrack;

@property (assign) IBOutlet NSSplitView *mainSplitView;
@property (assign) IBOutlet NSSplitView *contentSplitView;
@property (assign) IBOutlet NSSplitView *sourceListSplitView;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tracksTableView;
@property (assign) IBOutlet NSTableView *pointsTableView;
@property (assign) IBOutlet NSTableView *paceTableView;
@property (assign) IBOutlet MNXSpeedView *speedView;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSImageView *infoImageView;
@property (assign) IBOutlet NSTextField *trackTotalDistanceLabel;
@property (assign) IBOutlet NSTextField *trackDurationLabel;
@property (assign) IBOutlet NSTextField *trackPaceLabel;
@property (assign) IBOutlet NSTextField *trackSpeedLabel;
@property (assign) IBOutlet NSTextField *totalDistanceLabel;
@property (assign) IBOutlet NSTextField *totalDurationLabel;
@property (assign) IBOutlet NSTextField *totalPaceLabel;
@property (assign) IBOutlet NSTextField *totalSpeedLabel;
@property (assign) IBOutlet NSButton *cancelButton;

@property (assign) IBOutlet NSWindow *sheetWindow;
@property (assign) IBOutlet NSTextField *messageLabel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@property (assign) IBOutlet NSArrayController *portListArrayController;
@property (assign) IBOutlet NSPopUpButton *portPopUpButton;
@property (assign) IBOutlet NSMenuItem *deviceListMenuItem;

@property (assign) IBOutlet NSView *filetypeView;
@property (assign) IBOutlet NSPopUpButton *filetypePopUpButton;

@end

#pragma mark -

@interface MNXAppDelegate(TableView) <NSTableViewDataSource, NSTableViewDelegate>
@end
@interface MNXAppDelegate(Toolbar) <NSToolbarDelegate>
@end
@interface MNXAppDelegate(Web)
@end
@interface MNXAppDelegate(SplitView) <NSSplitViewDelegate>
@end
