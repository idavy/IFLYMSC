//
//  IATSpeechRecognizer.m
//  Financial
//
//  Created by Dave on 16/3/15.
//  Copyright © 2016年 Dave. All rights reserved.
//

#import "IATSpeechRecognizer.h"
#import "iflyMSC/iflyMSC.h"
#import "IATConfig.h"
#import "ISRDataHelper.h"


@interface IATSpeechRecognizer () <IFlySpeechRecognizerDelegate,IFlyRecognizerViewDelegate,UIActionSheetDelegate>
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;//带界面的识别对象

@property (nonatomic, strong) NSString * result;
@property (nonatomic, assign) BOOL isCanceled;

@property (nonatomic, copy) EndOfSpeechResultBlock resultBlock;

@end

@implementation IATSpeechRecognizer

- (instancetype)init
{
	self = [super init];
	if (self) {
		[IATConfig sharedInstance].haveView = YES;
		[self initRecognizer];//初始化识别对象
	}
	return self;
}
/**
 设置识别参数
 ****/
-(void)initRecognizer
{
	_result = @"";
	if ([IATConfig sharedInstance].haveView == NO) {//无界面
		
		//单例模式，无UI的实例
		if (_iFlySpeechRecognizer == nil) {
			_iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
			
			[_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
			
			//设置听写模式
			[_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
		}
		_iFlySpeechRecognizer.delegate = self;
		
		if (_iFlySpeechRecognizer != nil) {
			IATConfig *instance = [IATConfig sharedInstance];
			
			//设置最长录音时间
			[_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
			//设置后端点
			[_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
			//设置前端点
			[_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
			//网络等待时间
			[_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
			
			//设置采样率，推荐使用16K
			[_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
			
			if ([instance.language isEqualToString:[IATConfig chinese]]) {
				//设置语言
				[_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
				//设置方言
				[_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
			}else if ([instance.language isEqualToString:[IATConfig english]]) {
				[_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
			}
			//设置是否返回标点符号
			[_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
			
		}
	}else  {//有界面
		
		//单例模式，UI的实例
		if (_iflyRecognizerView == nil) {
			//UI显示居中
            CGPoint center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
			_iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:center];
			
			[_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
			
			//设置听写模式
			[_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
			
		}
		_iflyRecognizerView.delegate = self;
		
		if (_iflyRecognizerView != nil) {
			IATConfig *instance = [IATConfig sharedInstance];
			//设置最长录音时间
			[_iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
			//设置后端点
			[_iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
			//设置前端点
			[_iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
			//网络等待时间
			[_iflyRecognizerView setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
			
			//设置采样率，推荐使用16K
			[_iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
			if ([instance.language isEqualToString:[IATConfig chinese]]) {
				//设置语言
				[_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
				//设置方言
				[_iflyRecognizerView setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
			}else if ([instance.language isEqualToString:[IATConfig english]]) {
				//设置语言
				[_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
			}
			//设置是否返回标点符号
			[_iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
			
		}
	}
}

- (void)startSpeechRecognizerWithCallback:(EndOfSpeechResultBlock)result
{
	self.resultBlock = [result copy];
	
	if ([IATConfig sharedInstance].haveView == NO) {//无界面
		
		self.isCanceled = NO;
		
		if(_iFlySpeechRecognizer == nil)
		{
			[self initRecognizer];
		}
		
		[_iFlySpeechRecognizer cancel];
		
		//设置音频来源为麦克风
		[_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
		
		//设置听写结果格式为json
		[_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
		
		//保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
		[_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
		
		[_iFlySpeechRecognizer setDelegate:self];
		
		BOOL ret = [_iFlySpeechRecognizer startListening];
		
		if (ret) {

		}else{
			NSLog(@"启动识别服务失败，请稍后重试");//可能是上次请求未结束，暂不支持多路并发
		}
	}else {
		
		if(_iflyRecognizerView == nil)
		{
			[self initRecognizer ];
		}
		
		//设置音频来源为麦克风
		[_iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
		
		//设置听写结果格式为json
		[_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
		
		//保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
		[_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
		
		[_iflyRecognizerView start];
	}
}

- (void)cancelSpeechRecognizer
{
	if ([IATConfig sharedInstance].haveView == NO) {//无界面
		[_iFlySpeechRecognizer cancel]; //取消识别
		[_iFlySpeechRecognizer setDelegate:nil];
		[_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
	}
	else
	{
		[_iflyRecognizerView cancel]; //取消识别
		[_iflyRecognizerView setDelegate:nil];
		[_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
	}
}

#pragma mark - IFlySpeechRecognizerDelegate

/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
	NSLog(@"onBeginOfSpeech");
}

/**
 停止录音回调
 ****/
- (void) onEndOfSpeech
{
	NSLog(@"onEndOfSpeech");
}


/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
	NSLog(@"%s",__func__);
	
	if ([IATConfig sharedInstance].haveView == NO ) {
		NSString *text ;
		
		if (self.isCanceled) {
			text = @"识别取消";
			
		} else if (error.errorCode == 0 ) {
			if (_result.length == 0) {
				text = @"无识别结果";
			}else {
				text = @"识别成功";
			}
		}else {
			text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
			NSLog(@"%@",text);
		}
		
		NSLog(@"%@", text);
		
	}else {
		NSLog(@"识别结束 errorCode:%d",[error errorCode]);
	}
}

/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
	NSMutableString *resultString = [[NSMutableString alloc] init];
	NSDictionary *dic = results[0];
	for (NSString *key in dic) {
		[resultString appendFormat:@"%@",key];
	}
	NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
	_result =[NSString stringWithFormat:@"%@%@", _result,resultFromJson];
	
	if (isLast){
		NSLog(@"听写结果(json)：%@测试",  self.result);
//		_result = [ISRDataHelper formatMoneyStringFromResult:_result];
		if (self.resultBlock) {
			self.resultBlock(_result);
		}
		
		_result = @"";
	}
}


/**
 有界面，听写结果回调
 resultArray：听写结果
 isLast：表示最后一次
 ****/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
	NSMutableString *result = [[NSMutableString alloc] init];
	NSDictionary *dic = [resultArray objectAtIndex:0];
	
	for (NSString *key in dic) {
		[result appendFormat:@"%@",key];
	}
	_result = [_result stringByAppendingString:result];
	if (isLast){
		NSLog(@"听写结果(json)：%@测试",  _result);
//		_result = [ISRDataHelper formatMoneyStringFromResult:_result];
		if (self.resultBlock) {
			self.resultBlock(_result);
		}
		_result = @"";
	}
}


/**
 听写取消回调
 ****/
- (void) onCancel
{
	NSLog(@"识别取消");
}


- (void)dealloc
{
	[self cancelSpeechRecognizer];
}

@end
