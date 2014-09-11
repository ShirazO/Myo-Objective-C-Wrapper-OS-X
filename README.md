Myo-Objective-C-Wrapper-OS-X by ShirazO
============================

Objective-C Wrapper for C++ Myo.framework for OS X

You need to add myo.framework from the Myo SDK to the Project, instructions for that can be found on the SDK.

<B>Here is an example of how you can get started:</B>

    // Create Myo Object
    Myo *aMyo = [[Myo alloc] initWithApplicationIdentifier:@"com.YourCompany.ExampleApp"];
      
    // Create Block To Run Commands In Background Thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
      
      // Create Loop To Keep Trying To Find & Connect To Myo
      BOOL found = false;
      while (!found) {
          found = [self.myo connectMyoWaiting:10000];
      }
      
      // Create Block To Run Commands on Main Thread
      dispatch_async(dispatch_get_main_queue(), ^(void) {
          
          self.myo.delegate = self; // Set self as Delegate
          self.myo.updateTime = 1000; // Set the Update Time
          [self.myo startUpdate]; // Start Getting Updates From Myo (This Command Runs on Background Thread In Implemenation)
      });
    });
    
    // Add MyoDelegate To Your Class
    @interface ViewController : UIViewController <MyoDelegate>
    
    // Implement The Following Optional Delegate Methods To Handle The Events Triggered By The Listener
    - (void)myoOnUnpair:(Myo *)myo timestamp:(uint64_t)timestamp;
    - (void)myoOnArmLost:(Myo *)myo timestamp:(uint64_t)timestamp;
    - (void)myoOnDisconnect:(Myo *)myo timestamp:(uint64_t)timestamp;
    - (void)myo:(Myo *)myo onRssi:(int8_t)rssi timestamp:(uint64_t)timestamp;
    - (void)myo:(Myo *)myo onPose:(MyoPose *)pose timestamp:(uint64_t)timestamp;
    - (void)myo:(Myo *)myo onGyroscopeDataWithVector:(MyoVector *)vector timestamp:(uint64_t)timestamp;
    - (void)myo:(Myo *)myo onAccelerometerDataWithVector:(MyoVector *)vector timestamp:(uint64_t)timestamp;
    - (void)myoOnPair:(Myo *)myo firmwareVersion:(MyoFirmwareVersion *)firmware timestamp:(uint64_t)timestamp;
    - (void)myoOnConnect:(Myo *)myo firmwareVersion:(MyoFirmwareVersion *)firmware timestamp:(uint64_t)timestamp;
    - (void)myoOnArmRecognized:(Myo *)myo arm:(MyoArm)arm direction:(MyoDirection)direction timestamp:(uint64_t)timestamp;
    - (void)myo:(Myo *)myo onOrientationDataWithRoll:(int)roll pitch:(int)pitch yaw:(int)yaw timestamp:(uint64_t)timestamp;
