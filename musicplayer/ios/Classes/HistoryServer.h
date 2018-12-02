//
// Created by Willi Ye on 02.12.18.
//

#import <Foundation/Foundation.h>
#import "History.h"
#import "Server.h"

@interface HistoryServer : Server
- (void)add:(History *)history;
@end
