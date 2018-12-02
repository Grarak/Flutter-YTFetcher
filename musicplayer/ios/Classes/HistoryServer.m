//
// Created by Willi Ye on 02.12.18.
//

#import "HistoryServer.h"

@implementation HistoryServer
- (void)add:(History *)history {
    [self post:@"users/history/add" :[history to_string] :nil];
}
@end
