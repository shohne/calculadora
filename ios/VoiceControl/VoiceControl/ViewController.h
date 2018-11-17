//
//  ViewController.h
//  VoiceControl
//
//  Created by Silvio Hohne on 11/12/18.
//  Copyright © 2018 Silvio Hohne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioRecorderDelegate, UITextFieldDelegate>

@property UIButton *btCommand;
@property UIButton *btPlay;
@property UIButton *btSettings;
@property int sequence;
@property int estado;
@property bool respostaDisponivel;
@property(nonatomic,strong) AVAudioRecorder *recorder;
@property(nonatomic,strong) NSMutableDictionary *recorderSettings;
@property(nonatomic,strong) NSString *recorderFilePath;
@property(nonatomic,strong) AVAudioPlayer *audioPlayer;
@property(nonatomic,strong) NSString *audioFileName;
@property(nonatomic,strong) NSString *enderecoServidor;
@property(nonatomic, retain) AVAudioPlayer *player;


@end

