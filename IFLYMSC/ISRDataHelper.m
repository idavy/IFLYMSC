//
//  ISRDataHander.m
//  MSC
//
//  Created by ypzhao on 12-11-19.
//  Copyright (c) 2012年 iflytek. All rights reserved.
//

#import "ISRDataHelper.h"

@implementation ISRDataHelper

/**
 解析命令词返回的结果
 ****/
+ (NSString*)stringFromAsr:(NSString*)params;
{
    NSMutableString * resultString = [[NSMutableString alloc]init];
    NSString *inputString = nil;
    
    NSArray *array = [params componentsSeparatedByString:@"\n"];
    
    for (int  index = 0; index < array.count; index++)
    {
        NSRange range;
        NSString *line = [array objectAtIndex:index];
        
        NSRange idRange = [line rangeOfString:@"id="];
        NSRange nameRange = [line rangeOfString:@"name="];
        NSRange confidenceRange = [line rangeOfString:@"confidence="];
        NSRange grammarRange = [line rangeOfString:@" grammar="];
        
        NSRange inputRange = [line rangeOfString:@"input="];
        
        if (confidenceRange.length == 0 || grammarRange.length == 0 || inputRange.length == 0 )
        {
            continue;
        }
        
        //check nomatch
        if (idRange.length!=0) {
            NSUInteger idPosX = idRange.location + idRange.length;
            NSUInteger idLength = nameRange.location - idPosX;
            range = NSMakeRange(idPosX,idLength);
            NSString *idValue = [[line substringWithRange:range]
                                 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] ];
            if ([idValue isEqualToString:@"nomatch"]) {
                return @"";
            }
        }
        
        //Get Confidence Value
        NSUInteger confidencePosX = confidenceRange.location + confidenceRange.length;
        NSUInteger confidenceLength = grammarRange.location - confidencePosX;
        range = NSMakeRange(confidencePosX,confidenceLength);
        
        
        NSString *score = [line substringWithRange:range];
        
        NSUInteger inputStringPosX = inputRange.location + inputRange.length;
        NSUInteger inputStringLength = line.length - inputStringPosX;
        
        range = NSMakeRange(inputStringPosX , inputStringLength);
        inputString = [line substringWithRange:range];
        
        [resultString appendFormat:@"%@ 置信度%@\n",inputString, score];
    }
    
    return resultString;
    
}

/**
 解析听写json格式的数据
 params例如：
 {"sn":1,"ls":true,"bg":0,"ed":0,"ws":[{"bg":0,"cw":[{"w":"白日","sc":0}]},{"bg":0,"cw":[{"w":"依山","sc":0}]},{"bg":0,"cw":[{"w":"尽","sc":0}]},{"bg":0,"cw":[{"w":"黄河入海流","sc":0}]},{"bg":0,"cw":[{"w":"。","sc":0}]}]}
 ****/
+ (NSString *)stringFromJson:(NSString*)params
{
    if (params == NULL) {
        return nil;
    }
    
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:    //返回的格式必须为utf8的,否则发生未知错误
                                [params dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];

    if (resultDic!= nil) {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];
        
        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex: i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            
            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString: str];
            }
        }
    }
    return tempStr;
}


/**
 解析语法识别返回的结果
 ****/
+ (NSString *)stringFromABNFJson:(NSString*)params
{
    if (params == NULL) {
        return nil;
    }
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:
                                [params dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    
    NSArray *wordArray = [resultDic objectForKey:@"ws"];
        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex: i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            
            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                NSString *score = [wDic objectForKey:@"sc"];
                [tempStr appendString: str];
                [tempStr appendFormat:@" 置信度:%@",score];
                [tempStr appendString: @"\n"];
            }
        }
    return tempStr;
}


/**
 金额转换成数字
 ****/
