Initialize SDKs and Set Delegates
To display screens and process purchases correctly, initialize both SDKs in your app and assign delegates for handling screen behavior.

Required steps:

Initialize Qonversion SDK
Swift
Kotlin
Java
React Native
Flutter

final config = new QonversionConfigBuilder(
  'projectKey',
  QLaunchMode.subscriptionManagement
).build();
Qonversion.initialize(config);
Initialize No-Codes SDK
Swift
Kotlin
Java
React Native
Flutter

final noCodesConfig = new NoCodesConfigBuilder(projectKey).build();
NoCodes.initialize(noCodesConfig);
Set No-Codes SDK delegates
Swift
Kotlin
Java
React Native
Flutter

// Set presentation style config before showing screen if needed
    final config = NoCodesPresentationConfig(
        animated: true,
        presentationStyle: NoCodesPresentationStyle.fullScreen,
    );

    NoCodes.getSharedInstance().setScreenPresentationConfig(config, contextKey: 'your_context_key');

// Subscribe to separate NoCodes event streams
    _screenShownStream = NoCodes.getSharedInstance().screenShownStream.listen((event) {
      // add functionality here
    });
    
    _finishedStream = NoCodes.getSharedInstance().finishedStream.listen((event) {
      // add functionality here
    });
    
    _actionStartedStream = NoCodes.getSharedInstance().actionStartedStream.listen((event) {
      // add functionality here
    });
    
    _actionFailedStream = NoCodes.getSharedInstance().actionFailedStream.listen((event) {
      // add functionality here
    });
    
    _actionFinishedStream = NoCodes.getSharedInstance().actionFinishedStream.listen((event) {
      // add functionality here
    });
    
    _screenFailedToLoadStream = NoCodes.getSharedInstance().screenFailedToLoadStream.listen((event) {
      // add functionality here
    });
The first delegate is used for main events (e.g., screen opened, button tapped).
The second is for screen customization (if you want to override default styles).
3. Launch
Display Your No-Code Screen
Once everything is set up, you’re ready to display your screen inside the app.

This is where your design meets the real world. Whether you’re launching to users or testing internally, the process is the same.

Swift
Kotlin
Java
React Native
Flutter

NoCodes.getSharedInstance().showScreen('your_context_key');
Make Your First Purchase
It’s time to test the full flow — from screen to sale.

Launch your app
Display the screen you created
Trigger a test purchase
Confirm that everything works as expected: purchase completes, entitlements are unlocked, and analytics start flowing.
If you see revenue in your dashboard — congrats, you're live! 🥳



