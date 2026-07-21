import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Symmetric contract with Android; the iOS side is a stub (see below).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ConnectivityChannel") {
      let channel = FlutterEventChannel(
        name: "kongsi/connectivity",
        binaryMessenger: registrar.messenger()
      )
      channel.setStreamHandler(ConnectivityStreamHandler())
    }
  }
}

/// iOS stub so the channel compiles and the contract stays symmetric with
/// Android. The developer can't run iOS; a real impl would drive this from
/// NWPathMonitor. Emits nothing for now.
class ConnectivityStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    // TODO(ios): emit "online"/"offline" from NWPathMonitor when iOS ships.
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