+ (NSString *)formatMoneyStringFromResult:(NSString *)source
{
	// 1,去除不相干的文字信息
	NSMutableArray *strs = [NSMutableArray array];
	for (NSInteger i = 0; i<source.length; i++) {
		NSString *st = [source substringWithRange:NSMakeRange(i, 1)];
		NSString *regStr = @"[0-9.]|一|二|两|三|四|五|六|七|八|九|十|百|千|万|亿|点";
		NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regStr];
		if ([regextest evaluateWithObject:st] == YES) {
			[strs addObject:st];
		}
	}
	
	source = [strs componentsJoinedByString:@""];
	NSString *decimalStr = @"";
	NSArray *strArray = [source componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".点"]];
	
	if (strArray.count >= 2) {
		source = strArray[0];
		decimalStr = strArray[1];
	}
	
	
	// 2,汉字'十','百','千'的转换
	long money = 0;
	// 如果不是数字也就是 一千万这样的汉字 ---则需要转换 如 一百五十万----1500000
	if ([source containsString:@"一"] ||
		[source containsString:@"二"] ||
		[source containsString:@"两"] ||
		[source containsString:@"三"] ||
		[source containsString:@"四"] ||
		[source containsString:@"五"] ||
		[source containsString:@"六"] ||
		[source containsString:@"七"] ||
		[source containsString:@"八"] ||
		[source containsString:@"九"] ||
		[source containsString:@"十"] ||
		[source containsString:@"百"] ||
		[source containsString:@"千"] ||
		[source containsString:@"万"] ||
		[source containsString:@"亿"]) {
		
		money = [self excuteCharge:source];
		
	}
	// 数据的来源直接就是阿拉伯数字 如200元---此时元已经去掉，即数字200
	else {
		if (![source isEqualToString:@""]) {
			money = source.longLongValue;
		}
	}
	// 3,返回最终格式化结果
	
	if (strArray.count >= 2) {
		return [NSString stringWithFormat:@"%ld.%@", money, [self decimalPart:decimalStr]];
	}
	return [NSString stringWithFormat:@"%ld", money];
}
+ (NSString *)decimalPart:(NSString *)str
{
	// 1,去除不相干的文字信息
	NSMutableArray *strs = [NSMutableArray array];
	for (NSInteger i = 0; i<str.length; i++) {
		NSString *st = [str substringWithRange:NSMakeRange(i, 1)];
		if ([st isEqualToString:@"一"]) {
			st = @"1";
		}
		else if ([st isEqualToString:@"二"]) {
			st = @"2";
		}
		else if ([st isEqualToString:@"两"]) {
			st = @"2";
		}
		else if ([st isEqualToString:@"三"]) {
			st = @"3";
		}
		else if ([st isEqualToString:@"四"]) {
			st = @"4";
		}
		else if ([st isEqualToString:@"五"]) {
			st = @"5";
		}
		else if ([st isEqualToString:@"六"]) {
			st = @"6";
		}
		else if ([st isEqualToString:@"七"]) {
			st = @"7";
		}
		else if ([st isEqualToString:@"八"]) {
			st = @"8";
		}
		else if ([st isEqualToString:@"九"]) {
			st = @"9";
		}
		else if ([st isEqualToString:@"零"]) {
			st = @"0";
		}
		[strs addObject:st];
	}
	return [strs componentsJoinedByString:@""];
}
+ (long)excuteCharge:(NSString *)str
{
	NSArray *strCHup = @[@"亿", @"万", @"千", @"百", @"十", @"元"];
	
	// 存储量级单位
	long midNumber = 0;
	// 存储是否可以找到最高量级
	NSUInteger bre = NSNotFound;
	// 找到后根据索引实行字符串分割
	int split = 0;
	// 通过循环查找最高量级
	for (int i = 0; i < strCHup.count; i++) {
		
		bre = [str rangeOfString:strCHup[i]].location;
		
		
		if (bre != NSNotFound) {
			split = i;
			switch (i) {
				case 0:
					midNumber = 100000000;
					break;
				case 1:
					midNumber = 10000;
					break;
				case 2:
					midNumber = 1000;
					break;
				case 3:
					midNumber = 100;
					break;
				case 4:
					midNumber = 10;
					break;
				case 5:
					midNumber = 1;
					break;
			}
			// 只需要找到最高量级,找到即刻跳出循环.
			break;
		}
  
	}
	// 如果没有找到量级数.说明该数很小,直接调用add()返回该值.
	if (bre == NSNotFound) {
		return [self add:str];
	}
	// 否则要根据量级进行字符串侵害和返回侵害前部分的值
	else {
		// 如果大型整数,如:十万 等.因为后面不需要再分割
		if (str.length == bre + 1) {
			// 对于单个量级的值,如:十、百、千、万等。不需要裁减字符串。直接返回量级即可
			if (str.length == 1) {
				return midNumber;
			} else {
				return [self add:[str substringToIndex:str.length - 1]] * midNumber;
			}
		}
		// 对于只有两位数的.如:十九.直接调用add()返回值即可.不能在此处递归.
		else if (str.length == bre + 2) {
			return [self add:str];
		}
		// 其他情况则取值和分割.然后再递归调用.
		else {
			NSArray *strPart = [str componentsSeparatedByString:strCHup[split]];
			return [self add:strPart[0]] * midNumber + [self excuteCharge:strPart[1]];
		}
	}
}
+ (long)add:(NSString *)str
{
	NSArray *strCHup = @[@"亿", @"万", @"千", @"百", @"十", @"元"];
	
	// 存储strCHup里具体汉字的数字值
	long mid = 0;
	// 存储strNumup里具体汉字的数字值
	int number = 0;
	// 存储传入字符串的最高级别单位在strCHup数组里的索引.
	NSUInteger num = NSNotFound;
	for (int i = 0; i < strCHup.count; i++) {
		// 取得量级在字符串中的索引.
		num = [str rangeOfString:strCHup[i]].location;
		
		NSString *ch = @"";
		
		// //////////////////////////////////////////////////////////////
		if (num != NSNotFound) {
			
			switch (i) {
				case 0:
					mid = 100000000;
					break;
				case 1:
					mid = 10000;
					break;
				case 2:
					mid = 1000;
					break;
				case 3:
					mid = 100;
					break;
				case 4:
					mid = 10;
					break;
				case 5:
					mid = 1;
					break;
			}
			
			// 如果以"十"开关的,直接定义number的值.因为在上面能够找到它的量级.
			if ([str hasPrefix:@"十"]) {
				number = 1;
			}
			// 否则,取得量级前的数字进行比较,再确定number的值
			else {
				if (0 != num) {
					ch = [str substringWithRange:NSMakeRange(num - 1, 1)];
				}
			}
			// ////////////////////////////////////////////////////
		}
		// 循环结束
		// ////////////////////////////////////////////////////////////////
		// 如果整个字符串就一个字,那么就应该取该值进行比较.而不是再取量级前的数字.
		if (str.length == 1) {
			ch = [str substringWithRange:NSMakeRange(0, 1)];
		}
		// 防止几万零几这样的数.
		
		else if ((str.length == 2) && [str hasPrefix:@"零"]) {
			ch = [str substringWithRange:NSMakeRange(1, 1)];
		}
		// ///////////////////////////////////////////////////////////////
  
		if ([ch isEqualToString:@"零"]) {
			number = 0;
		}
		else if ([ch isEqualToString:@"一"]) {
			number = 1;
		}
		else if ([ch isEqualToString:@"二"]) {
			number = 2;
		}
		else if ([ch isEqualToString:@"三"]) {
			number = 3;
		}
		else if ([ch isEqualToString:@"四"]) {
			number = 4;
		}
		else if ([ch isEqualToString:@"五"]) {
			number = 5;
		}
		else if ([ch isEqualToString:@"六"]) {
			number = 6;
		}
		else if ([ch isEqualToString:@"七"]) {
			number = 7;
		}
		else if ([ch isEqualToString:@"八"]) {
			number = 8;
		}
		else if ([ch isEqualToString:@"九"]) {
			number = 9;
		}
		else {
			NSString *regStr = @"^[0-9]*$";
			NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regStr];
			if ([regextest evaluateWithObject:str] == YES) {
				return str.longLongValue;
			}
		}
		
		if (num != NSNotFound) {
			break;
		}
	}
	if (num == NSNotFound) {
		return number;
	}
	NSString *strLeft = [str substringFromIndex:num+1];
	return (number * mid) + [self add:strLeft];
}

@end
