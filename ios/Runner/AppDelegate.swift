import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAppCheck

#if DEBUG
/// Debug App Check only on Simulator. Physical devices use DeviceCheck via
/// FlutterFire `AppleProvider.deviceCheck` so AI can be tested like production.
final class PulpoAppCheckDebugFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    AppCheckDebugProvider(app: app)
  }
}
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Do not `import flutter_local_notifications` here: Xcode 26 fails to resolve
    // that Swift module with static CocoaPods frameworks. Local notifications still
    // register via GeneratedPluginRegistrant; background-action isolate callback
    // can be re-added once plugin headers are visible to Runner again.
#if DEBUG
    // Only the first factory sticks — set debug factory only on Simulator.
    // On a real device leave the default so DeviceCheck can run.
    if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
      AppCheck.setAppCheckProviderFactory(PulpoAppCheckDebugFactory())
    }
#endif
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
