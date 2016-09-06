//
//  IATSpeechRecognizer.h
//  Financial
//
//  Created by Dave on 16/3/15.
//  Copyright © 2016年 Dave. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EndOfSpeechResultBlock) (NSString *result);

@interface IATSpeechRecognizer : NSObject

- (void)startSpeechRecognizerWithCallback:(EndOfSpeechResultBlock)result; //开始听写
- (void)cancelSpeechRecognizer; //取消听写

@end
