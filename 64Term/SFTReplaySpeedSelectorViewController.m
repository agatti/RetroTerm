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

#import "SFTReplaySpeedSelectorViewController.h"

@interface SFTReplaySpeedSelectorViewController () <
    NSComboBoxDelegate, NSControlTextEditingDelegate>

@property(weak) IBOutlet NSComboBox *speedComboBox;

@end

@implementation SFTReplaySpeedSelectorViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.speedComboBox selectItemAtIndex:(NSInteger)SFTReplaySpeed300bps];
  self.replaySpeed = SFTReplaySpeed300bps;
  self.customBaudRate = 0;
}

- (void)comboBoxWillDismiss:(NSNotification *__unused)notification {
  if (self.speedComboBox.indexOfSelectedItem == -1) {
    self.replaySpeed = SFTReplaySpeedCustom;
  } else {
    self.replaySpeed = (NSUInteger)self.speedComboBox.indexOfSelectedItem;
  }
}

- (BOOL)control:(NSControl *)control
    textShouldEndEditing:(NSText *)fieldEditor {
  NSInteger baudRate = fieldEditor.string.integerValue;
  self.replaySpeed = SFTReplaySpeedCustom;
  self.customBaudRate = (NSUInteger)baudRate;
  if (baudRate == 0) {
    return NO;
  }

  fieldEditor.string = [NSString stringWithFormat:@"%lu bps", baudRate];

  return YES;
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
  return !((self.replaySpeed == SFTReplaySpeedCustom) &&
           (self.customBaudRate == 0));
}

+ (NSUInteger)bpsForSpeed:(SFTReplaySpeed)speed {
  switch (speed) {
  case SFTReplaySpeed300bps:
    return 300;

  case SFTReplaySpeed1200bps:
    return 1200;

  case SFTReplaySpeed2400bps:
    return 2400;

  case SFTReplaySpeed4800bps:
    return 4800;

  case SFTReplaySpeed9600bps:
    return 9600;

  case SFTReplaySpeed14400bps:
    return 14400;

  case SFTReplaySpeed19200bps:
    return 19200;

  case SFTReplaySpeed28800bps:
    return 28800;

  case SFTReplaySpeed33600bps:
    return 33600;

  case SFTReplaySpeed57600bps:
    return 57600;

  case SFTReplaySpeedUnlimited:
    return NSUIntegerMax;

  default:
    return 0;
  }
}

@end
