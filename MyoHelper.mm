//
//  MyoHelper.mm
//  MyoProfiler
//
//  Created by Shiraz Omar on 03/09/2014.
//  Copyright (c) 2014 Shiraz Omar. All rights reserved.
//

#import <myo/myo.hpp>

#import "MyoHelper.h"


@class Myo;


class DataCollector : public myo::DeviceListener {
    
public:
    
    DataCollector() : onArm(false), isUnlocked(false), roll_w(0), pitch_w(0), yaw_w(0), currentPose() {}
    
    
    // onOrientationData() is called whenever the Myo device provides its current orientation, which is represented as a unit quaternion.
    void onOrientationData(myo::Myo *myo, uint64_t timestamp, const myo::Quaternion<float>&quat) {
        
        using std::atan2;
        using std::asin;
        using std::sqrt;
        using std::max;
        using std::min;
        
        // Calculate Euler angles (roll, pitch, and yaw) from the unit quaternion.
        float roll = atan2(2.0f * (quat.w() * quat.x() + quat.y() * quat.z()),
                           1.0f - 2.0f * (quat.x() * quat.x() + quat.y() * quat.y()));
        float pitch = asin(max(-1.0f, min(1.0f, 2.0f * (quat.w() * quat.y() - quat.z() * quat.x()))));
        float yaw = atan2(2.0f * (quat.w() * quat.z() + quat.x() * quat.y()),
                          1.0f - 2.0f * (quat.y() * quat.y() + quat.z() * quat.z()));
        
        // Convert the floating point angles in radians to a scale from 0 to 18.
        roll_w = static_cast<int>((roll + (float)M_PI)/(M_PI * 2.0f) * 18);
        pitch_w = static_cast<int>((pitch + (float)M_PI/2.0f)/M_PI * 18);
        yaw_w = static_cast<int>((yaw + (float)M_PI)/(M_PI * 2.0f) * 18);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myo:onOrientationDataWithRoll:pitch:yaw:timestamp:)]) {
                [_myo.delegate myo:_myo onOrientationDataWithRoll:roll_w pitch:pitch_w yaw:yaw_w timestamp:timestamp];
            }
        });
    }
    
    /// Called when a Myo has been paired.
    void onPair(myo::Myo *myo, uint64_t timestamp, myo::FirmwareVersion firmwareVersion) {
        
        NSString *firmware = [NSString stringWithFormat:@"Myo Firmware v%u.%u.%u.%u", firmwareVersion.firmwareVersionMajor, firmwareVersion.firmwareVersionMinor, firmwareVersion.firmwareVersionPatch, firmwareVersion.firmwareVersionHardwareRev];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnPair:firmwareVersion:timestamp:)]) {
                [_myo.delegate myoOnPair:_myo firmwareVersion:firmware timestamp:timestamp];
            }
        });
    }
    
    /// Called when a Myo has been unpaired.
    void onUnpair(myo::Myo *myo, uint64_t timestamp) {
        
        // Myo Lost. Cleanup
        yaw_w = 0;
        roll_w = 0;
        pitch_w = 0;
        onArm = false;
        isUnlocked = false;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnUnpair:timestamp:)]) {
                [_myo.delegate myoOnUnpair:_myo timestamp:timestamp];
            }
        });
    }
    
    /// Called when a paired Myo has been connected.
    void onConnect(myo::Myo *myo, uint64_t timestamp, myo::FirmwareVersion firmwareVersion) {
        
        NSString *firmware = [NSString stringWithFormat:@"Myo Firmware v%u.%u.%u.%u", firmwareVersion.firmwareVersionMajor, firmwareVersion.firmwareVersionMinor, firmwareVersion.firmwareVersionPatch, firmwareVersion.firmwareVersionHardwareRev];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnConnect:firmwareVersion:timestamp:)]) {
                [_myo.delegate myoOnConnect:_myo firmwareVersion:firmware timestamp:timestamp];
            }
        });
    }
    
    /// Called when a paired Myo has been disconnected.
    void onDisconnect(myo::Myo *myo, uint64_t timestamp) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnDisconnect:timestamp:)]) {
                [_myo.delegate myoOnDisconnect:_myo timestamp:timestamp];
            }
        });
    }
    
    // onArmSync() is called whenever Myo has recognized a Sync Gesture after someone has put it on their arm. This lets Myo know which arm it's on and which way it's facing.
    void onArmSync(myo::Myo *myo, uint64_t timestamp, myo::Arm arm, myo::XDirection xDirection) {
        
        onArm = true;
        whichArm = arm;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnArmSync:arm:direction:timestamp:)]) {
                [_myo.delegate myoOnArmSync:_myo arm:getArm(arm) direction:getDirection(xDirection) timestamp:timestamp];
            }
        });
    }
    
    // onArmUnsync() is called whenever Myo has detected that it was moved from a stable position on a person's arm after it recognized the arm. Typically this happens when someone takes Myo off of their arm, but it can also happen when Myo is moved around on the arm.
    void onArmUnsync(myo::Myo *myo, uint64_t timestamp) {
        
        onArm = false;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnArmUnsync:timestamp:)]) {
                [_myo.delegate myoOnArmUnsync:_myo timestamp:timestamp];
            }
        });
    }
    
    // onPose() is called whenever the Myo detects that the person wearing it has changed their pose, for example, making a fist, or not making a fist anymore.
    void onPose(myo::Myo *myo, uint64_t timestamp, myo::Pose pose) {
        
        currentPose = pose;
        
        if (pose != myo::Pose::unknown && pose != myo::Pose::rest) {
            // Tell the Myo to stay unlocked until told otherwise. We do that here so you can hold the poses without the
            // Myo becoming locked.
            myo->unlock(myo::Myo::unlockHold);
            
            // Notify the Myo that the pose has resulted in an action, in this case changing
            // the text on the screen. The Myo will vibrate.
            myo->notifyUserAction();
        } else {
            // Tell the Myo to stay unlocked only for a short period. This allows the Myo to stay unlocked while poses
            // are being performed, but lock after inactivity.
            myo->unlock(myo::Myo::unlockTimed); // ** Change This To Prevent Timed Locking on Rest Pose **
        }
        
        MyoPose *myoPose = [MyoPose new];
        if (pose.type() == myo::Pose::rest)
            myoPose.poseType = MyoPoseTypeRest;
        if (pose.type() == myo::Pose::fist)
            myoPose.poseType = MyoPoseTypeFist;
        if (pose.type() == myo::Pose::waveIn)
            myoPose.poseType = MyoPoseTypeWaveIn;
        if (pose.type() == myo::Pose::waveOut)
            myoPose.poseType = MyoPoseTypeWaveOut;
        if (pose.type() == myo::Pose::doubleTap)
            myoPose.poseType = MyoPoseTypeDoubleTap;
        if (pose.type() == myo::Pose::doubleTap)
            myoPose.poseType = MyoPoseTypeFingersSpread;
        if (pose.type() == myo::Pose::unknown)
            myoPose.poseType = MyoPoseTypeUnknown;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myo:onPose:timestamp:)]) {
                [_myo.delegate myo:_myo onPose:myoPose timestamp:timestamp];
            }
        });
    }
    
    // onLock() is called whenever Myo has become locked. No pose events will be sent until the Myo is unlocked again.
    void onLock(myo::Myo *myo, uint64_t timestamp) {
        
        isUnlocked = false;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnLock:timestamp:)]) {
                [_myo.delegate myoOnLock:_myo timestamp:timestamp];
            }
        });
    }
    
    // onUnlock() is called whenever Myo has become unlocked, and will start delivering pose events.
    void onUnlock(myo::Myo *myo, uint64_t timestamp) {
        
        isUnlocked = true;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myoOnUnlock:timestamp:)]) {
                [_myo.delegate myoOnUnlock:_myo timestamp:timestamp];
            }
        });
    }
    
    /// Called when a paired Myo has provided new accelerometer data in units of g.
    void onAccelerometerData(myo::Myo *myo, uint64_t timestamp, const myo::Vector3<float>&accel) {
        
        MyoVector *vector = [[MyoVector alloc] initWithX:accel.x() y:accel.y() z:accel.z()];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myo:onAccelerometerDataWithVector:timestamp:)]) {
                [_myo.delegate myo:_myo onAccelerometerDataWithVector:vector timestamp:timestamp];
            }
        });
    }
    
    /// Called when a paired Myo has provided new gyroscope data in units of deg/s.
    void onGyroscopeData(myo::Myo *myo, uint64_t timestamp, const myo::Vector3<float>&gyro) {
        
        MyoVector *vector = [[MyoVector alloc] initWithX:gyro.x() y:gyro.y() z:gyro.z()];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myo:onGyroscopeDataWithVector:timestamp:)]) {
                [_myo.delegate myo:_myo onGyroscopeDataWithVector:vector timestamp:timestamp];
            }
        });
    }
    
    /// Called when a paired Myo has provided a new RSSI value.
    /// @see Myo::requestRssi() to request an RSSI value from the Myo.
    void onRssi(myo::Myo *myo, uint64_t timestamp, int8_t rssi) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // Fire Delegate Method On Main Thread
            if ([_myo.delegate respondsToSelector:@selector(myo:onRssi:timestamp:)]) {
                [_myo.delegate myo:_myo onRssi:rssi timestamp:timestamp];
            }
        });
    }
    
    
    // Utility Methods
    // Converts myo::Arm to MyoArm
    MyoArm getArm(myo::Arm arm) {
        
        MyoArm myoArm;
        if (arm == myo::Arm::armLeft) {
            myoArm = MyoArmLeft;
        } else if (arm == myo::Arm::armRight) {
            myoArm = MyoArmRight;
        } else {
            myoArm = MyoArmUnknown;
        }
        return myoArm;
    }
    
    // Converts myo::XDirection to MyoDirection
    MyoDirection getDirection(myo::XDirection direction) {
        
        MyoDirection myoDirection;
        if (direction == myo::XDirection::xDirectionTowardElbow) {
            myoDirection = MyoDirectionTowardElbow;
        } else if (direction == myo::XDirection::xDirectionTowardWrist) {
            myoDirection = MyoDirectionTowardWrist;
        } else {
            myoDirection = MyoDirectionUnknown;
        }
        return myoDirection;
    }
    
    
    // These values are set by onArmSync() and onArmUnsync() above.
    bool onArm;
    myo::Arm whichArm;
    
    // This is set by onUnlocked() and onLocked() above.
    bool isUnlocked;
    
    // These values are set by onOrientationData() and onPose() above.
    Myo *_myo;
    myo::Pose currentPose;
    int roll_w, pitch_w, yaw_w;
};


