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

#import "SFTApplicationDelegate.h"
#import "NSWindowController+Toggle.h"
#import "SFTAddressBookController.h"
#import "SFTDataController.h"
#import "SFTDataFlowInspectorWindowController.h"
#import "SFTDebugInspectorWindowController.h"

@interface SFTApplicationDelegate ()

@property(strong, nonatomic, nonnull)
    SFTAddressBookWindowController *addressBookController;

@property(strong, nonatomic, nonnull)
    SFTDebugInspectorWindowController *keypressInspectorController;

@property(strong, nonatomic, nonnull)
    SFTDataFlowInspectorWindowController *dataFlowInspectorController;
@end

@implementation SFTApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  self.addressBookController = [[SFTAddressBookWindowController alloc]
      initWithWindowNibName:@"AddressBook"];
  self.keypressInspectorController =
      SFTDebugInspectorWindowController.sharedInstance;
  self.dataFlowInspectorController =
      SFTDataFlowInspectorWindowController.sharedInstance;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.addressBookController showWindow:self];
  self.keypressInspectorController.shouldCascadeWindows = NO;
  self.dataFlowInspectorController.shouldCascadeWindows = NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:
    (NSApplication *)sender {
  NSManagedObjectContext *context =
      SFTDataController.sharedInstance.persistentContainer.viewContext;

  if (![context commitEditing]) {
    NSLog(@"%@:%@ unable to commit editing to terminate", self.class,
          NSStringFromSelector(_cmd));
    return NSTerminateCancel;
  }

  if (!context.hasChanges) {
    return NSTerminateNow;
  }

  NSError *error = nil;
  if (![context save:&error]) {
    BOOL result = [sender presentError:error];
    if (result) {
      return NSTerminateCancel;
    }

    NSString *question = NSLocalizedString(
        @"Could not save changes while quitting. Quit anyway?",
        @"Quit without saves error question message");
    NSString *info =
        NSLocalizedString(@"Quitting now will lose any changes you have made "
                          @"since the last successful save",
                          @"Quit without saves error question info");
    NSString *quitButton =
        NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
    NSString *cancelButton =
        NSLocalizedString(@"Cancel", @"Cancel button title");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = question;
    alert.informativeText = info;
    [alert addButtonWithTitle:quitButton];
    [alert addButtonWithTitle:cancelButton];

    NSInteger answer = [alert runModal];

    if (answer == NSAlertSecondButtonReturn) {
      return NSTerminateCancel;
    }
  }

  return NSTerminateNow;
}

- (IBAction)toggleKeypressInspector:(id)sender {
  [self.keypressInspectorController toggleVisibility];
}

- (IBAction)toggleDataFlowInspector:(id)sender {
  [self.dataFlowInspectorController toggleVisibility];
}

@end
