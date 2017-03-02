// HomeViewController.swift
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

class HomeViewController: UIViewController,UITextFieldDelegate {
    
    // MARK: - IBAction
    
    var credentialProvider: AWSCognitoCredentialsProvider!

    @IBAction func showLoginController(_ sender: UIButton) {
    
    
    
        
        let controller = A0Lock.shared().newLockViewController()
        controller?.closable = true
        controller?.onAuthenticationBlock = { profile, token in
            guard let userProfile = profile else {
                self.showMissingProfileAlert()
                return
            }
            self.idToken = token?.idToken
            
            self.retrievedProfile = userProfile
            
            controller?.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "ShowProfile", sender: nil)
        }
        controller?.onUserDismissBlock = {
            //The user dismisses the Login screen
        }
        A0Lock.shared().present(controller, from: self)
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let profileController = segue.destination as? ProfileViewController else {
            return
        }
        profileController.profile = self.retrievedProfile
        profileController.myCognitoData = self.valueFromCognito.text
        profileController.idToken = self.idToken
    }
    
    // MARK: - Private
    
    fileprivate var retrievedProfile: A0UserProfile!
    fileprivate var idToken: String!
    
    
    fileprivate func showMissingProfileAlert() {
        let alert = UIAlertController(title: "Error", message: "Could not retrieve profile", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func setValueInCognito(_ sender: UIButton) {
        
        let dataset = AWSCognito.default().openOrCreateDataset("MainDataset")
        dataset.setString(valueFromCognito.text, forKey:"value")
        
        dataset.synchronize().continueWith {(task) -> AnyObject! in
            if(task.error != nil)
            {
                let alert = UIAlertController(title: "Alert", message: task.error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else
            {
            self.valueFromCognito.text = dataset.string(forKey: "value")
            
            }
            return nil
        }
        self.view.endEditing(true);
    }
    @IBOutlet weak var valueFromCognito: UITextField!
    override func viewDidLoad() {

                                   NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.identityDidChange(notification:)), name: NSNotification.Name.AWSCognitoIdentityIdChanged, object: nil)
        self.credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:99ca9e07-a7d6-42ae-80a0-6c46bdb4dd92")
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: self.credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
       self.valueFromCognito.delegate  = self
        
        
        
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

    
    override func viewDidAppear(_ animated: Bool) {
        self.credentialProvider.invalidateCachedTemporaryCredentials()
        self.credentialProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
            if (task.error != nil) {
                let alert = UIAlertController(title: "Alert", message: task.error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                // the task result will contain the identity id
                let cognitoId = task.result!
                print("Cognito id: \(cognitoId)")
                
                let dataset = AWSCognito.default().openOrCreateDataset("MainDataset")
                self.valueFromCognito.text = dataset.string(forKey: "value")
                
            }
            return task;
        })
        

        

    }
    
    

    
}




