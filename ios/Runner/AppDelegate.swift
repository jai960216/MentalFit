import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // URL 처리를 위한 메서드 추가
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Google Sign-In URL 처리
    if url.scheme?.hasPrefix("com.googleusercontent.apps.") == true {
      return super.application(app, open: url, options: options)
    }
    
    // Bundle ID URL 처리
    if url.scheme == "com.mentalfit.sports" {
      return super.application(app, open: url, options: options)
    }
    
    return super.application(app, open: url, options: options)
  }
  
  // iOS 9 이하 지원을 위한 메서드
  override func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any
  ) -> Bool {
    // Google Sign-In URL 처리
    if url.scheme?.hasPrefix("com.googleusercontent.apps.") == true {
      return super.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // Bundle ID URL 처리
    if url.scheme == "com.mentalfit.sports" {
      return super.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    return super.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
  }
}
