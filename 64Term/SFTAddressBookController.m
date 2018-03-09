/*
 * Copyright 2017-2018 Alessandro Gatti - frob.it
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "SFTAddressBookController.h"
#import "SFTAddressBookEntry+CoreDataClass.h"
#import "SFTAddressBookSerialiser.h"
#import "SFTDataController.h"
#import "SFTDataToImageTransformer.h"
#import "SFTDocument.h"
#import "SFTQuickConnectWindowController.h"

typedef NS_ENUM(NSUInteger, SFTActionSegmentIndex) {
  SFTActionSegmentIndexAdd = 0,
  SFTActionSegmentIndexRemove,
  SFTActionSegmentIndexImportExport
};

@interface SFTAddressBookWindowController () <NSWindowDelegate, NSMenuDelegate,
                                              NSTableViewDelegate>

@property(weak) IBOutlet NSTableView *entriesList;
@property(strong) IBOutlet NSMenu *actionButtonContextMenu;
@property(strong) IBOutlet NSArrayController *entriesArrayController;
@property(weak) IBOutlet NSSegmentedControl *actionSegmentedControl;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic, nonnull)
    SFTQuickConnectWindowController *quickConnectWindowController;
@property(strong, nonatomic, nonnull)
    NSArray<NSSortDescriptor *> *sortDescriptors;

- (void)arrayControllerDidChangeNotification:
    (nonnull NSNotification *)notification;
- (void)initiateConnectionToEntry:(SFTAddressBookEntry *)entry;

- (IBAction)actionRequested:(id)sender;
- (IBAction)doubleActionOnRow:(id)sender;
- (IBAction)importAddressBookEntries:(id)sender;
- (IBAction)exportAddressBookEntries:(id)sender;
- (IBAction)quickConnect:(id)sender;

@end

@implementation SFTAddressBookWindowController

+ (void)initialize {
  [NSValueTransformer setValueTransformer:[SFTDataToImageTransformer new]
                                  forName:SFTDataToImageTransformerName];
}

- (void)awakeFromNib {
  self.sortDescriptors =
      @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
}

- (void)windowDidLoad {
  [super windowDidLoad];

  self.quickConnectWindowController = [[SFTQuickConnectWindowController alloc]
      initWithWindowNibName:@"QuickConnect"];

  self.managedObjectContext =
      SFTDataController.sharedInstance.persistentContainer.viewContext;

  [NSNotificationCenter.defaultCenter
      addObserver:self
         selector:@selector(arrayControllerDidChangeNotification:)
             name:NSManagedObjectContextObjectsDidChangeNotification
           object:nil];

  [self.actionSegmentedControl
      setEnabled:[self.entriesArrayController.arrangedObjects count] > 0
      forSegment:SFTActionSegmentIndexRemove];
}

- (void)windowWillClose:(NSNotification *__unused)notification {
  [NSNotificationCenter.defaultCenter
      removeObserver:self
                name:NSManagedObjectContextObjectsDidChangeNotification
              object:nil];
}

- (void)arrayControllerDidChangeNotification:
    (nonnull NSNotification *)notification {
  NSManagedObjectContext *savedContext =
      (NSManagedObjectContext *)notification.object;

  if (savedContext != self.managedObjectContext) {
    return;
  }

  [self.actionSegmentedControl
      setEnabled:[self.entriesArrayController.arrangedObjects count] > 0
      forSegment:SFTActionSegmentIndexRemove];
}

- (IBAction)actionRequested:(id)sender {
  switch (self.actionSegmentedControl.selectedSegment) {
  case SFTActionSegmentIndexAdd:
    [self.entriesArrayController add:sender];
    break;

  case SFTActionSegmentIndexRemove:
    [self.entriesArrayController remove:sender];
    break;

  case SFTActionSegmentIndexImportExport:
    // @TODO: Move NSEvent.mouseLocation elsewhere to not cover the button.
    [self.actionButtonContextMenu popUpMenuPositioningItem:nil
                                                atLocation:NSEvent.mouseLocation
                                                    inView:nil];
    break;

  default:
    break;
  }
}

- (void)initiateConnectionToEntry:(SFTAddressBookEntry *)entry {
  NSError *error;
  SFTDocument *document =
      [[SFTDocument alloc] initWithEntry:entry error:&error];
  if (error == nil) {
    [NSDocumentController.sharedDocumentController addDocument:document];
    [document makeWindowControllers];
    [document showWindows];
  } else {
    [[NSAlert alertWithError:error]
        beginSheetModalForWindow:self.window
               completionHandler:^(NSModalResponse returnCode){
               }];
  }
}

- (IBAction)doubleActionOnRow:(id)sender {
  NSAssert([sender isKindOfClass:NSTableView.class],
           @"Double click event from outside the table view?");

  NSTableView *tableView = (NSTableView *)sender;
  NSInteger clickedRow = tableView.clickedRow;
  if (clickedRow < 0) {
    return;
  }

  NSAssert([(self.entriesArrayController.arrangedObjects)[clickedRow]
               isKindOfClass:SFTAddressBookEntry.class],
           @"Invalid object class type!");

  SFTAddressBookEntry *entry =
      (self.entriesArrayController.arrangedObjects)[clickedRow];
  [self initiateConnectionToEntry:entry];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
  return SFTDataController.sharedInstance.persistentContainer.viewContext
      .undoManager;
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
  NSAssert(sender == self.window, @"Got a close request for the wrong window");

  if (![self.managedObjectContext commitEditing]) {
    NSLog(@"%@:%@ unable to commit editing before saving", self.class,
          NSStringFromSelector(_cmd));
  }

  NSError *error = nil;
  if (self.managedObjectContext.hasChanges &&
      ![self.managedObjectContext save:&error]) {
    [NSApp presentError:error];
  }

  return YES;
}

- (IBAction)connectToSelectedBBS:(id)sender {
  NSArray *selection = self.entriesArrayController.selectedObjects;

  if (selection.count != 1) {
    return;
  }

  NSAssert([selection[0] isKindOfClass:SFTAddressBookEntry.class],
           @"Selection is not an address book entry!");

  SFTAddressBookEntry *entry = (SFTAddressBookEntry *)selection[0];
  [self initiateConnectionToEntry:entry];
}

- (IBAction)importAddressBookEntries:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = NO;
  panel.canResolveUbiquitousConflicts = NO;

  __weak SFTAddressBookWindowController *weakSelf = self;

  [panel
      beginSheetModalForWindow:self.window
             completionHandler:^(NSModalResponse result) {
               SFTAddressBookWindowController *strongSelf = weakSelf;
               if (result != NSModalResponseOK) {
                 return;
               }

               [panel close];

               NSError *error;
               NSMutableData *data = [NSMutableData
                   dataWithContentsOfURL:panel.URL
                                 options:NSDataReadingMappedIfSafe
                                   error:&error];
               if (data == nil) {
                 [[NSAlert alertWithError:error]
                     beginSheetModalForWindow:strongSelf.window
                            completionHandler:^(NSModalResponse returnCode){
                            }];
                 return;
               }

               NSFetchRequest *fetchRequest = [NSFetchRequest
                   fetchRequestWithEntityName:@"SFTAddressBookEntry"];
               NSArray *items = [strongSelf.managedObjectContext
                   executeFetchRequest:fetchRequest
                                 error:&error];
               if (error != nil) {
                 [[NSAlert alertWithError:error]
                     beginSheetModalForWindow:strongSelf.window
                            completionHandler:^(NSModalResponse returnCode){
                            }];
                 return;
               }

               NSManagedObjectContext *context = [[NSManagedObjectContext alloc]
                   initWithConcurrencyType:NSPrivateQueueConcurrencyType];
               context.parentContext = strongSelf.managedObjectContext;
               context.undoManager = [NSUndoManager new];
               [context.undoManager beginUndoGrouping];

               for (id item in items) {
                 [strongSelf.managedObjectContext deleteObject:item];
               }

               BOOL deserialised = [SFTAddressBookSerialiser
                   deserialise:strongSelf.managedObjectContext
                      fromData:data
                     withError:&error];

               [context.undoManager endUndoGrouping];

               if (deserialised == NO) {
                 [context.undoManager undo];
                 [[NSAlert alertWithError:error]
                     beginSheetModalForWindow:strongSelf.window
                            completionHandler:^(NSModalResponse returnCode){
                            }];
               }
             }];
}

- (IBAction)exportAddressBookEntries:(id)sender {
  NSError *error;
  NSMutableData *addressBookData = [NSMutableData new];
  BOOL serialised =
      [SFTAddressBookSerialiser serialise:self.managedObjectContext
                                 intoData:addressBookData
                                withError:&error];
  if (serialised == NO) {
    NSLog(@"Unable to fetch elements from the managed object context: %@",
          error.description);
    [[NSAlert alertWithError:error]
        beginSheetModalForWindow:self.window
               completionHandler:^(NSModalResponse returnCode){
               }];
    return;
  }

  NSSavePanel *panel = [NSSavePanel savePanel];

  __weak SFTAddressBookWindowController *weakSelf = self;
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSModalResponse result) {
                  SFTAddressBookWindowController *strongSelf = weakSelf;

                  if (result != NSModalResponseOK) {
                    return;
                  }

                  [panel close];

                  NSError *error;
                  [addressBookData writeToURL:panel.URL
                                      options:NSDataWritingAtomic
                                        error:&error];
                  if (error != nil) {
                    [[NSAlert alertWithError:error]
                        beginSheetModalForWindow:strongSelf.window
                               completionHandler:^(NSModalResponse returnCode){
                               }];
                  }
                }];
}

- (IBAction)quickConnect:(id)sender {
  __weak SFTAddressBookWindowController *weakSelf = self;
  [self.window
             beginSheet:self.quickConnectWindowController.window
      completionHandler:^(NSModalResponse returnCode) {
        SFTAddressBookWindowController *strongSelf = weakSelf;

        if (returnCode != NSModalResponseOK) {
          return;
        }

        NSError *error = nil;
        SFTDocument *document = [[SFTDocument alloc]
            initWithAddress:strongSelf.quickConnectWindowController.url
                      error:&error];
        if (error == nil) {
          [NSDocumentController.sharedDocumentController addDocument:document];
          [document makeWindowControllers];
          [document showWindows];
        } else {
          [[NSAlert alertWithError:error]
              beginSheetModalForWindow:strongSelf.window
                     completionHandler:^(NSModalResponse returnCode){
                     }];
        }
      }];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
  return;
}

- (BOOL)menu:(NSMenu *)menu
      updateItem:(NSMenuItem *)item
         atIndex:(NSInteger)index
    shouldCancel:(BOOL)shouldCancel {
  return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *__unused)notification {
  [self.actionSegmentedControl setEnabled:(self.entriesList.selectedRow != -1)
                               forSegment:SFTActionSegmentIndexRemove];
}

@end
