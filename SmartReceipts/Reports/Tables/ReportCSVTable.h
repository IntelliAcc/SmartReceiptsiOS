//
//  ReportCSVTable.h
//  SmartReceipts
//
//  Created by Jaanus Siim on 25/04/15.
//  Copyright (c) 2015 Will Baumann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReportTable.h"

@interface ReportCSVTable : ReportTable

- (instancetype)initWithContent:(NSMutableString *)content columns:(NSArray *)columns;

@end