#define DEFAULT_UPDATE_TIME 100
#pragma mark - MYOPOSE
@implementation MyoPose

@end


#pragma mark - MYOVECTOR
@implementation MyoVector

- (id)init {
    
    return [self initWithX:0 y:0 z:0];
}

- (instancetype)initWithX:(float)x y:(float)y z:(float)z {
    
    self = [super init];
    if (self) {
        vectorData[0] = x;
        vectorData[1] = y;
        vectorData[2] = z;
    }
    return self;
}

- (float)x {
    
    return vectorData[0];
}

-(float)y
{
    return vectorData[1];
}

- (float)z {
    
    return vectorData[2];
}

- (float)magnitude {
    
    return std::sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
}

- (float)productWithVector:(MyoVector *)vector {
    
    return self.x * self.x + self.y * self.y + self.z * self.z;
}

- (MyoVector *)normalized {
    
    float norm = self.magnitude;
    return [[MyoVector alloc] initWithX:(self.x / norm) y:(self.y / norm) z:(self.z / norm)];
}

- (MyoVector *)crossProductWithVector:(MyoVector *)vector {
    
    float x = self.x * vector.y - self.y * vector.x;
    float y = self.y * vector.z - self.z * vector.y;
    float z = self.z * vector.x - self.x * vector.z;
    return [[MyoVector alloc] initWithX:x y:y z:z];
}

