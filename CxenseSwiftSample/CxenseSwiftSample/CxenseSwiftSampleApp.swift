#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

import SwiftUI
import AdSupport
import CxenseSDK

class AppDelegate: NSObject, UIApplicationDelegate {
    
    public private(set) static var SiteID = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let cxenseConf = Bundle.main.object(forInfoDictionaryKey: "Cxense") as! [String:Any?]

        let configuration = Configuration(
            withUserName: cxenseConf["UserName"] as! String,
            apiKey: cxenseConf["ApiKey"] as! String
        )
        
        AppDelegate.SiteID = cxenseConf["SiteID"] as! String

        requestPersistentCookie { persistentCookie in
            if persistentCookie != nil {
                configuration.persistentCookie = persistentCookie!
            }
            
            try! Cxense.initialize(withConfiguration: configuration)
        }

        return true
    }
    
    private func requestPersistentCookie(completion: @escaping (String?) -> Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                var cookie: String? = nil
                if status == .authorized {
                    cookie = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                }
                completion(cookie)
            }
            return
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                completion(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            } else {
                completion(nil)
            }
        }
    }
}

@main
struct CxenseSwiftSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    }
}
