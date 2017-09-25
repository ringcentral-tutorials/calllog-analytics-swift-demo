//
//  ViewController.swift
//  Call Analytics
//
//  Created by Phong Vu on 9/20/17.
//  Copyright © 2017 Phong Vu. All rights reserved.
//


import UIKit
import RingCentral

class ViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var rightNavBarButton: UIBarButtonItem!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var menuBtnView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var extensionTextField: UITextField!

    var rc:RestClient!
    var appDelegate:AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        extensionTextField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        }else if textField == passwordTextField {
            extensionTextField.becomeFirstResponder()
        }else{
            self.rightNavBarBtnClicked( nil )
        }
        return true
    }
    
    @IBAction func rightNavBarBtnClicked(_ sender: UIBarButtonItem? = nil) {
        if rc != nil && rc.token != nil { // being logged in => logout
            rc.revoke()
            rc.token = nil
            loginView.isHidden = false
            menuBtnView.isHidden = true
            self.rightNavBarButton.title = "Login"
        }else {
            let username = usernameTextField.text!
            if username == "" {
                promptForCredential(message: "Please enter username")
            }
            let pwd = passwordTextField.text!
            if pwd == "" {
                promptForCredential(message: "Please enter password")
            }
            if (rc == nil) {
                rc = appDelegate.createRingCentralClient()
            }
            rc.authorize(username, ext: extensionTextField.text!, password: pwd) {
                token, error in
                if error == nil {
                    self.loginView.isHidden = true
                    self.menuBtnView.isHidden = false
                    self.rightNavBarButton.title = "Logout"
                }else{
                    print(error?.message ?? "error")
                }
            }
        }
    }
    
    func promptForCredential(message:String) {
        let alertController = UIAlertController(title: "Login request", message: message, preferredStyle:UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
        { action -> Void in
            
        })
    }
    
    @IBAction func CallLogBtnClicked(_ sender: UIButton) {
        let calllogViewController = self.storyboard?.instantiateViewController(withIdentifier: "calllogview") as! CallInfoViewController
        self.present(calllogViewController, animated: true, completion: nil)
    }
    
}
