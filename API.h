//
//  ContentManager.h
//  Food
//
//  Created by TNKHANH on 12/11/17.
//  Copyright © 2017 TNKHANH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FoodModel.h"

@interface ContentManager : NSObject

+ (ContentManager *)shareManager;
- (void)getFoodListWithCompletion:(void(^)(BOOL success, NSArray *foodList, NSString *errorMessage))callBack;

@end