- (float)angleWithVector:(MyoVector *)vector {
    
    return std::acos([self productWithVector:vector] / (self.magnitude * vector.magnitude));
}

@end


#pragma mark - MYO
@implementation Myo {
    
    BOOL update;
    myo::Hub hub;
    myo::Myo *myo;
    DataCollector collector;
}

- (instancetype)initWithApplicationIdentifier:(NSString *)identifier {
    
    self = [super init];
    if (self) {
        myo::Hub hub([identifier UTF8String]);
        self.updateTime = DEFAULT_UPDATE_TIME;
    }
    return self;
}

- (BOOL)connectMyoWaiting:(int)milliseconds {
    
    try {
        
        myo = hub.waitForMyo(milliseconds);
        NSLog(@"Looking For Myo...");
        
        if (!myo) {
            NSLog(@"Unable To Find Myo!");
            return false;
        }
        NSLog(@"Connected to a Myo Armband!");
        collector._myo = self;
        hub.addListener(&collector);
        
    } catch (const std::exception &e) {
        
        NSLog(@"Failed to Connect to a Myo Armband - %@", [NSString stringWithUTF8String:e.what()]);
        return false;
    }
    
    return true;
}

- (void)startUpdate {
    
    update = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        try {
            
            //Background Thread
            while (update) {
                hub.run(_updateTime);
            }
            
        } catch (const std::exception &e) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSLog(@"Error In Myo Update Loop - %@", [NSString stringWithUTF8String:e.what()]);
            });
        }
    });
}
- (void)stopUpdate {
    
    update = false;
}

