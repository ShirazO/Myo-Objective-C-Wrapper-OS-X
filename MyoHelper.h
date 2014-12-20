//
//  MyoHelper.h
//
//  Created by Shiraz Omar on 03/09/2014.
//  Copyright (c) 2014 Shiraz Omar. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Myo;


#pragma mark - MyoPose
typedef enum MyoPoseType {
    MyoPoseTypeRest = 0,
    MyoPoseTypeFist = 1,
    MyoPoseTypeWaveIn = 2,
    MyoPoseTypeWaveOut = 3,
    MyoPoseTypeFingersSpread = 4,
    MyoPoseTypeDoubleTap = 5,
    MyoPoseTypeUnknown = 0xffff
} MyoPoseType;

@interface MyoPose : NSObject

@property (nonatomic) MyoPoseType poseType;

@end

@interface MyoVector : NSObject {
    
    float vectorData[3];
}

@property (nonatomic, readonly, getter=x) float x;
@property (nonatomic, readonly, getter=y) float y;
@property (nonatomic, readonly, getter=y) float z;
@property (nonatomic, readonly, getter=magnitude) float magnitude;

- (id)init;
- (float)x;
- (float)y;
- (float)z;
- (float)magnitude;
- (MyoVector *)normalized;
- (float)angleWithVector:(MyoVector *)vector;
- (float)productWithVector:(MyoVector *)vector;
- (id)initWithX:(float)x y:(float)y z:(float)z;
- (MyoVector *)crossProductWithVector:(MyoVector *)vector;

@end


#pragma mark - MyoDelegate
typedef enum MyoArm {
    MyoArmLeft = 0,
    MyoArmRight = 1,
    MyoArmUnknown = 2
} MyoArm;

typedef enum MyoDirection {
    MyoDirectionTowardWrist = 0,
    MyoDirectionTowardElbow = 1,
    MyoDirectionUnknown = 2
} MyoDirection;

@protocol MyoDelegate <NSObject>

@optional
- (void)myoOnLock:(Myo *)myo timestamp:(uint64_t)timestamp;
- (void)myoOnUnlock:(Myo *)myo timestamp:(uint64_t)timestamp;
- (void)myoOnUnpair:(Myo *)myo timestamp:(uint64_t)timestamp;
- (void)myoOnArmUnsync:(Myo *)myo timestamp:(uint64_t)timestamp;
- (void)myoOnDisconnect:(Myo *)myo timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onRssi:(int8_t)rssi timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onPose:(MyoPose *)pose timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onEmgData:(int *)emgData timestamp:(uint64_t)timestamp;
- (void)myoOnPair:(Myo *)myo firmwareVersion:(NSString *)firmware timestamp:(uint64_t)timestamp;
- (void)myoOnConnect:(Myo *)myo firmwareVersion:(NSString *)firmware timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onGyroscopeDataWithVector:(MyoVector *)vector timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onAccelerometerDataWithVector:(MyoVector *)vector timestamp:(uint64_t)timestamp;
- (void)myoOnArmSync:(Myo *)myo arm:(MyoArm)arm direction:(MyoDirection)direction timestamp:(uint64_t)timestamp;
- (void)myo:(Myo *)myo onOrientationDataWithRoll:(float)roll pitch:(float)pitch yaw:(float)yaw timestamp:(uint64_t)timestamp;

@end


#pragma mark - MyoUnlockType
typedef enum MyoUnlockType {
    MyoUnlockTypeTimed = 0,
    MyoUnlockTypeHold = 1,
} MyoUnlockType;


#pragma mark - MyoLockingPolicy
typedef enum MyoLockingPolicy {
    MyoLockingPolicyNone,
    MyoLockingPolicyStandard,
} MyoLockingPolicy;


#pragma mark - MyoVibrationType
typedef enum MyoVibrationType {
    MyoVibrationTypeShort = 0,
    MyoVibrationTypeMedium = 1,
    MyoVibrationTypeLong = 2,
    MyoVibrationTypeNone = 3
} MyoVibrationType;


#pragma mark - Myo
@interface Myo : NSObject

- (void)lockMyo;
- (void)stopUpdate;
- (void)startUpdate;
- (void)requestRSSI;
- (void)enableEmgData;
- (void)disableEmgData;
- (void)showUserNotification; // Causes Small Vibration
- (NSString *)poseName:(MyoPose *)pose;
- (void)unlockMyo:(MyoUnlockType)unlockType;
- (BOOL)connectMyoWaiting:(int)milliseconds;
- (NSString *)getArmDescription:(MyoArm)arm;
- (void)vibrateWithType:(MyoVibrationType)type;
- (void)setMyoLockingPolicy:(MyoLockingPolicy)lockingPolicy;
- (NSString *)getDirectionDescription:(MyoDirection)direction;
- (BOOL)connectMyoWaiting:(int)milliseconds enableEmg:(BOOL)emg;
- (instancetype)initWithApplicationIdentifier:(NSString *)identifier;

@property (nonatomic) int updateTime;
@property (nonatomic, assign) id <MyoDelegate> delegate;

@end
