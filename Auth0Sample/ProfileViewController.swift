// ProfileViewController.swift
// Auth0Sample
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Lock
import AWSCognito
class ProfileViewController: UIViewController, UITextFieldDelegate {
    
    @IBAction func setCognitoData(_ sender: UIButton) {
        
        let dataset : AWSCognitoDataset
        
        let cognitoSync = AWSCognito.default()
        dataset = cognitoSync.openOrCreateDataset("MainDataset")
        
        dataset.setString(self.cognitoText.text, forKey: "value")
        _ = dataset.synchronize()
        
        self.view.endEditing(true)
    }

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    var provider: AWSCognitoCredentialsProvider!
    var profile: A0UserProfile!
    @IBOutlet weak var cognitoText: UITextField!
    var myCognitoData: String!
    var idToken: String!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

                           NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.identityDidChange(notification:)), name: NSNotification.Name.AWSCognitoIdentityIdChanged, object: nil)
      
        self.welcomeLabel.text = "Welcome, \(self.profile.name)"
        URLSession.shared.dataTask(with: self.profile.picture, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                guard let data = data , error == nil else { return }
                self.avatarImageView.image = UIImage(data: data)
            }
        }).resume()
        
        
        //AWSLogger.default().logLevel = AWSLogLevel.none
        self.provider = AWSCognitoCredentialsProvider.init(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:99ca9e07-a7d6-42ae-80a0-6c46bdb4dd92")
    
        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: provider);
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        
        self.cognitoText.delegate  = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.provider.invalidateCachedTemporaryCredentials()
        let logins = ["pushp.auth0.com": self.idToken]
        let manager = CustomIdentityProviderManager(tokens: logins as NSDictionary)
        self.provider.setIdentityProviderManagerOnce(manager)
        self.provider.invalidateCachedTemporaryCredentials()
        
        
        self.provider.getIdentityId().continueOnSuccessWith(block: { (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print(task.error!)
            } else {
                // the task result will contain the identity id
                let cognitoId:String? = task.result as? String
                //Store Cognito token in keychain
                
                print(cognitoId!);
                let dataset : AWSCognitoDataset
                let cognitoSync = AWSCognito.default()
                dataset = cognitoSync.openOrCreateDataset("MainDataset")
                self.cognitoText.text = dataset.string(forKey: "value")
                
                
            }
            return nil
            
        })

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    func identityDidChange(notification: NSNotification!) {
        if let userInfo = notification.userInfo as? [String: AnyObject]
        {
            let alert = UIAlertController(title: "Alert", message: "identity changed from: \(userInfo[AWSCognitoNotificationPreviousId]) to: \(userInfo[AWSCognitoNotificationNewId])", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        }
    }
    
        
}

class CustomIdentityProviderManager: NSObject, AWSIdentityProviderManager{
    public func logins() -> AWSTask<NSDictionary> {
        return AWSTask(result: tokens)
    }
    
    var tokens : NSDictionary
    
    init(tokens: NSDictionary) {
        self.tokens = tokens
    }
    
    
}