- (void)lockMyo {
    
    myo->lock();
}

- (void)unlockMyo:(MyoUnlockType)unlockType {
    
    if (unlockType == MyoUnlockTypeHold) {
        myo->unlock(myo::Myo::unlockHold);
    } else {
        myo->unlock(myo::Myo::unlockTimed);
    }
}

- (void)setMyoLockingPolicy:(MyoLockingPolicy)lockingPolicy {
    
    if (lockingPolicy == MyoLockingPolicyNone) {
        hub.setLockingPolicy(myo::Hub::lockingPolicyNone);
    } else {
        hub.setLockingPolicy(myo::Hub::lockingPolicyStandard);
    }
}

- (void)vibrateWithType:(MyoVibrationType)type {
    
    switch (type) {
        case MyoVibrationTypeShort:
            myo->vibrate(myo::Myo::vibrationShort);
            break;
        case MyoVibrationTypeLong:
            myo->vibrate(myo::Myo::vibrationLong);
            break;
        default:
            myo->vibrate(myo::Myo::vibrationMedium);
            break;
    }
    
}

- (void)requestRSSI {
    
    myo->requestRssi();
}

- (NSString *)getArmDescription:(MyoArm)arm {
    
    if (arm == MyoArmLeft) {
        return @"Left Arm";
    } else if (arm == MyoArmRight) {
        return @"Right Arm";
    } else {
        return @"Unknown Arm";
    }
}

- (NSString *)getDirectionDescription:(MyoDirection)direction {
    
    if (direction == MyoDirectionTowardElbow) {
        return @"Toward Elbow";
    } else if (direction == MyoDirectionTowardWrist) {
        return @"Toward Wrist";
    } else {
        return @"Unknown Direction";
    }
}

- (NSString *)poseName:(MyoPose *)pose {
    
    if (pose.poseType == MyoPoseTypeRest) {
        return @"Rest";
    } else if (pose.poseType == MyoPoseTypeFist) {
        return @"Fist";
    } else if (pose.poseType == MyoPoseTypeFingersSpread) {
        return @"Fingers Spread";
    } else if (pose.poseType == MyoPoseTypeWaveIn) {
        return @"Wave In";
    } else if (pose.poseType == MyoPoseTypeWaveOut) {
        return @"Wave Out";
    } else if (pose.poseType == MyoPoseTypeDoubleTap) {
        return @"Double Tap";
    } else if (pose.poseType == MyoPoseTypeUnknown) {
        return @"Unrecognized";
    } else {
        return @"Unrecognized";
    }
}

@end